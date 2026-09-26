#!/usr/bin/env bash
# 《后知后觉》成片装配 v2（加开场引导镜 shot-00）
# 16 段：shot-00 开场引导 → [shot-01 冷战 → card-01 → ... → shot-07 现在 → card-07] → 尾板
set -euo pipefail
cd "$(dirname "$0")/.."   # -> houzhihoujue/
ROOT="$(pwd)"
OUT="$ROOT/final/houzhihoujue-final.mp4"

INPUTS=(
  "shots/shot-00/video/shot-00.mp4"   # 开场引导（含同期对白）
  "shots/shot-01/video/shot-01.mp4"   # 实景·冷战
  "final/cards/card-01.mp4"
  "shots/shot-02/video/shot-02.mp4"   # 实景·较劲
  "final/cards/card-02.mp4"
  "shots/shot-03/video/shot-03.mp4"   # 实景·幸福
  "final/cards/card-03.mp4"
  "shots/shot-04/video/shot-04.mp4"   # 实景·心疼
  "final/cards/card-04.mp4"
  "shots/shot-05/video/shot-05.mp4"   # 实景·迁就
  "final/cards/card-05.mp4"
  "shots/shot-06/video/shot-06.mp4"   # 实景·以为
  "final/cards/card-06.mp4"
  "shots/shot-07/video/shot-07.mp4"   # 实景·现在（黑底孤身）
  "final/cards/card-07.mp4"
  "final/cards/endslate.mp4"          # 尾板
)

N=${#INPUTS[@]}
args=(); filt=""
for i in "${!INPUTS[@]}"; do
  args+=( -i "${INPUTS[$i]}" )
  filt+="[${i}:v]scale=768:1344:force_original_aspect_ratio=decrease,pad=768:1344:(ow-iw)/2:(oh-ih)/2,setsar=1,fps=30,format=yuv420p[v${i}];"
  filt+="[${i}:a]aformat=sample_rates=44100:channel_layouts=stereo[a${i}];"
done
for i in $(seq 0 $((N-1))); do filt+="[v${i}][a${i}]"; done
filt+="concat=n=${N}:v=1:a=1[vout][aout]"

ffmpeg -y "${args[@]}" -filter_complex "$filt" \
  -map "[vout]" -map "[aout]" \
  -c:v libx264 -preset medium -crf 19 -pix_fmt yuv420p \
  -c:a aac -b:a 160k -movflags +faststart "$OUT"

echo "assembled -> $OUT"
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT"
