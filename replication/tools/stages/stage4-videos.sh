#!/usr/bin/env bash
# =============================================================================
# stage4-videos.sh — 生视频 + 轻量成片收尾 stage（付费；委托 paid-asset-orchestrator.sh）
#   周期：shot_images_accepted -> shot_videos_pending -> shot_videos_accepted
#         -> final_cut_pending -> complete   （stage5 已并入此处，精简收尾）
#   - 有台词镜的对白+表演+配音在该镜正片内一次性生成；每个生成单元必带音效+对白
#     （纯空镜可豁免对白但音效必带）；成片零字幕，不烧字幕（SOP §13.2.1）。
#   - 状态变化镜 FL2VA 锁首尾帧（首尾帧须 stage3 已 accepted，作 depends_on）。
#   - 媒体不做程序效果校验：批量生成后**人工确认**（accept --evidence <人工看片证据>）；
#     有问题的单元单独 reject + 重生成（superseded_by）。付费安全底座（金丝雀/预算/
#     防重复/防覆盖/证据链/sha256 账实）保留。
#   phase：
#     run                              进入 shot_videos_pending + foreign 基线 + 批量生成指令
#     asset  --unit <id>               委托 orchestrator run-asset（金丝雀/授权/预算/防覆盖）
#     accept --unit <id> --evidence f  人工确认该单元（媒体效果人工，不走程序语义校验）
#     reject --unit <id> --evidence f  人工判废，单独重生成
#     gate-out                         该组全部 accepted + sha256 账实一致 + 他片零改动
#     finalize                         shot_videos_accepted -> final_cut_pending（派子agent本地拼接成片）
#     deliver  --evidence <signoff>    final_cut_pending -> complete（成片存在+人工签核+他片零改动）
# =============================================================================
set -Eeuo pipefail
phase="${1:-}"; project_dir="${2:-}"; sub="${3:-}"; desc="${4:-}"; cur="${5:-}"; shift 5 || true
[[ -n "$phase" && -d "$project_dir" && -f "$desc" ]] || { echo "stage4 bad args" >&2; exit 1; }
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$(dirname "$0")/_paid-common.sh"
pc_init
parse_stage_args "$@"

# 成片定位：描述符 .final_film（相对项目目录）优先，否则 final/<sub>-*.mp4 须恰好一个
find_final_film() {
  local ff
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

case "$phase" in
  run)
    [[ "$cur" == shot_images_accepted ]] || emit_reject 10 "stage4 run 需 shot_images_accepted（当前 $cur）"
    pc_foreign_baseline
    emit_pause "shot_images_accepted" "shot_videos_pending" "stage4:run" \
      "group=shot_video。确保 paid-state（$ps_rel）内视频单元 status=ready、depends_on 指向已 accepted 的首尾帧、视频提示词已过 H3/Seedance 评审。\n每单元必带音效+对白（纯空镜可豁免对白但音效必带）；成片零字幕不烧字幕。\n批量生成（金丝雀先行→再批量）：逐单元 --phase asset --unit <id>（H3 最短 4s 按 4s 计费；在途别杀；付费前查余额）。\n人工确认：--phase accept --unit <id> --evidence <人工看片证据>；有问题的单元 --phase reject 后单独重生成。\n全部 accept 后：--phase gate-out。"
    ;;
  asset)  pc_run_asset ;;
  accept) pc_accept_reject accept ;;
  reject) pc_accept_reject reject ;;
  gate-out)
    [[ "$cur" == shot_videos_pending ]] || emit_reject 10 "stage4 gate-out 需 shot_videos_pending（当前 $cur）"
    pc_group_gate_out shot_video shot_videos_pending shot_videos_accepted "stage4:gate-out"
    ;;
  finalize)
    [[ "$cur" == shot_videos_accepted ]] || emit_reject 10 "stage4 finalize 需 shot_videos_accepted（当前 $cur）"
    pc_foreign_baseline
    emit_pause "shot_videos_accepted" "final_cut_pending" "stage4:finalize" \
      "轻量成片收尾（¥0 本地 ffmpeg，主会话派隔离子 agent，全在 owner_globs 内写文件）：\n① 按分镜顺序拼接已 accepted 的分镜视频 + 统一音频（concat；成片零字幕、不烧字幕）。\n② 成片只放 final/${sub}-final.mp4（final/ 只放成片，不放中间件）。\n③ 人工看整片确认（节奏/音效/对白/连贯）；有问题回 stage4 reject 对应单元重生成后重拼。\n完成后：--phase deliver --evidence <人工签核.json>（含 reviewer 非空）。"
    ;;
  deliver)
    [[ "$cur" == final_cut_pending ]] || emit_reject 10 "stage4 deliver 需 final_cut_pending（当前 $cur）"
    [[ -n "$EVID" && -f "$EVID" ]] || emit_reject 12 "deliver 须 --evidence <签核.json>（人工确认成片，含 reviewer）"
    jq -e . "$EVID" >/dev/null 2>&1 || emit_reject 12 "deliver：签核证据非合法 JSON：$EVID"
    ok="$(jq -r 'if ((.reviewer//"")|length>0) then "ok" else "bad" end' "$EVID")"
    [[ "$ok" == "ok" ]] || emit_reject 12 "deliver：签核缺 reviewer（人工确认人）：$EVID"
    pc_foreign_check
    [[ $FGRC -eq 13 ]] && emit_reject 13 "foreign-guard：他片被改动，拒绝推进"
    [[ $FGRC -eq 0 ]]  || emit_reject 12 "foreign-guard 无法校验(rc=$FGRC)；finalize 阶段须先 baseline"
    ff="$(find_final_film)" || {
      case $? in
        3) emit_reject 12 "deliver：找不到成片（描述符 .final_film 或 final/${sub}-*.mp4）";;
        4) emit_reject 12 "deliver：final/${sub}-*.mp4 匹配多个，须唯一（描述符 .final_film 指定）";;
        *) emit_reject 12 "deliver：成片定位失败";;
      esac
    }
    sha="$(sha256sum "$ff" | awk '{print $1}')"; rel="${ff#$project_dir/}"; ev_rel="${EVID#$project_dir/}"
    ev="$(jq -cn --arg p "$rel" --arg h "$sha" --arg sg "$ev_rel" \
          '[{kind:"final_film",path:$p,sha256:$h},
            {kind:"human_signoff",signoff:$sg,result:"pass"},
            {kind:"foreign_guard",result:"pass"}]')"
    emit_advance "final_cut_pending" "complete" "stage4:deliver" \
      "成片人工签核通过（成片存在 + reviewer 签核 + 他片零改动）" "$ev"
    ;;
  *) echo "stage4: unknown phase $phase" >&2; exit 1 ;;
esac
