#!/usr/bin/env bash
# 无缝拼接 7 镜:每镜裁取连贯段 → 同向下行运动 0.4s dissolve 叠化(非硬切)。
# 视频用 xfade,音频用 acrossfade,保留各镜 H3 原生音轨(S01/S02 含中文告白)。
# 输出 v1(视觉成片,原声),后续叠加声音设计出 v2。
set -euo pipefail
cd "$(dirname "$0")/.."
CLIPS=assets/clips
OUT=assets/final
mkdir -p "$OUT" automation/tmp
T=automation/tmp

# 每镜: ss(起点) d(取用时长)
DECL=("S01 0.15 3.6" "S02 0.30 2.7" "S03 0.30 2.7" "S04 0.30 2.7" "S05 0.20 2.8" "S06 0.30 2.7" "S07 0.20 2.7")
XF=0.4   # 叠化时长

# 1) 裁段并统一编码(30fps, 48k 音频, 统一 SAR/tbn 便于 xfade)
i=0
for row in "${DECL[@]}"; do
  set -- $row; S=$1; SS=$2; D=$3
  ffmpeg -y -loglevel error -ss "$SS" -i "$CLIPS/$S.mp4" -t "$D" \
    -vf "fps=30,scale=1344:768:force_original_aspect_ratio=decrease,pad=1344:768:(ow-iw)/2:(oh-ih)/2,setsar=1" \
    -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
    -af "aresample=48000" -c:a aac -b:a 192k \
    "$T/seg_$S.mp4"
  i=$((i+1))
done

# 2) 链式 xfade + acrossfade
inputs=""; for row in "${DECL[@]}"; do set -- $row; inputs="$inputs -i $T/seg_$1.mp4"; done

# 计算 offset 并构建 filtergraph
declare -a D=(3.6 2.7 2.7 2.7 2.8 2.7 2.7)
vf=""; af=""
cum=${D[0]}
vprev="[0:v]"; aprev="[0:a]"
for k in 1 2 3 4 5 6; do
  off=$(echo "$cum - $XF" | bc -l)
  vlab="[v$k]"; alab="[a$k]"
  vf="$vf${vprev}[$k:v]xfade=transition=fade:duration=$XF:offset=$off$vlab;"
  af="$af${aprev}[$k:a]acrossfade=d=$XF:c1=tri:c2=tri$alab;"
  vprev="$vlab"; aprev="$alab"
  cum=$(echo "$cum + ${D[$k]} - $XF" | bc -l)
done
# 去掉末尾分号前的标签改为输出名
vf="${vf%;}"; af="${af%;}"

ffmpeg -y -loglevel error $inputs \
  -filter_complex "$vf;$af" \
  -map "$vprev" -map "$aprev" \
  -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -c:a aac -b:a 192k \
  "$OUT/iloveyou-v1.mp4"

echo "== v1 done =="
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT/iloveyou-v1.mp4"
ls -la "$OUT/iloveyou-v1.mp4"
