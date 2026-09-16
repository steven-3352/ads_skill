#!/usr/bin/env bash
# [R]约束测试版(口径B):重排+按动作/人声节点拆段,零生成,仅用现有10条镜头。
# 目的:验证新加 [R] 节奏门照做能否把可量化指标(ASL/静默/首切/首声/片长)拉回合格。
# 不覆盖 final;输出 edit/xiaozhu-test-cutB.mp4。横屏未改(整片转竖=整片重做,已排除)。
set -euo pipefail
cd "$(dirname "$0")/.."
SH=shots; W=edit/_tcb; OUT=edit/xiaozhu-test-cutB.mp4
rm -rf "$W"; mkdir -p "$W"

# 片段表: 序号 源文件 起点ss 时长t  —— 暖峰钩子前置,冷转+钩子收尾
# 1 暖钩子(亲抱数条件,人声0起) 2 拽人 3 举高高 4 正反打(烧字幕版) 5 掀被叫起
# 6 赖床 7 背起走向餐厅 8 空床冷转(现在) 9 手机"一年前的今天"钩子
CLIPS=(
  "S06 $SH/S06/S06-U1.mp4 0.00 2.6"
  "S05 $SH/S05/S05-U1.mp4 1.50 2.4"
  "S07 $SH/S07/S07-U1.mp4 1.50 2.3"
  "S04 $SH/S04/S04-U1.burned-subtitle.mp4 0.30 2.0"
  "S02 $SH/S02/S02-U1.mp4 0.50 1.8"
  "S03 $SH/S03/S03-U1.mp4 2.50 1.9"
  "S08 $SH/S08/S08-U1.mp4 1.00 2.0"
  "S01 $SH/S01/S01-U1.mp4 2.60 1.3"
  "S10 $SH/S10/S10-U1.mp4 1.00 2.2"
)
SILENT="S01 S09"  # 冷段不做响度归一,避免抬噪
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
