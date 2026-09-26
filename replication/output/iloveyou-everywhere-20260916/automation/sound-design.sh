#!/usr/bin/env bash
# 程序化声音床(无TTS):暖调空灵和声pad(情绪弧渐强到上帝视角)+ 逐界质感层
# (海底低频涌动/晶洞高频shimmer)+ 6处过界whoosh。人声「我喜欢你」层留占位待补。
# 全部 ffmpeg 合成,48kHz 立体声,时长对齐成片 17.568s。
set -euo pipefail
cd "$(dirname "$0")/.."
T=automation/tmp; mkdir -p "$T" assets/audio
DUR=17.568

# 1) 暖调和声 PAD:C大调加九和弦叠 sine → chorus加宽 → 长混响 → 柔化低通 → 呼吸tremolo
#    情绪弧:afade缓入 + volume随t渐强,S07(>15s)满溢
ffmpeg -y -loglevel error -f lavfi -i \
"aevalsrc=0.20*sin(2*PI*130.81*t)+0.16*sin(2*PI*196.00*t)+0.15*sin(2*PI*261.63*t)+0.13*sin(2*PI*329.63*t)+0.09*sin(2*PI*392.00*t)+0.05*sin(2*PI*523.25*t):d=$DUR:s=48000" \
-af "chorus=0.6:0.9:55|75:0.4|0.3:0.25|0.4:2|1.5,aecho=0.8:0.85:600|1200|1800:0.35|0.25|0.18,lowpass=f=2600,tremolo=f=0.18:d=0.25,volume='0.28+0.55*min(t/16,1)':eval=frame,afade=t=in:st=0:d=1.6,afade=t=out:st=16.6:d=0.95,aformat=channel_layouts=stereo" \
"$T/pad.wav"

# 2) 过界 WHOOSH:棕噪 0.6s 下坠包络,放 6 个叠化点强化"向下穿透"
OFFS=(3.0 5.3 7.6 9.9 12.3 14.6)
idx=0
for off in "${OFFS[@]}"; do
  ms=$(printf "%.0f" "$(echo "$off*1000"|bc -l)")
  ffmpeg -y -loglevel error -f lavfi -i "anoisesrc=color=brown:d=0.7:s=48000:a=0.5" \
   -af "highpass=f=180,lowpass=f=4200,volume='exp(-12*(t-0.28)*(t-0.28))':eval=frame,aecho=0.8:0.8:300:0.3,adelay=${ms}|${ms},aformat=channel_layouts=stereo,volume=0.5" \
   "$T/wh_$idx.wav"
  idx=$((idx+1))
done

# 3) 海底涌动(10.3-13.1s):棕噪低通 + 缓慢起伏,adelay 10300
ffmpeg -y -loglevel error -f lavfi -i "anoisesrc=color=brown:d=3.0:s=48000:a=0.7" \
 -af "lowpass=f=320,tremolo=f=0.35:d=0.5,afade=t=in:st=0:d=0.6,afade=t=out:st=2.4:d=0.6,adelay=10300|10300,aformat=channel_layouts=stereo,volume=0.6" \
 "$T/sea.wav"

# 4) 晶洞 shimmer(12.9-15.4s):高频 sine 群 + 慢 tremolo,清透铃感,adelay 12900
ffmpeg -y -loglevel error -f lavfi -i \
"aevalsrc=0.10*sin(2*PI*3136*t)+0.08*sin(2*PI*4186*t)+0.06*sin(2*PI*5274*t)+0.05*sin(2*PI*6272*t):d=2.6:s=48000" \
 -af "tremolo=f=6:d=0.7,aecho=0.8:0.85:220|440:0.4|0.3,highpass=f=2000,afade=t=in:st=0:d=0.5,afade=t=out:st=2.0:d=0.6,adelay=12900|12900,aformat=channel_layouts=stereo,volume=0.5" \
 "$T/crys.wav"

# 5) 上帝视角光辉 shimmer 满溢(15.0-17.5s):高频和声堆叠渐强(人声占位处的器乐替身)
ffmpeg -y -loglevel error -f lavfi -i \
"aevalsrc=0.09*sin(2*PI*523.25*t)+0.08*sin(2*PI*659.25*t)+0.07*sin(2*PI*783.99*t)+0.06*sin(2*PI*1046.5*t):d=2.6:s=48000" \
 -af "chorus=0.5:0.8:40|60:0.4|0.3:0.3|0.4:2|1.5,aecho=0.8:0.85:500|1000:0.4|0.3,tremolo=f=0.4:d=0.3,afade=t=in:st=0:d=1.2,afade=t=out:st=2.0:d=0.6,adelay=15000|15000,aformat=channel_layouts=stereo,volume=0.55" \
 "$T/glory.wav"

# 6) 混所有层 → loudnorm 统一 → 生成声床
ffmpeg -y -loglevel error \
 -i "$T/pad.wav" -i "$T/wh_0.wav" -i "$T/wh_1.wav" -i "$T/wh_2.wav" -i "$T/wh_3.wav" -i "$T/wh_4.wav" -i "$T/wh_5.wav" \
 -i "$T/sea.wav" -i "$T/crys.wav" -i "$T/glory.wav" \
 -filter_complex "amix=inputs=10:duration=first:normalize=0:dropout_transition=0,loudnorm=I=-17:TP=-1.5:LRA=11,alimiter=limit=0.95,aformat=channel_layouts=stereo" \
 -t "$DUR" "assets/audio/soundbed.wav"

echo "== soundbed done =="
ffprobe -v error -show_entries format=duration -of csv=p=0 assets/audio/soundbed.wav
ls -la assets/audio/soundbed.wav