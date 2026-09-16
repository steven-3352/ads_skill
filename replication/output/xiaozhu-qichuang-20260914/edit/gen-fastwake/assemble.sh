#!/usr/bin/env bash
# 生成端节奏测试组装:长镜锚点拆段法产物 C1/C2/C3(各6.58s)→ 各弃锚点尾(5.0–6.58s)、
# 取 0–5.0s(=b1定调+b2转折两拍)→ 顺接 3 条 = 15.0s,竖屏 9:16。
# 零重排、保场景顺序(掀被→抗拒→拽拉→赖床→扶坐→醒神)。
set -euo pipefail
cd "$(dirname "$0")"
C=clips; W=_asm; OUT=fastwake-15s.mp4
rm -rf "$W"; mkdir -p "$W"
CLIPS=("C1 $C/C1-video.mp4" "C2 $C/C2-video.mp4" "C3 $C/C3-video.mp4")
LIST="$W/list.txt"; : > "$LIST"; i=0
for row in "${CLIPS[@]}"; do
  set -- $row; tag=$1; f=$2; i=$((i+1))
  seg="$W/$(printf '%02d' $i)-$tag.ts"
  ffmpeg -v error -y -i "$f" -ss 0 -t 5.0 \
    -vf "fps=24,scale=768:1344,setsar=1" -c:v libx264 -crf 20 -preset veryfast -pix_fmt yuv420p \
    -af "loudnorm=I=-18:TP=-1.5:LRA=11,aresample=44100" -c:a aac -ac 2 -ar 44100 -b:a 192k \
    -f mpegts "$seg"
  echo "file '$(basename "$seg")'" >> "$LIST"
done
( cd "$W" && ffmpeg -v error -y -f concat -safe 0 -i list.txt -c copy -bsf:a aac_adtstoasc -movflags +faststart "../$OUT" )
echo "OK -> $OUT ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")s)"