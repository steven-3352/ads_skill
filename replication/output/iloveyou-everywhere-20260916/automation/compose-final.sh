#!/usr/bin/env bash
# 终版合成 v4:画面(已拼接) + 三层音频
#   ① S01 真人告白原声(开头 0–2.5s,男「我喜欢你」+女「你再说一遍」,贴口型)
#   ② 空灵声床 soundbed(暖调pad情绪弧 + 逐界质感 + 过界whoosh,全程)
#   ③ 亿万合唱 voices_chorus(正确种子:各界回响 + S07高潮)
set -euo pipefail
cd "$(dirname "$0")/.."
T=automation/tmp; mkdir -p "$T"
VID=assets/final/iloveyou-v2.mp4          # 取其画面流(与v1/v3同一拼接画面)
BED=assets/audio/soundbed.wav
CHO=assets/audio/voices_chorus.wav
OUT=assets/final/iloveyou-v4.mp4

# ① S01 开头真人告白(0–2.5s),清理+淡出,置于时间线开头
ffmpeg -y -loglevel error -ss 0.30 -t 2.30 -i assets/clips/S01.mp4 \
  -af "highpass=f=90,lowpass=f=8500,afftdn=nf=-24,loudnorm=I=-15:TP=-1.5,afade=t=in:st=0:d=0.05,afade=t=out:st=2.05:d=0.25,adelay=300|300,aformat=channel_layouts=stereo" \
  "$T/s01conf.wav"

# 三层混音 → 统一响度 → 限幅
ffmpeg -y -loglevel error -i "$BED" -i "$CHO" -i "$T/s01conf.wav" \
  -filter_complex "[0:a]volume=0.85[bed];[1:a]volume=1.0[cho];[2:a]volume=1.15[conf];\
[bed][cho][conf]amix=inputs=3:duration=longest:normalize=0:dropout_transition=0[mx];\
[mx]loudnorm=I=-16:TP=-1.2:LRA=11,alimiter=limit=0.96,aformat=channel_layouts=stereo[out]" \
  -map "[out]" -t 17.568 "$T/final_mix.wav"

# 与画面合成(画面拷流不重压,音频AAC)
ffmpeg -y -loglevel error -i "$VID" -i "$T/final_mix.wav" \
  -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k -shortest "$OUT"

echo "== iloveyou-v4 done =="
ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT"
ffprobe -v error -select_streams a -show_entries stream=codec_name,channels -of csv=p=0 "$OUT"
echo "分段mean(0=真声告白 / 4-12=各界 / 15=亿万高潮):"
for i in 0 2 5 8 11 14 15 16; do
  r=$(ffmpeg -hide_banner -ss $i -t 1.5 -i "$OUT" -af volumedetect -f null /dev/null 2>&1 | grep mean_volume | awk '{print $5}')
  echo "  ${i}s: $r dB"
done
ls -la "$OUT"
