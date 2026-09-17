#!/usr/bin/env bash
# =============================================================================
# run-video-batch.sh — 付费视频批量：run.sh 的薄封装（不再直调 generate-video.sh）
#
#   唯一 sanctioned 付费入口是 run.sh。本脚本只做一件事：按顺序（金丝雀=首条即验证）
#   循环调 run.sh <dir> <stage> --sub <sub> --phase asset --unit <id>，见拒即停。
#   证据链 / 金丝雀（orchestrator 未结算门）/ audit / 子账本 / 预算·授权双上限 / validate /
#   video 归类修复，全部在 run.sh → paid-asset-orchestrator.sh 内，本脚本不重复也不绕过。
#
#   为什么顺序而非并发：账户余额可能只够几条（实测 15 条只出 3 条即 226638 积分不足）。
#   顺序执行时某条被拒立即停止，最多损失当前一条。orchestrator 的未结算门要求上一条
#   结算（accept，或 paid-state 设 allow_pending_semantic_qc）后才放行下一条 run-asset。
#
#   用法：
#     run-video-batch.sh --project-dir <项目目录> --sub <子片> [--stage stage4-videos] < unit-ids
#     stdin：每行一个 asset-id（paid-state 内的单元 id）；# 开头为注释；空行跳过。
#   退出码：0 全部成功；非 0 = 首个失败单元的 run.sh 退出码（10/12/13/20/…），见拒即停。
# =============================================================================
set -uo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
RUN="$ROOT/run.sh"
PROJECT_DIR=""; SUB=""; STAGE="stage4-videos"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-dir) PROJECT_DIR="${2:-}"; shift 2 ;;
    --sub)         SUB="${2:-}"; shift 2 ;;
    --stage)       STAGE="${2:-}"; shift 2 ;;
    -h|--help)     sed -n '2,22p' "$0" >&2; exit 2 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$PROJECT_DIR" && -d "$PROJECT_DIR" ]] || { echo "需要有效的 --project-dir" >&2; exit 2; }
[[ -n "$SUB" ]] || { echo "需要 --sub <子片>" >&2; exit 2; }

ok=0; idx=0
while IFS= read -r id; do
  id="${id%%$'\r'}"; id="$(echo "$id" | tr -d '[:space:]')"
  [[ -z "$id" || "$id" == \#* ]] && continue
  idx=$((idx+1))
  echo "[$idx] paid asset: $id"
  "$RUN" "$PROJECT_DIR" "$STAGE" --sub "$SUB" --phase asset --unit "$id"
  rc=$?
  if [[ $rc -ne 0 ]]; then
    echo "==== 批量停止：单元 $id 经 run.sh 返回 exit $rc（见拒即停）。已完成 $ok。修复后重跑（已生成单元会被 orchestrator 防覆盖跳过）。 ====" >&2
    exit $rc
  fi
  ok=$((ok+1))
done

echo "批量完成：成功 $ok 个付费单元（QC/accept 请按 --phase qc/accept 单独收口）。"
exit 0
