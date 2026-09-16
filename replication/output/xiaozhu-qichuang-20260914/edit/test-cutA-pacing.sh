#!/usr/bin/env bash
# [R]测试版·口径A修正:保持原叙事顺序 S01→S10,只做节奏卫生(砍静音/拆段/压时长),
# 零生成、不重排、不改因果。验证"不打乱故事"时 [R] 能满足到哪几项。
# 不覆盖 final;输出 edit/xiaozhu-test-cutA.mp4。
set -euo pipefail
cd "$(dirname "$0")/.."
SH=shots; W=edit/_tca; OUT=edit/xiaozhu-test-cutA.mp4
rm -rf "$W"; mkdir -p "$W"

# 原顺序,每镜取其动作/人声核心;S01/S09冷段静音块压到<1.5s以过R3
CLIPS=(
  "S01 $SH/S01/S01-U1.mp4 3.00 1.2"
  "S02 $SH/S02/S02-U1.mp4 0.45 2.0"
  "S03 $SH/S03/S03-U1.mp4 2.50 2.0"
  "S04 $SH/S04/S04-U1.burned-subtitle.mp4 0.30 2.6"
  "S05 $SH/S05/S05-U1.mp4 1.50 2.6"
  "S06 $SH/S06/S06-U1.mp4 0.00 2.8"
  "S07 $SH/S07/S07-U1.mp4 1.40 2.6"
  "S08 $SH/S08/S08-U1.mp4 0.80 2.2"
  "S09 $SH/S09/S09-U1.mp4 1.20 1.3"
  "S10 $SH/S10/S10-U1.mp4 0.80 2.4"
)
SILENT="S01 S09"
LIST="$W/list.txt"; : > "$LIST"; i=0
for row in "${CLIPS[@]}"; do
  set -- $row; tag=$1; f=$2; ss=$3; t=$4; i=$((i+1))
  seg="$W/$(printf '%02d' $i)-$tag.ts"
  if echo " $SILENT " | grep -q " $tag "; then AF="anull"; else AF="loudnorm=I=-18:TP=-1.5:LRA=11"; fi
  ffmpeg -v error -y -i "$f" -ss "$ss" -t "$t" \
    -vf "fps=24,scale=1344:768,setsar=1" -c:v libx264 -crf 20 -preset veryfast -pix_fmt yuv420p \
    -af "$AF,aresample=44100" -c:a aac -ac 2 -ar 44100 -b:a 192k \
    -f mpegts "$seg"
  echo "file '$(basename "$seg")'" >> "$LIST"
done
( cd "$W" && ffmpeg -v error -y -f concat -safe 0 -i list.txt -c copy -bsf:a aac_adtstoasc -movflags +faststart "../$(basename "$OUT")" )
echo "OK -> $OUT"
