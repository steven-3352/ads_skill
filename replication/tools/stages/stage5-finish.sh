#!/usr/bin/env bash
# =============================================================================
# stage5-finish.sh — 收尾/成片 stage（TTS 付费纳子账本 + 后期烧字幕 + 成片留存/交付门）
#   周期：shot_videos_accepted -> final_workflow_pending -> final_qc -> complete
#   - TTS 补齐（无对白边界的配音）走 generate-speech.sh，经 orchestrator（kind:speech）
#     纳入 paid-state（原生 audit/幂等/未结算金丝雀/预算双上限，与图/视频同一付费层）。
#   - 字幕后期统一烧（H3 只出配音+表演）走 burn-subtitles.sh（¥0，确定性后期），非付费单元。
#   - 最终剪辑装配成片放 final/<sub>-final*.mp4（final/ 只放成片）。
#   phase：
#     run                              进入 final_workflow_pending + foreign 基线 + 打印收尾指令
#     asset/qc/accept/reject --unit    付费 TTS 单元委托 orchestrator（同 stage3/4）
#     gate-qc                          成片技术门（ffprobe：可解码/含视频+音频流/时长 15–120s）→ final_qc
#     gate-out --evidence <signoff>    成片留存门(SOP §15.5 静默检测) + 交付清单(§16 签核)
#                                      + 成片 sha 与 final_qc 记录一致 + 授权 TTS 全 accepted → complete
#   注意：shot_videos_accepted ≠ 成片；complete 是有前置门的终态。
# =============================================================================
set -Eeuo pipefail
phase="${1:-}"; project_dir="${2:-}"; sub="${3:-}"; desc="${4:-}"; cur="${5:-}"; shift 5 || true
[[ -n "$phase" && -d "$project_dir" && -f "$desc" ]] || { echo "stage5 bad args" >&2; exit 1; }
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$(dirname "$0")/_paid-common.sh"
pc_init
parse_stage_args "$@"

