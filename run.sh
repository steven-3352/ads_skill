#!/usr/bin/env bash
# =============================================================================
# run.sh — ads_skill 项目级统一门禁 / 唯一编排入口
#
#   正式生产的每一步都只经此脚本推进。它做三件事：
#     1) gate-in（准入）：按 references/state-machine/main-sequence.json 校验前置状态；
#     2) 分发 stage 脚本（stages/<stage>.sh）做 run / gate-out 校验（收编所有校验器）；
#     3) gate-out 通过后，作为**总账唯一写者**原子 append 一条带哈希链的记录，推进主状态。
#
#   底层生成脚本（generate-image/video/speech.sh）不在此改动，保持可单独执行的原子工具。
#   "唯一入口"落在证据层：被总账承认、能进正式交付的付费产物，必须经 orchestrator 生成、
#   有 paid-state 条目 + audit 证据链 + accept 记录 + 本总账迁移；绕过 run.sh 直调生成脚本
#   的产物没有这条证据链，gate-out 不认、不算数、不进交付。
#
#   用法：
#     run.sh <project-dir> <stage> --sub <sub> --phase <run|gate-out|gate-qc> [-- <stage-args...>]
#     run.sh <project-dir> --init        --sub <sub> --at <state> [--note "..."] [--evidence '<json[]>']
#     run.sh <project-dir> --status      --sub <sub>
#     run.sh <project-dir> --verify-chain --sub <sub>
#     run.sh <project-dir> --history     --sub <sub>
#
#   统一退出码：
#     0  推进成功
#     2  用法/内部错误
#     10 gate-in 拒（前置状态/证据不足，含"状态不足拒付"）
#     11 回合制暂停（需主会话派子 agent 产出，已打印待产物路径与指令）
#     12 gate-out 拒（产物缺 / sha256 不符 / validate 非 0 / blocker 未清）
#     13 他片零改动 gate 失败（foreign-guard）
#     20 付费委托失败（orchestrator 非 0）
#     30 哈希链断裂（总账被篡改/损坏）
# =============================================================================
set -Eeuo pipefail

REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"
GENESIS_HASH="0000000000000000000000000000000000000000000000000000000000000000"

die()   { echo "run.sh: $*" >&2; exit 2; }
reject(){ local code="$1"; shift; echo "run.sh: $*" >&2; exit "$code"; }

usage() {
  sed -n '2,45p' "$0" | sed 's/^# \{0,1\}//' >&2
  exit 2
}

command -v jq        >/dev/null || die "jq is required"
command -v sha256sum >/dev/null || die "sha256sum is required"
command -v flock     >/dev/null || die "flock is required"

# ---- 参数解析 --------------------------------------------------------------
[[ $# -ge 2 ]] || usage
PROJECT_DIR="$1"; shift
CMD="$1"; shift
SUB=""; PHASE=""; AT=""; NOTE=""; EVIDENCE="[]"; declare -a STAGE_ARGS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --sub)      SUB="$2"; shift 2 ;;
    --phase)    PHASE="$2"; shift 2 ;;
    --at)       AT="$2"; shift 2 ;;
    --note)     NOTE="$2"; shift 2 ;;
    --evidence) EVIDENCE="$2"; shift 2 ;;
    --)         shift; STAGE_ARGS=("$@"); break ;;
    *)          STAGE_ARGS+=("$1"); shift ;;
  esac
done

[[ -d "$PROJECT_DIR" ]] || die "project dir not found: $PROJECT_DIR"
PROJECT_DIR="$(cd "$PROJECT_DIR" && pwd)"
[[ -n "$SUB" ]] || die "--sub <subproject-id> is required"

# ---- 描述符 ----------------------------------------------------------------
DESC="$PROJECT_DIR/automation/$SUB.project.json"
[[ -f "$DESC" ]] || die "descriptor not found: $DESC (先建 automation/<sub>.project.json)"
jq -e '.subproject_id and .ledger and .state_sequence' "$DESC" >/dev/null \
  || die "descriptor missing required keys (subproject_id/ledger/state_sequence): $DESC"

