#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
CASE_DIR="$ROOT_DIR/replication/output/wedding-mother-bag-ad"
EDIT_DIR="$CASE_DIR/edit"
OUT_DIR="$CASE_DIR/generated"
IMAGE="$CASE_DIR/assets/product-clean.png"
FONT="/System/Library/Fonts/PingFang.ttc"

mkdir -p "$OUT_DIR"

say -v Tingting -r 190 -f "$EDIT_DIR/voiceover.txt" -o "$OUT_DIR/voiceover.aiff"

ffmpeg -y \
  -f lavfi -i "color=c=0x4A0F1D:s=1080x1920:r=30:d=15" \
  -loop 1 -framerate 30 -i "$IMAGE" \
  -i "$OUT_DIR/voiceover.aiff" \
  -f lavfi -i "sine=frequency=220:sample_rate=48000:duration=15" \
  -f lavfi -i "sine=frequency=329.63:sample_rate=48000:duration=15" \
  -filter_complex "
    [1:v]scale=1080:-2,split=4[p1][p2][p3][p4];

    [p1]crop=1080:1440:0:0,
      zoompan=z='min(zoom+0.0007,1.06)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=90:s=1080x1440:fps=30,
      pad=1080:1920:0:240:color=0xF3F1F0,
      drawbox=x=54:y=112:w=972:h=142:color=0x4A0F1D@0.94:t=fill,
      drawtext=fontfile='$FONT':textfile='$EDIT_DIR/line1.txt':fontcolor=0xFFF9F0:fontsize=52:x=(w-text_w)/2:y=154,
      drawtext=fontfile='$FONT':text='COALIEA & HAEFLI':fontcolor=0xB99052:fontsize=25:x=(w-text_w)/2:y=1770,
      fade=t=in:st=0:d=0.25,fade=t=out:st=2.72:d=0.28,setpts=PTS-STARTPTS[v1];

    [p2]crop=904:1606:151:0,
      zoompan=z='min(zoom+0.00055,1.05)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)+40':d=120:s=1080x1920:fps=30,
      drawbox=x=60:y=1478:w=960:h=174:color=0x26080F@0.78:t=fill,
      drawtext=fontfile='$FONT':textfile='$EDIT_DIR/line2.txt':fontcolor=white:fontsize=58:x=(w-text_w)/2:y=1534,
      fade=t=in:st=0:d=0.25,fade=t=out:st=3.72:d=0.28,setpts=PTS-STARTPTS[v2];

    [p3]crop=720:1280:95:250,
      zoompan=z='1.04-min(on,120)*0.0003':x='iw*0.38-(iw/zoom/2)':y='ih*0.42-(ih/zoom/2)':d=120:s=1080x1920:fps=30,
      drawbox=x=60:y=126:w=960:h=164:color=0xF7F1EA@0.90:t=fill,
      drawtext=fontfile='$FONT':textfile='$EDIT_DIR/line3.txt':fontcolor=0x561424:fontsize=54:x=(w-text_w)/2:y=179,
      fade=t=in:st=0:d=0.25,fade=t=out:st=3.72:d=0.28,setpts=PTS-STARTPTS[v3];

    [p4]crop=1080:1440:0:0,
      zoompan=z='1.035-min(on,120)*0.0002':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=120:s=1080x1440:fps=30,
      pad=1080:1920:0:240:color=0x4A0F1D,
      drawbox=x=0:y=0:w=1080:h=272:color=0x4A0F1D:t=fill,
      drawbox=x=0:y=1680:w=1080:h=240:color=0x4A0F1D:t=fill,
      drawtext=fontfile='$FONT':textfile='$EDIT_DIR/line4a.txt':fontcolor=0xFFF9F0:fontsize=66:x=(w-text_w)/2:y=88,
      drawtext=fontfile='$FONT':textfile='$EDIT_DIR/line4b.txt':fontcolor=0xD9B66F:fontsize=48:x=(w-text_w)/2:y=180,
      drawtext=fontfile='$FONT':text='COALIEA & HAEFLI':fontcolor=0xFFF9F0:fontsize=29:x=(w-text_w)/2:y=1775,
      fade=t=in:st=0:d=0.25,fade=t=out:st=3.72:d=0.28,setpts=PTS-STARTPTS[v4];

    [v1][v2][v3][v4]concat=n=4:v=1:a=0[video];
    [3:a]volume=0.018,afade=t=in:st=0:d=1.2,afade=t=out:st=13.5:d=1.5[m1];
    [4:a]volume=0.012,afade=t=in:st=0:d=1.2,afade=t=out:st=13.5:d=1.5[m2];
    [m1][m2]amix=inputs=2:normalize=0[bed];
    [2:a]volume=1.35,adelay=250|250,apad=pad_dur=15[voice];
    [bed][voice]amix=inputs=2:duration=first:normalize=0,alimiter=limit=0.92[audio]
  " \
  -map "[video]" -map "[audio]" \
  -t 15 -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p \
  -c:a aac -b:a 192k -movflags +faststart \
  "$OUT_DIR/wedding-mother-bag-ad-15s.mp4"

ffmpeg -y -ss 00:00:05.5 -i "$OUT_DIR/wedding-mother-bag-ad-15s.mp4" -frames:v 1 "$OUT_DIR/preview-05.5s.png"
ffmpeg -y -ss 00:00:09.5 -i "$OUT_DIR/wedding-mother-bag-ad-15s.mp4" -frames:v 1 "$OUT_DIR/preview-09.5s.png"
ffmpeg -y -ss 00:00:13.5 -i "$OUT_DIR/wedding-mother-bag-ad-15s.mp4" -frames:v 1 "$OUT_DIR/preview-13.5s.png"

ffprobe -v error -show_entries format=duration:stream=codec_name,width,height,r_frame_rate -of json "$OUT_DIR/wedding-mother-bag-ad-15s.mp4"