# ---- 成片定位：描述符 .final_film（相对项目目录）优先，否则 final/<sub>-*.mp4 须恰好一个 ----
find_final_film() {
  local ff subid
  ff="$(jq -r '.final_film // empty' "$desc")"
  if [[ -n "$ff" ]]; then
    [[ "$ff" = /* ]] || ff="$project_dir/$ff"
    [[ -f "$ff" ]] || return 3
    echo "$ff"; return 0
  fi
  local -a cands=()
  while IFS= read -r f; do cands+=("$f"); done < <(ls "$project_dir/final/${sub}-"*.mp4 2>/dev/null || true)
  [[ "${#cands[@]}" -ge 1 ]] || return 3
  [[ "${#cands[@]}" -eq 1 ]] || return 4
  echo "${cands[0]}"; return 0
}

# ---- 从总账取 to_state==final_qc 那条迁移记录里的成片 sha（用于"交付=已QC同一片"核验）----
ledger_final_qc_sha() {
  local led rel
  rel="$(jq -r '.ledger' "$desc")"
  led="$project_dir/$rel"
  [[ -s "$led" ]] || { echo ""; return; }
  jq -r 'select(.to_state=="final_qc") | (.evidence[]? | select(.kind=="final_film") | .sha256)' "$led" | tail -n1
}

# ---- 授权名单内的 TTS(speech) 单元若存在，须全部 accepted（无则跳过）----
require_speech_settled() {
  [[ -f "$PAID_STATE" ]] || return 0
  local bad
  bad="$(jq -r '
    (.authorization.asset_ids // []) as $a |
    [.assets[]? | select(.kind=="speech" and ((.id) as $id|($a|index($id))!=null)) | select(.status!="accepted") | "\(.id):\(.status)"] | join(", ")
  ' "$PAID_STATE")"
  [[ -z "$bad" ]] || emit_reject 12 "gate-out：授权 TTS 单元尚未 accepted：$bad"
}

case "$phase" in
  run)
    [[ "$cur" == shot_videos_accepted ]] || emit_reject 10 "stage5 run 需 shot_videos_accepted（当前 $cur）"
    pc_foreign_baseline
    emit_pause "shot_videos_accepted" "final_workflow_pending" "stage5:run" \
      "收尾三件事（主会话派隔离子 agent 产出，全在 owner_globs 内写文件，勿动他片）：\n① TTS 补齐（仅无对白边界需要配音时；H3 对白已在正片内嵌，通常 0 单元）：在 paid-state（$ps_rel）建 kind:speech 资产（prompt_file/output/cost/authorization.asset_ids/预算上限），逐单元 --phase asset/qc/accept（金丝雀先行，付费前查余额）。\n② 后期统一烧字幕（¥0，确定性）：burn-subtitles.sh --input <剪好的成片> --manifest <字幕清单> --output final/${sub}-final.mp4（H3 只出配音+表演，字幕后期烧；烧后查残留=0）。\n③ 成片装配：最终成片只放 final/${sub}-final.mp4（final/ 只放成片，不放中间件）。\n完成后：--phase gate-qc（成片技术门）→ 过后 --phase gate-out --evidence <留存+交付签核.json>（含 retention_gate=pass / delivery_checklist=pass / reviewer）。"
    ;;
  asset)  pc_run_asset ;;
  qc)     pc_auto_qc ;;
  accept) pc_accept_reject accept ;;
  reject) pc_accept_reject reject ;;

  gate-qc)
    [[ "$cur" == final_workflow_pending ]] || emit_reject 10 "stage5 gate-qc 需 final_workflow_pending（当前 $cur）"
    pc_foreign_check
    [[ $FGRC -eq 13 ]] && emit_reject 13 "foreign-guard：他片被改动，拒绝推进"
    [[ $FGRC -eq 0 ]]  || emit_reject 12 "foreign-guard 无法校验(rc=$FGRC)；run 阶段须先 baseline"
    ff="$(find_final_film)" || {
      case $? in
        3) emit_reject 12 "gate-qc：找不到成片（描述符 .final_film 或 final/${sub}-*.mp4）";;
        4) emit_reject 12 "gate-qc：final/${sub}-*.mp4 匹配多个成片，须唯一（描述符 .final_film 指定）";;
        *) emit_reject 12 "gate-qc：成片定位失败";;
      esac
    }
    command -v ffprobe >/dev/null || emit_reject 2 "gate-qc 需要 ffprobe"
    ffprobe -v error "$ff" >/dev/null 2>&1 || emit_reject 12 "gate-qc：成片无法解码：$ff"
    has_v="$(ffprobe -v error -select_streams v -show_entries stream=codec_type -of csv=p=0 "$ff" 2>/dev/null | grep -c video || true)"
    has_a="$(ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$ff" 2>/dev/null | grep -c audio || true)"
    [[ "${has_v:-0}" -ge 1 ]] || emit_reject 12 "gate-qc：成片缺视频流"
    [[ "${has_a:-0}" -ge 1 ]] || emit_reject 12 "gate-qc：成片缺音频流（成片须含配音/声音）"
    dur="$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$ff" 2>/dev/null | awk '{printf "%.2f",$1}')"
    awk -v d="$dur" 'BEGIN{exit !(d>=15 && d<=120)}' \
      || emit_reject 12 "gate-qc：成片时长 ${dur}s 不在 15–120s（SOP 短视频区间）"
    sha="$(sha256sum "$ff" | awk '{print $1}')"
    rel="${ff#$project_dir/}"
    ev="$(jq -cn --arg p "$rel" --arg h "$sha" --arg d "$dur" \
          '[{kind:"final_film",path:$p,sha256:$h,duration_s:($d|tonumber)},
            {kind:"ffprobe_qc",video_streams:1,audio_streams:1,result:"pass"},
            {kind:"foreign_guard",result:"pass"}]')"
    emit_advance "final_workflow_pending" "final_qc" "stage5:gate-qc" \
      "成片技术门过：可解码 + 含视频/音频流 + 时长 ${dur}s∈[15,120]" "$ev"
    ;;

  gate-out)
    [[ "$cur" == final_qc ]] || emit_reject 10 "stage5 gate-out 需 final_qc（当前 $cur）"
    [[ -n "$EVID" && -f "$EVID" ]] || emit_reject 12 \
      "gate-out：须 --evidence <签核.json>（留存门+交付清单人工签核；含 retention_gate/delivery_checklist/reviewer）"
    jq -e . "$EVID" >/dev/null 2>&1 || emit_reject 12 "gate-out：签核证据非合法 JSON：$EVID"
    ok="$(jq -r 'if (.retention_gate=="pass" and .delivery_checklist=="pass" and ((.reviewer//"")|length>0)) then "ok" else "bad" end' "$EVID")"
    [[ "$ok" == "ok" ]] || emit_reject 12 \
      "gate-out：签核未通过（须 retention_gate=pass 且 delivery_checklist=pass 且 reviewer 非空）：$EVID"

    pc_foreign_check
    [[ $FGRC -eq 13 ]] && emit_reject 13 "foreign-guard：他片被改动，拒绝推进"
    [[ $FGRC -eq 0 ]]  || emit_reject 12 "foreign-guard 无法校验(rc=$FGRC)"

    require_speech_settled

    ff="$(find_final_film)" || emit_reject 12 "gate-out：成片定位失败（同 gate-qc）"
    sha="$(sha256sum "$ff" | awk '{print $1}')"
    qcsha="$(ledger_final_qc_sha)"
    [[ -n "$qcsha" ]] || emit_reject 12 "gate-out：总账无 final_qc 成片 sha 记录（须先 gate-qc）"
    [[ "$sha" == "$qcsha" ]] || emit_reject 12 \
      "gate-out：交付成片 sha 与 final_qc 记录不一致（成片被改动/换片，须回退重跑 gate-qc）"

    # SOP §15.5 静默门（确定性）：单段静默 > 2.0s 视为节奏塌陷，拒。
    command -v ffmpeg >/dev/null || emit_reject 2 "gate-out 需要 ffmpeg（silencedetect）"
    sil_log="$(ffmpeg -hide_banner -nostats -i "$ff" -af silencedetect=noise=-30dB:d=2.0 -f null - 2>&1 || true)"
    max_sil="$( { printf '%s\n' "$sil_log" | grep -oE 'silence_duration: [0-9.]+' | awk '{print $2}' | sort -gr | head -n1; } || true )"
    if [[ -n "$max_sil" ]]; then
      awk -v s="$max_sil" 'BEGIN{exit !(s>2.0)}' \
        && emit_reject 12 "gate-out：成片存在 ${max_sil}s 静默段(>2.0s)，未过 SOP §15.5 静默门（补内容/剪掉停滞窗后重烧）"
    fi

    rel="${ff#$project_dir/}"; ev_rel="${EVID#$project_dir/}"
    ev="$(jq -cn --arg p "$rel" --arg h "$sha" --arg sg "$ev_rel" --arg ms "${max_sil:-0}" \
          '[{kind:"final_film",path:$p,sha256:$h},
            {kind:"retention_gate",signoff:$sg,max_silence_s:($ms|tonumber),result:"pass"},
            {kind:"delivery_checklist",signoff:$sg,result:"pass"},
            {kind:"final_qc_sha_crosscheck",result:"consistent"},
            {kind:"foreign_guard",result:"pass"}]')"
    emit_advance "final_qc" "complete" "stage5:gate-out" \
      "成片留存门+交付签核通过（静默 max ${max_sil:-0}s≤2.0，成片=已QC同一片，他片零改动）" "$ev"
    ;;

  *) echo "stage5: unknown phase $phase" >&2; exit 1 ;;
esac