resolve() { # 相对路径按 REPO_ROOT 解析
  local p="$1"; [[ "$p" = /* ]] && { echo "$p"; return; }
  echo "$REPO_ROOT/$p"
}
LEDGER="$PROJECT_DIR/automation/$(jq -r '.ledger|split("/")|last' "$DESC")"
# 描述符里 ledger 允许写成相对项目目录的 automation/<sub>.ledger.ndjson
LEDGER="$PROJECT_DIR/$(jq -r '.ledger' "$DESC")"
SEQFILE="$(resolve "$(jq -r '.state_sequence' "$DESC")")"
[[ -f "$SEQFILE" ]] || die "state sequence file not found: $SEQFILE"
STAGES_DIR="$REPO_ROOT/replication/tools/stages"
mkdir -p "$(dirname "$LEDGER")"

GENESIS_STATE="$(jq -r '.genesisState' "$SEQFILE")"

# ---- 状态序列查询 ----------------------------------------------------------
index_of() { jq -r --arg s "$1" '(.states|index($s)) // -1' "$SEQFILE"; }
succ_of()  { jq -r --arg s "$1" '.states as $a|($a|index($s)) as $i|if $i==null or $i+1>=($a|length) then "" else $a[$i+1] end' "$SEQFILE"; }
is_pending(){ jq -e --arg s "$1" '(.pendingStates|index($s))!=null' "$SEQFILE" >/dev/null; }

# ---- 哈希链 ----------------------------------------------------------------
canon_hash() { jq -S -c 'del(.entry_hash)' | sha256sum | awk '{print $1}'; }

# 校验整链；返回链尾 entry_hash（空账本回显 GENESIS）。断裂即 exit 30。
verify_chain() {
  local led="$1"
  [[ -s "$led" ]] || { echo "$GENESIS_HASH"; return 0; }
  local prev="$GENESIS_HASH" exp=1 line seq stored_prev stored_entry recomputed
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    jq -e . >/dev/null 2>&1 <<<"$line" || reject 30 "chain broken: non-JSON ledger line (seq expected $exp)"
    seq="$(jq -r '.seq // empty' <<<"$line")"
    stored_prev="$(jq -r '.prev_hash // empty' <<<"$line")"
    stored_entry="$(jq -r '.entry_hash // empty' <<<"$line")"
    [[ "$seq" == "$exp" ]]            || reject 30 "chain broken: seq mismatch (got '$seq' expected '$exp')"
    [[ "$stored_prev" == "$prev" ]]  || reject 30 "chain broken: prev_hash mismatch at seq $seq"
    recomputed="$(canon_hash <<<"$line")"
    [[ "$recomputed" == "$stored_entry" ]] || reject 30 "chain broken: entry_hash mismatch at seq $seq (tampered record)"
    prev="$stored_entry"; exp=$((exp+1))
  done < "$led"
  echo "$prev"
}

current_state() {
  local led="$1"
  [[ -s "$led" ]] || { echo "$GENESIS_STATE"; return; }
  local s; s="$(jq -r -s 'map(select(.to_state != null)) | (last // {}) | .to_state // empty' "$led")"
  [[ -n "$s" ]] && echo "$s" || echo "$GENESIS_STATE"
}
last_seq() { [[ -s "$1" ]] && jq -r -s '(last // {}) | .seq // 0' "$1" || echo 0; }

validate_transition() { # <from> <to>  — 仅 dimension=main 用
  local from="$1" to="$2" fi ti
  fi="$(index_of "$from")"; ti="$(index_of "$to")"
  [[ "$fi" -ge 0 ]] || die "unknown from_state: $from"
  [[ "$ti" -ge 0 ]] || die "unknown to_state: $to"
  if [[ "$ti" -eq $((fi+1)) ]]; then return 0; fi                 # 前进：紧邻后继
  if [[ "$ti" -lt "$fi" ]] && is_pending "$to"; then return 0; fi # 回退：最小责任单元
  reject 12 "illegal transition $from -> $to (只允许前进到紧邻后继，或回退到本 stage 的 *_pending)"
}

# 总账唯一写者：持排他锁 → 复验链 → 邻接校验 → append 一行。
# ledger_append <from> <to|""> <dimension> <gate> <actor> <note> <evidence-json>
ledger_append() {
  local from="$1" to="$2" dim="$3" gate="$4" actor="$5" note="$6" evidence="$7"
  jq -e . >/dev/null 2>&1 <<<"$evidence" || die "evidence is not valid JSON: $evidence"
  exec 8>"$LEDGER.lock"
  flock -x 8
  local tip; tip="$(verify_chain "$LEDGER")"
  if [[ "$dim" == "main" && -n "$to" ]]; then
    local cur; cur="$(current_state "$LEDGER")"
    [[ "$from" == "$cur" ]] || die "stage emitted from_state '$from' but current is '$cur'"
    validate_transition "$from" "$to"
  fi
  local seq; seq=$(( $(last_seq "$LEDGER") + 1 ))
  local rec; rec="$(jq -cn \
      --argjson seq "$seq" --arg at "$(date -Is)" --arg sub "$SUB" \
      --arg from "$from" --arg to "$to" --arg dim "$dim" --arg gate "$gate" \
      --arg actor "$actor" --arg note "$note" --argjson evidence "$evidence" --arg prev "$tip" \
      '{seq:$seq, at:$at, subproject_id:$sub, from_state:$from,
        to_state:(if $to=="" then null else $to end),
        dimension:$dim, gate:$gate, actor:$actor, note:$note, evidence:$evidence, prev_hash:$prev}')"
  local h; h="$(canon_hash <<<"$rec")"
  jq -cn --argjson r "$rec" --arg h "$h" '$r + {entry_hash:$h}' >> "$LEDGER"
  flock -u 8
  echo "$seq"
}

# ---- 管理子命令 ------------------------------------------------------------
case "$CMD" in
  --verify-chain)
    tip="$(verify_chain "$LEDGER")"
    echo "chain OK; tip=$tip; state=$(current_state "$LEDGER"); entries=$(last_seq "$LEDGER")"
    exit 0 ;;
  --status)
    verify_chain "$LEDGER" >/dev/null
    cur="$(current_state "$LEDGER")"
    echo "subproject : $SUB"
    echo "state      : $cur"
    echo "entries    : $(last_seq "$LEDGER")"
    echo "next-succ  : $(succ_of "$cur")"
    echo "ledger     : $LEDGER"
    exit 0 ;;
  --history)
    [[ -s "$LEDGER" ]] || { echo "(empty ledger)"; exit 0; }
    jq -r '"seq \(.seq) [\(.dimension)] \(.from_state) -> \(.to_state // "-")  @\(.gate)  \(.at)"' "$LEDGER"
    exit 0 ;;
  --init)
    verify_chain "$LEDGER" >/dev/null
    [[ -n "$AT" ]] || die "--init requires --at <state>"
    [[ "$(index_of "$AT")" -ge 0 ]] || die "unknown --at state: $AT"
    [[ "$(last_seq "$LEDGER")" == 0 ]] || die "ledger already initialized (state=$(current_state "$LEDGER"))"
    ev="$EVIDENCE"
    seq="$(ledger_append "$GENESIS_STATE" "$AT" "bootstrap" "bootstrap:init" "run.sh" \
        "${NOTE:-reconstructed prior state on init}" "$ev")"
    echo "initialized ledger at state=$AT (seq $seq)"
    exit 0 ;;
esac

# ---- stage 分发 ------------------------------------------------------------
# stage 脚本契约：
#   调用：stages/<stage>.sh <phase> <project-dir> <sub> <descriptor> <current-state> [stage-args...]
#   stdout：单个 JSON 决策对象：
#     {"decision":"advance","from":X,"to":Y,"gate":"stageN:phase","evidence":[...],"note":"..."}
#     {"decision":"pause",  "from":X,"to":X_pending,"gate":"...","evidence":[...],"instructions":"..."}
#     {"decision":"reject","code":10|12|13|20,"reason":"..."}
#   退出码：0 = 已产出决策对象（含 reject 决策）；非 0 = stage 内部错误。
STAGE="$CMD"
SCRIPT="$STAGES_DIR/$STAGE.sh"
[[ -f "$SCRIPT" ]] || die "stage '$STAGE' 尚未实现（$SCRIPT 缺失）"
[[ -n "$PHASE" ]]  || die "--phase <run|gate-out|gate-qc> is required for stage runs"

# --evidence/--note 与 run.sh 顶层同名 flag（供 --init 用）冲突，会被顶层解析吃掉。
# stage 运行时把它们转发进 stage 参数，使 `--phase accept --evidence <file> [--note ..]`
# 无需 `--` 分隔即可传达给 stage（--unit/--reviewer 非顶层 flag，本就自动进 STAGE_ARGS）。
[[ "$EVIDENCE" != "[]" ]] && STAGE_ARGS+=(--evidence "$EVIDENCE")
[[ -n "$NOTE" ]]         && STAGE_ARGS+=(--note "$NOTE")

verify_chain "$LEDGER" >/dev/null
CUR="$(current_state "$LEDGER")"

# gate-in：主状态须 >= 该 stage requiresMinState
MINSTATE="$(jq -r --arg s "$STAGE" '.stages[$s].requiresMinState // empty' "$SEQFILE")"
if [[ -n "$MINSTATE" ]]; then
  [[ "$(index_of "$CUR")" -ge "$(index_of "$MINSTATE")" ]] \
    || reject 10 "gate-in reject: current state '$CUR' < required '$MINSTATE' for $STAGE"
fi

set +e
OUT="$("$SCRIPT" "$PHASE" "$PROJECT_DIR" "$SUB" "$DESC" "$CUR" "${STAGE_ARGS[@]}")"
SRC=$?
set -e
[[ $SRC -eq 0 ]] || die "stage '$STAGE' internal error (exit $SRC): ${OUT:-<no output>}"
jq -e . >/dev/null 2>&1 <<<"$OUT" || die "stage '$STAGE' did not emit a JSON decision: ${OUT:-<empty>}"

DEC="$(jq -r '.decision // empty' <<<"$OUT")"
case "$DEC" in
  advance)
    from="$(jq -r '.from' <<<"$OUT")"; to="$(jq -r '.to' <<<"$OUT")"
    gate="$(jq -r '.gate // (.decision)' <<<"$OUT")"; note="$(jq -r '.note // ""' <<<"$OUT")"
    ev="$(jq -c '.evidence // []' <<<"$OUT")"
    seq="$(ledger_append "$from" "$to" "main" "$gate" "$STAGE" "$note" "$ev")"
    echo "advanced: $from -> $to (seq $seq, gate $gate)"
    exit 0 ;;
  pause)
    from="$(jq -r '.from' <<<"$OUT")"; to="$(jq -r '.to' <<<"$OUT")"
    gate="$(jq -r '.gate // (.decision)' <<<"$OUT")"
    instr="$(jq -r '.instructions // ""' <<<"$OUT")"
    ev="$(jq -c '.evidence // []' <<<"$OUT")"
    if [[ "$CUR" != "$to" ]]; then
      seq="$(ledger_append "$from" "$to" "main" "$gate" "$STAGE" "turn-based pause: awaiting subagent output" "$ev")"
      echo "entered: $from -> $to (seq $seq)"
    else
      echo "already at $to (idempotent re-run)"
    fi
    echo "----- 待主会话派隔离子 agent 产出 -----"
    echo "$instr"
    exit 11 ;;
  passthrough)
    # 付费逐单元委托 / QC / accept：不改主状态、不写总账，仅透传消息与退出码。
    code="$(jq -r '.code // 0' <<<"$OUT")"
    msg="$(jq -r '.message // ""' <<<"$OUT")"
    [[ -n "$msg" ]] && echo "$msg"
    exit "$code" ;;
  reject)
    code="$(jq -r '.code // 12' <<<"$OUT")"
    reason="$(jq -r '.reason // "gate-out rejected"' <<<"$OUT")"
    reject "$code" "$STAGE $PHASE reject: $reason" ;;
  *)
    die "stage '$STAGE' returned unknown decision: ${DEC:-<none>}" ;;
esac
