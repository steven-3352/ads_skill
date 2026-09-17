#!/usr/bin/env bash
# =============================================================================
# stage4-videos.sh — 生视频 stage（付费；委托 paid-asset-orchestrator.sh）
#   周期：shot_images_accepted -> shot_videos_pending -> shot_videos_accepted
#   有台词镜的画内对白 + 表演 + 配音在该镜正片内一次性生成（不事后单独补口播）。
#   状态变化镜 FL2VA 锁首尾帧（首尾帧须已在 stage3 accepted，作为 depends_on）。
#   orchestrator 已含 §4.5 video 归类修复（已提交=计费；积分不足/未触达=cost0）。
#   phase 同 stage3：run / asset / qc / accept / reject / gate-out。
#   注意：shot_videos_accepted ≠ 成片，收尾在 stage5。
# =============================================================================
set -Eeuo pipefail
phase="${1:-}"; project_dir="${2:-}"; sub="${3:-}"; desc="${4:-}"; cur="${5:-}"; shift 5 || true
[[ -n "$phase" && -d "$project_dir" && -f "$desc" ]] || { echo "stage4 bad args" >&2; exit 1; }
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$(dirname "$0")/_paid-common.sh"
pc_init
parse_stage_args "$@"

case "$phase" in
  run)
    [[ "$cur" == shot_images_accepted ]] || emit_reject 10 "stage4 run 需 shot_images_accepted（当前 $cur）"
    pc_foreign_baseline
    emit_pause "shot_images_accepted" "shot_videos_pending" "stage4:run" \
      "group=shot_video。确保 paid-state（$ps_rel）内视频单元 status=ready、depends_on 指向已 accepted 的首尾帧、视频提示词已过 H3/Seedance 评审（orchestrator run-asset 内部再校验）。\n逐单元（金丝雀先行）：--phase asset --unit <id>（H3 最短 4s 按 4s 计费；在途别杀）；--phase qc / accept --evidence <ffprobe/抽帧证据>。\n全部 accept 后：--phase gate-out。付费前查余额。"
    ;;
  asset)  pc_run_asset ;;
  qc)     pc_auto_qc ;;
  accept) pc_accept_reject accept ;;
  reject) pc_accept_reject reject ;;
  gate-out)
    [[ "$cur" == shot_videos_pending ]] || emit_reject 10 "stage4 gate-out 需 shot_videos_pending（当前 $cur）"
    pc_group_gate_out shot_video shot_videos_pending shot_videos_accepted "stage4:gate-out"
    ;;
  *) echo "stage4: unknown phase $phase" >&2; exit 1 ;;
esac
