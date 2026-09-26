#!/usr/bin/env bash
# 《酒喝完了，我们散了》预告片·极短版(冷启动完播优化) —— 可复现
# 数据反馈:50s原版完播16.67%/平均看17.38s,中段对白戏流失严重。
# 对策:砍掉中段U4-U7,只留 钩子U1→反刺U2→立局U3(五年羁绊手部动作)→落点U8裁段→金句卡。
# 裁剪原则:保整句台词,cut点落在silencedetect的静音间隙,不切半句。
# 输出: final/trailer-jiuheover-short.mp4  (≈22.6s)
set -euo pipefail
cd "$(dirname "$0")"
ROOT=".."
W=768; H=1344; FPS=24; AR=48000
mkdir -p parts cards

U1="$ROOT/shots/shot-U1/videos/U1-video.mp4"
U2="$ROOT/shots/shot-U2/videos/U2-video-r2.mp4"
U3="$ROOT/shots/shot-U3/videos/U3-video.mp4"
U8="$ROOT/shots/shot-U8/videos/U8-video.mp4"
U8_START=3.45   # 落在 U8 静音间隙(3.042-3.888),进"会但我会更努力留住你"

echo "== [1/3] 主体拼接 U1+U2+U3+U8(裁段) =="
ffmpeg -y -i "$U1" -i "$U2" -i "$U3" -i "$U8" -filter_complex \
 "[0:v]setsar=1,fps=$FPS,scale=$W:$H[v0];\
  [1:v]setsar=1,fps=$FPS,scale=$W:$H[v1];\
  [2:v]setsar=1,fps=$FPS,scale=$W:$H[v2];\
  [3:v]trim=start=$U8_START,setpts=PTS-STARTPTS,setsar=1,fps=$FPS,scale=$W:$H[v3];\
  [0:a]aresample=$AR[a0];\
  [1:a]aresample=$AR[a1];\
  [2:a]aresample=$AR[a2];\
  [3:a]atrim=start=$U8_START,asetpts=PTS-STARTPTS,aresample=$AR,afade=t=in:st=0:d=0.1[a3];\
  [v0][a0][v1][a1][v2][a2][v3][a3]concat=n=4:v=1:a=1[v][a]" \
 -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -r $FPS \
 -c:a aac -b:a 160k -ar $AR -ac 2 parts/body-short.mp4 >/dev/null 2>&1
echo "   body-short: $(ffprobe -v error -show_entries format=duration -of csv=p=0 parts/body-short.mp4)s"

echo "== [2/3] 金句黑场卡(2.5s·渐入·极轻雨底渐隐) =="
ffmpeg -y -loop 1 -i "$ROOT/shots/shot-U9/images/U9-title.png" \
  -f lavfi -i "anoisesrc=color=pink:d=2.5:r=$AR" \
  -filter_complex \
   "[0:v]scale=$W:$H,fade=t=in:st=0:d=0.5,format=yuv420p[v];[1:a]lowpass=f=2200,volume=0.05,pan=stereo|c0=c0|c1=c0,afade=t=in:st=0:d=0.3,afade=t=out:st=1.0:d=1.5[a]" \
  -map "[v]" -map "[a]" -t 2.5 -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -r $FPS \
  -c:a aac -b:a 160k -ar $AR -ac 2 cards/card-quote-short.mp4 >/dev/null 2>&1
echo "   card-quote-short: $(ffprobe -v error -show_entries format=duration -of csv=p=0 cards/card-quote-short.mp4)s"

echo "== [3/3] 拼接极短版 =="
printf "file 'parts/body-short.mp4'\nfile 'cards/card-quote-short.mp4'\n" > concat-short.txt
ffmpeg -y -f concat -safe 0 -i concat-short.txt \
  -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -r $FPS \
  -c:a aac -b:a 160k -ar $AR -ac 2 -movflags +faststart trailer-jiuheover-short.mp4 >/dev/null 2>&1
echo "   ✔ trailer-jiuheover-short.mp4  总时长: $(ffprobe -v error -show_entries format=duration -of csv=p=0 trailer-jiuheover-short.mp4)s"
