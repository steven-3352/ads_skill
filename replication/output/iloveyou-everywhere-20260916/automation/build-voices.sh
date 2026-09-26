#!/usr/bin/env bash
# 用抠出的真实「我喜欢你」种子(seed_S01),多层 pitch/延迟/声像/混响变换,
# 造"各种音色的我喜欢你"层叠合唱:开头告白本体清晰 → 各界稀疏回响 → S07密集"亿万"。
# 无额外付费,纯 ffmpeg 变换真实人声。
set -euo pipefail
cd "$(dirname "$0")/.."
T=automation/tmp; mkdir -p "$T" assets/audio
# 正确种子:S01 男生第一句「我喜欢你」(0.37–1.25s),已抠净归一。
# (旧 seed_S01 抠的是女生「你再说一遍」,内容错,已弃用)
SEED=assets/audio/voices/seed_man_wxhn.wav
SR=24000
DUR=17.568

# 种子已是干净的「我喜欢你」(~0.97s),仅补首尾微淡入淡出
ffmpeg -y -loglevel error -ss 0.02 -t 0.92 -i "$SEED" -af "afade=t=in:st=0:d=0.03,afade=t=out:st=0.84:d=0.08" "$T/vseed.wav"

# 生成单个变换副本: pitch(保时长) + gain + pan(L/R) + 前置静音定位
mkvoice(){ # $1 out $2 time $3 pitch $4 gain $5 panL $6 panR
  local out=$1 time=$2 p=$3 g=$4 pl=$5 pr=$6
  local ms; ms=$(printf "%.0f" "$(echo "$time*1000"|bc -l)")
  local newsr; newsr=$(printf "%.0f" "$(echo "$SR*$p"|bc -l)")
  ffmpeg -y -loglevel error -i "$T/vseed.wav" \
    -af "asetrate=${newsr},aresample=${SR},atempo=$(echo "1/$p"|bc -l),volume=${g},pan=stereo|c0=${pl}*c0|c1=${pr}*c0,adelay=${ms}|${ms}" \
    "$out"
}

idx=0; INPUTS=();
add(){ mkvoice "$T/v_$idx.wav" "$1" "$2" "$3" "$4" "$5"; INPUTS+=("$T/v_$idx.wav"); idx=$((idx+1)); }

# —— 稀疏区:逐界回响(单声清晰,不同音色)。开头告白本体改用 S01 真人原声,合唱不再重复 ——
add 4.10 1.12 0.44 0.82 0.40   # 天上 女声偏左
add 6.55 0.86 0.44 0.40 0.82   # 山川 男声偏右
add 8.90 1.22 0.38 0.78 0.52   # 森林 童声感
add 11.10 0.94 0.42 0.50 0.78  # 海底
add 13.40 1.06 0.42 0.66 0.62  # 地下

# —— 高潮区 S07(14.9-17.2s):密集错位堆叠 = 亿万层叠 ——
RANDOM=20260917
for n in $(seq 1 30); do
  t=$(echo "14.9 + ($RANDOM % 2300)/1000"|bc -l)
  p=$(echo "0.80 + ($RANDOM % 620)/1000"|bc -l)     # 0.80–1.42 音色分布
  g=$(echo "0.14 + ($RANDOM % 130)/1000"|bc -l)     # 0.14–0.27
  pl=$(echo "0.35 + ($RANDOM % 650)/1000"|bc -l)
  pr=$(echo "0.35 + ($RANDOM % 650)/1000"|bc -l)
  add "$t" "$p" "$g" "$pl" "$pr"
done

# 混所有声部 → 空间混响 → 归一化限幅 → 人声合唱层
args=(); for f in "${INPUTS[@]}"; do args+=(-i "$f"); done
ffmpeg -y -loglevel error "${args[@]}" \
 -filter_complex "amix=inputs=${#INPUTS[@]}:duration=longest:normalize=0:dropout_transition=0,aecho=0.8:0.9:80|160|240:0.4|0.3|0.2,aformat=channel_layouts=stereo,loudnorm=I=-18:TP=-1.5,alimiter=limit=0.95" \
 -t "$DUR" assets/audio/voices_chorus.wav

echo "== voices_chorus done =="; ls -la assets/audio/voices_chorus.wav
echo "分段RMS(看开头清晰/高潮堆厚):"
for i in 0 4 6 8 10 12 14 16; do
  r=$(ffmpeg -hide_banner -ss $i -t 2 -i assets/audio/voices_chorus.wav -af volumedetect -f null /dev/null 2>&1 | grep mean_volume | awk '{print $5}')
  echo "  ${i}s: $r dB"
done