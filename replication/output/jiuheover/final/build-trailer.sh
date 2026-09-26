#!/usr/bin/env bash
# 《酒喝完了，我们散了》预告片装配 —— 可复现
# 输出: final/trailer-jiuheover.mp4 (预告片正片: U1-U8 + 金句卡 + 片名卡)
set -euo pipefail
cd "$(dirname "$0")"
ROOT=".."
SERIF="/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc"
SANS="/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
W=768; H=1344; FPS=24; AR=48000
mkdir -p parts cards

echo "== [1/4] 主体 U1-U8 重编码拼接(干净时间戳) =="
ffmpeg -y \
  -i "$ROOT/shots/shot-U1/videos/U1-video.mp4" \
  -i "$ROOT/shots/shot-U2/videos/U2-video-r2.mp4" \
  -i "$ROOT/shots/shot-U3/videos/U3-video.mp4" \
  -i "$ROOT/shots/shot-U4/videos/U4-video.mp4" \
  -i "$ROOT/shots/shot-U5/videos/U5-video.mp4" \
  -i "$ROOT/shots/shot-U6/videos/U6-video.mp4" \
  -i "$ROOT/shots/shot-U7/videos/U7-video.mp4" \
  -i "$ROOT/shots/shot-U8/videos/U8-video.mp4" \
  -filter_complex \
   "[0:v]setsar=1,fps=$FPS,scale=$W:$H[v0];[1:v]setsar=1,fps=$FPS,scale=$W:$H[v1];[2:v]setsar=1,fps=$FPS,scale=$W:$H[v2];[3:v]setsar=1,fps=$FPS,scale=$W:$H[v3];[4:v]setsar=1,fps=$FPS,scale=$W:$H[v4];[5:v]setsar=1,fps=$FPS,scale=$W:$H[v5];[6:v]setsar=1,fps=$FPS,scale=$W:$H[v6];[7:v]setsar=1,fps=$FPS,scale=$W:$H[v7];[0:a]aresample=$AR[a0];[1:a]aresample=$AR[a1];[2:a]aresample=$AR[a2];[3:a]aresample=$AR[a3];[4:a]aresample=$AR[a4];[5:a]aresample=$AR[a5];[6:a]aresample=$AR[a6];[7:a]aresample=$AR[a7];[v0][a0][v1][a1][v2][a2][v3][a3][v4][a4][v5][a5][v6][a6][v7][a7]concat=n=8:v=1:a=1[v][a]" \
  -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -r $FPS \
  -c:a aac -b:a 160k -ar $AR -ac 2 parts/body.mp4 >/dev/null 2>&1
echo "   body: $(ffprobe -v error -show_entries format=duration -of csv=p=0 parts/body.mp4)s"

echo "== [2/4] 金句黑场卡(5s·黑场渐入·极轻雨底渐隐) =="
ffmpeg -y -loop 1 -i "$ROOT/shots/shot-U9/images/U9-title.png" \
  -f lavfi -i "anoisesrc=color=pink:d=5:r=$AR" \
  -filter_complex \
   "[0:v]scale=$W:$H,fade=t=in:st=0:d=0.6,format=yuv420p[v];[1:a]lowpass=f=2200,volume=0.05,pan=stereo|c0=c0|c1=c0,afade=t=in:st=0:d=0.3,afade=t=out:st=3:d=2[a]" \
  -map "[v]" -map "[a]" -t 5 -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -r $FPS \
  -c:a aac -b:a 160k -ar $AR -ac 2 cards/card-quote.mp4 >/dev/null 2>&1
echo "   card-quote: $(ffprobe -v error -show_entries format=duration -of csv=p=0 cards/card-quote.mp4)s"

echo "== [3/4] 片名卡(3.4s·serif片名+正片见CTA) =="
MAIN=$(cat cards/title-main.txt)
CTA=$(cat cards/title-cta.txt)
ffmpeg -y -f lavfi -i "color=c=black:s=${W}x${H}:d=3.4:r=$FPS" \
  -f lavfi -i "anoisesrc=color=pink:d=3.4:r=$AR" \
  -filter_complex \
   "[0:v]drawtext=fontfile=$SERIF:text='$MAIN':fontcolor=white:fontsize=76:x=(w-text_w)/2:y=(h-text_h)/2-40,drawbox=x=(iw-140)/2:y=ih/2+70:w=140:h=3:color=white@0.55:t=fill,drawtext=fontfile=$SANS:text='$CTA':fontcolor=white@0.75:fontsize=34:x=(w-text_w)/2:y=h/2+110,fade=t=in:st=0:d=0.6,fade=t=out:st=2.9:d=0.5,format=yuv420p[v];[1:a]lowpass=f=2000,volume=0.03,pan=stereo|c0=c0|c1=c0,afade=t=out:st=1.4:d=2[a]" \
  -map "[v]" -map "[a]" -t 3.4 -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -r $FPS \
  -c:a aac -b:a 160k -ar $AR -ac 2 cards/card-title.mp4 >/dev/null 2>&1
echo "   card-title: $(ffprobe -v error -show_entries format=duration -of csv=p=0 cards/card-title.mp4)s"

echo "== [4/4] 拼接预告片正片 =="
printf "file 'parts/body.mp4'\nfile 'cards/card-quote.mp4'\nfile 'cards/card-title.mp4'\n" > concat-final.txt
ffmpeg -y -f concat -safe 0 -i concat-final.txt \
  -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -r $FPS \
  -c:a aac -b:a 160k -ar $AR -ac 2 -movflags +faststart trailer-jiuheover.mp4 >/dev/null 2>&1
echo "   ✔ trailer-jiuheover.mp4  总时长: $(ffprobe -v error -show_entries format=duration -of csv=p=0 trailer-jiuheover.mp4)s"
