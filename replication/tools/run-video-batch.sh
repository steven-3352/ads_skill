#!/usr/bin/env bash
# 付费视频批量的唯一 sanctioned 入口。强制：金丝雀(顺序执行=首个即验证) + 见拒即停。
#
# 为什么顺序而非并发：账户余额可能只够几条(实测 15 条只出 3 条即 226638 积分不足)。
# 并发一次性把余额烧在多条 in-flight 创建上；顺序执行时，某条创建返回 exit 3(积分不足/被拒)
# 立即停止，最多损失当前这一条。generate-video.sh 的 RetCode 门禁保证被拒是硬失败(exit 3)。
#
# 用法:
#   run-video-batch.sh --project-root <绝对路径> [--provider minimax] < jobs.tsv
#   jobs.tsv 每行(TAB 分隔): <prompt.json 相对project-root> <输出目录 相对> <输出名.json> [ref1,ref2 逗号分隔;留空则读 prompt 的 .images]
# 退出码: 0 全部成功/跳过; 3 见拒即停(积分不足等); 1 其他失败。
set -uo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GEN="$BASE_DIR/generate-video.sh"
PROJECT_ROOT=""
PROVIDER="minimax"
KEEP_GOING=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project-root) PROJECT_ROOT="${2:-}"; shift 2 ;;
    --provider) PROVIDER="${2:-}"; shift 2 ;;
    --keep-going) KEEP_GOING=true; shift ;;   # 非积分类失败时继续(仍在 exit3 硬停)
    -h|--help) sed -n '2,14p' "$0" >&2; exit 2 ;;
    *) echo "未知参数: $1" >&2; exit 2 ;;
  esac
done
[[ -n "$PROJECT_ROOT" && -d "$PROJECT_ROOT" ]] || { echo "需要有效的 --project-root" >&2; exit 2; }
command -v jq >/dev/null || { echo "需要 jq" >&2; exit 2; }

ok=0; skip=0; fail=0; idx=0
while IFS=$'\t' read -r PF ODIR ONAME REFS; do
  [[ -n "${PF:-}" ]] || continue
  [[ "$PF" == \#* ]] && continue
  idx=$((idx+1))
  mp4="$PROJECT_ROOT/$ODIR/${ONAME%.json}.mp4"
  if [[ -e "$mp4" ]]; then echo "[$idx] SKIP 已存在: $ODIR/${ONAME%.json}.mp4"; skip=$((skip+1)); continue; fi

  refargs=()
  if [[ -n "${REFS:-}" ]]; then
    IFS=',' read -ra RA <<< "$REFS"
    for r in "${RA[@]}"; do [[ -n "$r" ]] || continue; [[ "$r" == /* ]] || r="$PROJECT_ROOT/$r"; refargs+=(--reference "$r"); done
  else
    while IFS= read -r r; do [[ -n "$r" ]] || continue; refargs+=(--reference "$PROJECT_ROOT/$r"); done \
      < <(jq -r '.images[]?' "$PROJECT_ROOT/$PF" 2>/dev/null)
  fi

  echo "[$idx] 生成: $PF -> $ODIR/${ONAME%.json}.mp4 (refs=${#refargs[@]}/2)"
  bash "$GEN" --prompt "$PROJECT_ROOT/$PF" --output-dir "$PROJECT_ROOT/$ODIR" --output-name "$ONAME" \
    --provider "$PROVIDER" "${refargs[@]}" --wait --download
  rc=$?
  if [[ "$rc" -eq 3 ]]; then
    echo "==== 批量停止：第 $idx 条创建被拒(exit 3，通常=积分不足)。已完成 $ok，跳过 $skip。请充值后重跑(会自动跳过已成)。 ====" >&2
    exit 3
  elif [[ "$rc" -ne 0 ]]; then
    fail=$((fail+1)); echo "[$idx] 失败 exit=$rc" >&2
    [[ "$KEEP_GOING" == true ]] || { echo "==== 批量停止：第 $idx 条失败(exit $rc)。加 --keep-going 可跳过继续。 ====" >&2; exit 1; }
  else
    ok=$((ok+1))
  fi
done

echo "批量完成：成功 $ok，跳过 $skip，失败 $fail。"
[[ "$fail" -eq 0 ]] && exit 0 || exit 1
