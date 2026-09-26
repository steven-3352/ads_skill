#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
CASE_DIR="$ROOT_DIR/replication/output/wedding-mother-bag-ad"
EDIT_DIR="$CASE_DIR/edit"
OUT_DIR="$CASE_DIR/generated"
SCENE="$OUT_DIR/route-b-scene.mp4"
FONT="/System/Library/Fonts/PingFang.ttc"
FINAL="$OUT_DIR/wedding-mother-bag-route-b-15s.mp4"

[[ -s "$SCENE" ]] || { echo "缺少生成场景: $SCENE" >&2; exit 1; }
mkdir -p "$OUT_DIR"

say -v Tingting -r 140 -f "$EDIT_DIR/voiceover.txt" -o "$OUT_DIR/voiceover.aiff"
python3 "$EDIT_DIR/render-overlays.py"
PRODUCT="$EDIT_DIR/product-hero.png"

ffmpeg -y \
  -i "$SCENE" \
  -loop 1 -framerate 30 -t 3 -i "$PRODUCT" \
  -i "$OUT_DIR/voiceover.aiff" \
  -loop 1 -framerate 30 -i "$EDIT_DIR/caption-checklist.png" \
  -loop 1 -framerate 30 -i "$EDIT_DIR/caption-all-ready.png" \
  -loop 1 -framerate 30 -i "$EDIT_DIR/caption-last-item.png" \
  -loop 1 -framerate 30 -i "$EDIT_DIR/caption-best-self.png" \
  -filter_complex "
    [0:v]trim=0:12,setpts=PTS-STARTPTS,scale=1080:1920:force_original_aspect_ratio=increase,crop=1080:1920,
      fps=30,format=rgba[scene];
    [3:v]format=rgba[cap1];[4:v]format=rgba[cap2];[5:v]format=rgba[cap3];[6:v]format=rgba[cap4];
    [scene][cap1]overlay=shortest=1:enable='between(t,0.25,3.7)'[s1];
    [s1][cap2]overlay=shortest=1:enable='between(t,3.7,5.7)'[s2];
    [s2][cap3]overlay=shortest=1:enable='between(t,5.7,7.4)'[s3];
    [s3][cap4]overlay=shortest=1:enable='between(t,7.4,12)',format=yuv420p[vscene];
    [1:v]zoompan=z='min(zoom+0.0003,1.027)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=90:s=1080x1920:fps=30,
      fade=t=in:st=0:d=0.22,format=yuv420p,setpts=PTS-STARTPTS[vproduct];
    [vscene][vproduct]concat=n=2:v=1:a=0[video];
    [0:a]atrim=0:12,asetpts=PTS-STARTPTS,volume=0.32,afade=t=out:st=11.2:d=0.8,apad=pad_dur=15[bed];
    [2:a]volume=1.25,adelay=180|180,apad=pad_dur=15[voice];
    [bed][voice]amix=inputs=2:duration=longest:normalize=0,atrim=0:15,alimiter=limit=0.94[audio]
  " \
  -map "[video]" -map "[audio]" -t 15 \
  -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
  -c:a aac -b:a 192k -movflags +faststart "$FINAL"

for SECOND in 2.0 6.2 10.2 13.5; do
  ffmpeg -y -ss "$SECOND" -i "$FINAL" -frames:v 1 "$OUT_DIR/preview-${SECOND}s.png"
done

ffprobe -v error -show_entries format=duration:stream=codec_name,width,height,r_frame_rate -of json "$FINAL"
