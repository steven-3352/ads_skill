#!/usr/bin/env bash
# =============================================================================
# stage3-images.sh — 生图 stage（付费；委托 paid-asset-orchestrator.sh）
#   两个子周期，按当前状态自动选择：
#     master 母板     : storyboard_confirmed -> public_assets_pending -> public_assets_accepted
#     镜头关键帧 shot : public_assets_accepted -> shot_images_pending -> shot_images_accepted
#   phase：
#     run                              进入 *_pending + 取 foreign 基线 + 打印逐单元指令
#     asset  --unit <id>               委托 orchestrator run-asset（金丝雀/授权/预算/防覆盖/validate）
#     qc     --unit <id>               委托 orchestrator auto-qc（技术 QC）
#     accept --unit <id> --evidence f  委托 orchestrator accept（语义 QC）
#     reject --unit <id> --evidence f  委托 orchestrator reject
#     gate-out                         该组全部 accepted + sha256 账实一致 + 他片零改动 → 推进
# =============================================================================
set -Eeuo pipefail
phase="${1:-}"; project_dir="${2:-}"; sub="${3:-}"; desc="${4:-}"; cur="${5:-}"; shift 5 || true
[[ -n "$phase" && -d "$project_dir" && -f "$desc" ]] || { echo "stage3 bad args" >&2; exit 1; }
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
source "$(dirname "$0")/_paid-common.sh"
pc_init
parse_stage_args "$@"

case "$phase" in
  run)
    case "$cur" in
      storyboard_confirmed)   from="$cur"; to="public_assets_pending"; grp="master" ;;
      public_assets_accepted) from="$cur"; to="shot_images_pending";   grp="shot_image" ;;
      *) emit_reject 10 "stage3 run 需 storyboard_confirmed 或 public_assets_accepted（当前 $cur）" ;;
    esac
    pc_foreign_baseline
    emit_pause "$from" "$to" "stage3:run:$grp" \
      "本子周期 group=$grp。先确保 paid-state（$ps_rel）内该组资产 status=ready、在 authorization.asset_ids 内、budget/authorization 双上限已设。\n然后逐单元（金丝雀先行）：run.sh <dir> stage3-images --sub <sub> --phase asset --unit <id>；每单元 --phase qc / --phase accept --evidence <QC证据>。\n全部 accept 后：--phase gate-out。付费前查余额；见拒即停。"
    ;;
  asset)  pc_run_asset ;;
  qc)     pc_auto_qc ;;
  accept) pc_accept_reject accept ;;
  reject) pc_accept_reject reject ;;
  gate-out)
    case "$cur" in
      public_assets_pending) pc_group_gate_out master     public_assets_pending public_assets_accepted "stage3:gate-out:master" ;;
      shot_images_pending)   pc_group_gate_out shot_image  shot_images_pending   shot_images_accepted   "stage3:gate-out:shots" ;;
      *) emit_reject 10 "stage3 gate-out 需 public_assets_pending 或 shot_images_pending（当前 $cur）" ;;
    esac
    ;;
  *) echo "stage3: unknown phase $phase" >&2; exit 1 ;;
esac
