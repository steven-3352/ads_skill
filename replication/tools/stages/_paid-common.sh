#!/usr/bin/env bash
# =============================================================================
# _paid-common.sh — 付费 stage（stage3 图 / stage4 视频 / stage5 语音）共享逻辑
#   被 stage3/4/5 source。不单独执行。
#   委托 paid-asset-orchestrator.sh（付费层核心，含 flock / 未结算金丝雀 / 授权名单 /
#   预算双上限 / 防覆盖 / 调 validate-* / video 归类修复），run.sh 是其唯一正式调用者。
#   付费逐单元只写 paid-state.json（orchestrator 唯一写者）；主总账只在 gate-out 记
#   一条 *_accepted 迁移 + 证据指针（paid-state hash + 该组已 accept 数）。
# =============================================================================
# 调用方须先设置：REPO_ROOT project_dir sub desc cur ；并已 parse_stage_args "$@"

pc_init() {
  ORCH="$REPO_ROOT/replication/tools/paid-asset-orchestrator.sh"
  FG="$REPO_ROOT/replication/tools/stages/foreign-guard.sh"
  ps_rel="$(jq -r '.paid_state // ("automation/"+.subproject_id+".paid-state.json")' "$desc")"
  PAID_STATE="$project_dir/$ps_rel"
}

emit_reject()  { jq -cn --argjson c "$1" --arg r "$2" '{decision:"reject",code:$c,reason:$r}'; exit 0; }
emit_pass()    { jq -cn --argjson c "$1" --arg m "$2" '{decision:"passthrough",code:$c,message:$m}'; exit 0; }
emit_pause()   { jq -cn --arg f "$1" --arg t "$2" --arg g "$3" --arg i "$4" \
                  '{decision:"pause",from:$f,to:$t,gate:$g,evidence:[],instructions:$i}'; exit 0; }
emit_advance() { jq -cn --arg f "$1" --arg t "$2" --arg g "$3" --arg n "$4" --argjson e "$5" \
                  '{decision:"advance",from:$f,to:$t,gate:$g,note:$n,evidence:$e}'; exit 0; }

parse_stage_args() {
  UNIT=""; EVID=""; NOTE=""; REVIEWER=""
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --unit)     UNIT="$2"; shift 2 ;;
      --evidence) EVID="$2"; shift 2 ;;
      --note)     NOTE="$2"; shift 2 ;;
      --reviewer) REVIEWER="$2"; shift 2 ;;
      *) shift ;;
    esac
  done
}

pc_require_paid_state() {
  [[ -f "$PAID_STATE" ]] || emit_reject 10 \
    "paid-state 未初始化：$ps_rel（stage run 阶段须由子 agent 依 production-plan 建好资产清单 + budget/authorization）"
}

pc_foreign_baseline() { "$FG" baseline "$project_dir" "$desc" >&2; }

pc_foreign_check() { # 结果写全局 FGRC（0 干净 / 13 污染 / 其它 无法校验），恒返回 0，避免触发 set -e
  set +e; "$FG" check "$project_dir" "$desc" >&2; FGRC=$?; set -e; return 0
}

# 逐单元付费委托：orchestrator run-asset（内部金丝雀/授权/预算/validate/防覆盖）
pc_run_asset() {
  [[ -n "$UNIT" ]] || emit_reject 2 "asset 阶段需 --unit <asset-id>"
  pc_require_paid_state
  set +e; "$ORCH" run-asset "$PAID_STATE" "$UNIT" >&2; local orc=$?; set -e
  pc_foreign_check
  [[ $FGRC -eq 13 ]] && emit_reject 13 "生成后 foreign-guard 发现他片被改动（unit $UNIT）"
  if [[ $orc -eq 0 ]]; then emit_pass 0 "unit $UNIT 已生成，待 QC/accept（paid-state: $ps_rel）"
  else emit_pass 20 "orchestrator run-asset 失败(rc=$orc) unit $UNIT；见 stderr（未结算/预算/授权/validate/provider）"; fi
}

pc_auto_qc() {
  [[ -n "$UNIT" ]] || emit_reject 2 "qc 阶段需 --unit <asset-id>"
  pc_require_paid_state
  set +e; "$ORCH" auto-qc "$PAID_STATE" "$UNIT" >&2; local rc=$?; set -e
  [[ $rc -eq 0 ]] && emit_pass 0 "unit $UNIT 技术 QC 过（语义 QC 见配置）" || emit_pass 20 "unit $UNIT auto-qc 失败(rc=$rc)"
}

