#!/usr/bin/env bash
# =============================================================================
# review-batch.sh — 用户看完公网审阅页后，一句话批量签核（2026-10-01 / 用户）
#
#   图片/视频的内容检查只由用户在审阅页上看，不再逐张跑 LLM 自检。
#   用户回复"通过"或"通过，除了 X/Y"后，本脚本把该组所有待验收资产
#   逐个经 run.sh accept/reject（仍走唯一入口，账本/哈希链照常），reviewer=user。
#
# 用法：
#   review-batch.sh <project-dir> <sub> <stage3-images|stage4-videos> <group> \
#       [--reject id1,id2] [--note "用户原话/看片结论"]
#   group：master | shot_image | shot_video
#   只处理状态为 generated_pending_qc / blocked_pending_semantic_qc 的资产；
#   已 accepted/rejected 的不动。--reject 列出的记 reject，其余 accept。
# =============================================================================
set -Eeuo pipefail
[[ $# -ge 4 ]] || { sed -n 2,16p "$0" >&2; exit 2; }
proj="$(cd "$1" && pwd)"; sub="$2"; stage="$3"; group="$4"; shift 4
rejects=""; note="用户看审阅页后签核"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --reject) rejects=",$2,"; shift 2 ;;
    --note)   note="$2"; shift 2 ;;
    *) echo "unknown arg $1" >&2; exit 2 ;;
  esac
done
root="$(cd "$(dirname "$0")/../.." && pwd)"
state="$proj/automation/$sub.paid-state.json"
[[ -f "$state" ]] || { echo "missing $state" >&2; exit 2; }
mkdir -p "$proj/automation/qc"

mapfile -t ids < <(jq -r --arg g "$group" \
  '.assets[] | select(.group==$g) | select(.status=="generated_pending_qc" or .status=="blocked_pending_semantic_qc") | .id' "$state")
[[ ${#ids[@]} -gt 0 ]] || { echo "组 $group 没有待验收资产"; exit 0; }

ts="$(date -Iseconds)"
for id in "${ids[@]}"; do
  act=accept; [[ "$rejects" == *",$id,"* ]] && act=reject
  out="$(jq -r --arg id "$id" '.assets[]|select(.id==$id)|.output' "$state")"
  sha="$(sha256sum "$root/$out" 2>/dev/null | awk '{print $1}')"
  ev="$proj/automation/qc/$id.user-$act.json"
  jq -n --arg id "$id" --arg act "$act" --arg ts "$ts" --arg note "$note" --arg out "$out" --arg sha "$sha" \
    '{asset_id:$id,result:$act,reviewer:"user",method:"用户看公网审阅页",at:$ts,note:$note,output:$out,sha256:$sha}' > "$ev"
  echo "== $id -> $act"
  "$root/run.sh" "$proj" "$stage" --sub "$sub" --phase "$act" --unit "$id" \
    --evidence "$ev" --note "$note" --reviewer user
done
echo "完成：${#ids[@]} 个资产。被 reject 的需重生成（新 id）后再次签核；全部解决后跑 gate-out。"
