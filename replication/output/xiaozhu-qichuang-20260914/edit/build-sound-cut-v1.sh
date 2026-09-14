#!/usr/bin/env bash
# 声音初剪 v1(响度归一版):
#  - 对白镜 S02..S08: two-pass loudnorm 归一到 I=-18 LUFS / TP=-1.5,消除 -13~-24 LUFS 落差
#  - 冷段镜 S01/S09/S10: 近静音属演出,不做 loudnorm(避免抬噪),仅统一 aac 编码
#  - 视频流一律 copy 不转码;音频统一 aac 44100 stereo 192k → concat -c copy
# freesound 音效待服务恢复后在 v2 叠加。
set -euo pipefail
ROOT=/home/ubuntu/ads_skill/replication/output/xiaozhu-qichuang-20260914
WORK=/tmp/xz-soundv1; mkdir -p "$WORK"
cd "$ROOT/shots"

DIALOG="S02 S03 S04 S05 S06 S07 S08"
COLD="S01 S09 S10"
AAC="-c:a aac -ar 44100 -ac 2 -b:a 192k"

# 纯线性增益对齐:不做压缩(保留演出动态),只把各镜体感响度移到 -18 LUFS 附近;
# 增益上限受 TP 约束(峰值不超 -1.5 dBTP),避免削波。
TARGET=-18; TPMAX=-1.5
norm_shot () {  # $1=shot
  local s=$1 f="$ROOT/shots/$1/$1-U1.mp4"
  local j m_i m_tp gain tpcap final
  j=$(ffmpeg -hide_banner -i "$f" -af loudnorm=I=-18:TP=-1.5:LRA=11:print_format=json -f null - 2>&1 | sed -n '/{/,/}/p')
  m_i=$(echo "$j"|grep input_i|cut -d'"' -f4);  m_tp=$(echo "$j"|grep input_tp|cut -d'"' -f4)
  gain=$(awk "BEGIN{print $TARGET-($m_i)}")
  tpcap=$(awk "BEGIN{print $TPMAX-($m_tp)}")
  final=$(awk "BEGIN{g=$gain;c=$tpcap; print (g<c)?g:c}")
  echo "   $s: I=$m_i TP=$m_tp → gain=${final}dB"
  ffmpeg -v error -i "$f" -map 0:v -map 0:a -c:v copy -af "volume=${final}dB" $AAC "$WORK/$s.mp4" -y
}

for s in $DIALOG; do echo "归一 $s ..."; norm_shot "$s"; done
for s in $COLD;   do echo "统一编码(不抬噪) $s ..."; ffmpeg -v error -i "$ROOT/shots/$s/$s-U1.mp4" -map 0:v -map 0:a -c:v copy $AAC "$WORK/$s.mp4" -y; done

LIST="$WORK/list.txt"; : > "$LIST"
for s in S01 S02 S03 S04 S05 S06 S07 S08 S09 S10; do echo "file '$WORK/$s.mp4'" >> "$LIST"; done
OUT="$ROOT/edit/xiaozhu-sound-cut-v1.mp4"
ffmpeg -v error -f concat -safe 0 -i "$LIST" -c copy -movflags +faststart "$OUT" -y
echo "完成: $OUT"
ffprobe -v error -show_entries format=duration -of default=nw=1:nk=1 "$OUT"