pc_accept_reject() { # $1 = accept|reject
  local act="$1"
  [[ -n "$UNIT" && -n "$EVID" ]] || emit_reject 2 "$act 阶段需 --unit <id> --evidence <file> [--note .. --reviewer ..]"
  pc_require_paid_state
  set +e; "$ORCH" "$act" "$PAID_STATE" "$UNIT" "$EVID" "${NOTE:-manual $act}" "${REVIEWER:-run.sh}" >&2; local rc=$?; set -e
  [[ $rc -eq 0 ]] && emit_pass 0 "unit $UNIT -> $act" || emit_pass 20 "unit $UNIT $act 失败(rc=$rc)"
}

# gate-out：该组授权资产全部 accepted + 逐件 sha256 账实一致 + 他片零改动 → 推进
pc_group_gate_out() { # <group> <from> <to> <gate>
  local group="$1" from="$2" to="$3" gate="$4"
  pc_require_paid_state
  pc_foreign_check
  [[ $FGRC -eq 13 ]] && emit_reject 13 "foreign-guard：他片被改动，拒绝推进"
  [[ $FGRC -eq 0 ]]  || emit_reject 12 "foreign-guard 无法校验(rc=$FGRC)；stage run 阶段须先 baseline"

  # 该组 + 在授权名单内的资产必须存在且全部 accepted
  local ok
  ok="$(jq -r --arg g "$group" '
    (.authorization.asset_ids // []) as $a |
    ([.assets[] | select(.group==$g) | select((.id) as $id | ($a|index($id))!=null)]) as $grp |
    if ($grp|length)==0 then "empty"
    elif (all($grp[]; .status=="accepted")) then "ok"
    else "bad" end' "$PAID_STATE")"
  if [[ "$ok" == "empty" ]]; then
    emit_reject 12 "gate-out：授权名单内无 group=$group 资产（paid-state 未按本阶段配置）"
  elif [[ "$ok" != "ok" ]]; then
    local bad; bad="$(jq -r --arg g "$group" '.authorization.asset_ids as $a|[.assets[]|select(.group==$g and ((.id) as $id|($a|index($id))!=null))|select(.status!="accepted")|"\(.id):\(.status)"]|join(", ")' "$PAID_STATE")"
    emit_reject 12 "gate-out：group=$group 尚有未 accepted 资产：$bad"
  fi

  # 逐件 sha256 账实一致（paid-state.sha256 vs 磁盘产物；output 相对 REPO_ROOT）
  local mismatch="" line id out sha op actual
  while IFS=$'\t' read -r id out sha; do
    op="$out"; [[ "$op" = /* ]] || op="$REPO_ROOT/$op"
    actual="$(sha256sum "$op" 2>/dev/null | awk '{print $1}')"
    [[ "$actual" == "$sha" && -n "$sha" ]] || mismatch+="$id "
  done < <(jq -r --arg g "$group" '.authorization.asset_ids as $a|.assets[]|select(.group==$g and ((.id) as $id|($a|index($id))!=null) and .status=="accepted")|"\(.id)\t\(.output)\t\(.sha256 // "")"' "$PAID_STATE")
  [[ -z "$mismatch" ]] || emit_reject 12 "gate-out：sha256 账实不一致（产物缺失/被替换）：$mismatch"

  local ph naccept ev
  ph="$(sha256sum "$PAID_STATE" | awk '{print $1}')"
  naccept="$(jq --arg g "$group" '[.assets[]|select(.group==$g and .status=="accepted")]|length' "$PAID_STATE")"
  ev="$(jq -cn --arg p "$ps_rel" --arg h "$ph" --arg g "$group" --argjson n "$naccept" \
        '[{kind:"paid_substate",path:$p,hash:$h,group:$g,assets_accepted:$n},
          {kind:"foreign_guard",result:"pass"},
          {kind:"sha256_crosscheck",group:$g,result:"consistent"}]')"
  emit_advance "$from" "$to" "$gate" "group=$group 全部 accepted + sha256 账实一致 + 他片零改动" "$ev"
}
