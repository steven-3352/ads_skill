#!/usr/bin/env bash
# 拼装《小猪起床了》画面初剪：10 条按 S01..S10 顺序硬切(含 S01↔S02、S08↔S09 匹配剪辑)。
# 全部同参数(h264/1344x768/yuv420p/24fps/aac32k)→ 流拷贝直连，不转码。
# 声音：暂沿用 H3 原声作粗定位参考(待下一轮定配音)。
set -euo pipefail
ROOT=/home/ubuntu/ads_skill/replication/output/xiaozhu-qichuang-20260914
cd "$ROOT/shots"
LIST=/tmp/xiaozhu-concat.txt
: > "$LIST"
for s in S01 S02 S03 S04 S05 S06 S07 S08 S09 S10; do
  f="$ROOT/shots/$s/$s-U1.mp4"
  [[ -f "$f" ]] || { echo "缺 $f"; exit 1; }
  echo "file '$f'" >> "$LIST"
done
OUT="$ROOT/edit/xiaozhu-picture-cut.mp4"
mkdir -p "$ROOT/edit"
ffmpeg -v error -f concat -safe 0 -i "$LIST" -c copy -movflags +faststart "$OUT" -y
echo "拼装完成: $OUT"
ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$OUT"
