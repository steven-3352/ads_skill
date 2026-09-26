#!/usr/bin/env bash
# v3 全长重拼(修 v2 弃尾丢信息):C1/C2/C3-v2 各取【全长 6.583s】,不再 -t 5.0 砍尾。
# 找回被丢的第三动作拍:C1 翻身伸懒腰赖床 / C2 缩回被窝 / C3 揉脸醒神→转头互动(暖收尾)。
# 零重生成、零重排,保场景顺序(掀被→抗拒→拽拉→赖床→扶坐→醒神)。横屏 16:9(1344×768)。
# 不覆盖 15s 版;输出 fastwake-full-v3.mp4。
set -euo pipefail
cd "$(dirname "$0")"
C=clips; W=_asm-v3; OUT=fastwake-full-v3.mp4
rm -rf "$W"; mkdir -p "$W"
CLIPS=("C1 $C/C1-v2.mp4" "C2 $C/C2-v2.mp4" "C3 $C/C3-v2.mp4")
LIST="$W/list.txt"; : > "$LIST"; i=0
for row in "${CLIPS[@]}"; do
  set -- $row; tag=$1; f=$2; i=$((i+1))
  seg="$W/$(printf '%02d' $i)-$tag.ts"
  # 全长:不加 -t,整条 6.583s 进片
  ffmpeg -v error -y -i "$f" \
    -vf "fps=24,scale=1344:768,setsar=1" -c:v libx264 -crf 20 -preset veryfast -pix_fmt yuv420p \
    -af "loudnorm=I=-18:TP=-1.5:LRA=11,aresample=44100" -c:a aac -ac 2 -ar 44100 -b:a 192k \
    -f mpegts "$seg"
  echo "file '$(basename "$seg")'" >> "$LIST"
done
( cd "$W" && ffmpeg -v error -y -f concat -safe 0 -i list.txt -c copy -bsf:a aac_adtstoasc -movflags +faststart "../$OUT" )
echo "OK -> $OUT ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")s)"
