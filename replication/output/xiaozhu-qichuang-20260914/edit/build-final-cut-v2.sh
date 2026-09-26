#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INPUT="${1:-$ROOT/edit/xiaozhu-final-cut-input.mp4}"
OUTPUT="${2:-$ROOT/edit/xiaozhu-final-cut-v2.mp4}"
SFX="$ROOT/assets/sfx"

[[ -f "$INPUT" ]] || { echo "missing input: $INPUT" >&2; exit 1; }
for asset in \
  music-soft-piano-acoustic-guitar-id744879.mp3 \
  clock-tick-id367495.mp3 \
  blanket-rustle-id493264.mp3 \
  dishes-id193060.mp3 \
  roomtone-id761024.mp3 \
  water-drop-id792932.mp3; do
  [[ -f "$SFX/$asset" ]] || { echo "missing audio asset: $SFX/$asset" >&2; exit 1; }
done

mkdir -p "$(dirname "$OUTPUT")"

# The first 0.7 seconds borrow a warm memory image from S05. The present-day
# shot then lands in near silence before the full memory begins at 5.05s.
ffmpeg -hide_banner -y \
  -i "$INPUT" \
  -i "$SFX/music-soft-piano-acoustic-guitar-id744879.mp3" \
  -i "$SFX/clock-tick-id367495.mp3" \
  -i "$SFX/blanket-rustle-id493264.mp3" \
  -i "$SFX/dishes-id193060.mp3" \
  -i "$SFX/roomtone-id761024.mp3" \
  -i "$SFX/water-drop-id792932.mp3" \
  -filter_complex '
    [0:v]split=3[v0][v1][v2];
    [v0]trim=start=22.55:end=23.25,setpts=PTS-STARTPTS[vflash];
    [v1]trim=start=0.40:end=4.75,setpts=PTS-STARTPTS[vcold];
    [v2]trim=start=5.207031:end=52.567166,setpts=PTS-STARTPTS[vrest];
    [vflash][vcold][vrest]concat=n=3:v=1:a=0,
      crop=1344:756:0:6,scale=1920:1080:flags=lanczos,
      fps=24,format=yuv420p[vout];

    anullsrc=r=44100:cl=stereo:d=0.70[asilence];
    [0:a]asplit=2[a0][a1];
    [a0]atrim=start=0.40:end=4.75,asetpts=PTS-STARTPTS[acold];
    [a1]atrim=start=5.207031:end=52.567166,asetpts=PTS-STARTPTS[arest];
    [asilence][acold][arest]concat=n=3:v=0:a=1[abase];

    [1:a]asplit=3[m0][m1][m2];
    [m0]atrim=start=0:end=0.70,asetpts=PTS-STARTPTS,
      volume=-8dB,afade=t=out:st=0.48:d=0.22[mflash];
    [m1]atrim=start=0:end=38.40,asetpts=PTS-STARTPTS,
      volume=-14dB,afade=t=in:st=0:d=0.55,
      afade=t=out:st=37.70:d=0.70,adelay=5050|5050[mmemory];
    [m2]atrim=start=0:end=1.40,asetpts=PTS-STARTPTS,
      volume=-18dB,afade=t=out:st=0.95:d=0.45,
      adelay=49200|49200[mphone];

    [2:a]asplit=2[c0][c1];
    [c0]atrim=start=0:end=4.35,asetpts=PTS-STARTPTS,
      volume=-18dB,adelay=700|700[clockopen];
    [c1]atrim=start=0:end=8.96,asetpts=PTS-STARTPTS,
      volume=-18dB,adelay=43450|43450[clockclose];

    [5:a]asplit=2[r0][r1];
    [r0]atrim=start=0:end=4.35,asetpts=PTS-STARTPTS,
      volume=6dB,afade=t=in:st=0:d=0.20,adelay=700|700[roomopen];
    [r1]atrim=start=0:end=8.96,asetpts=PTS-STARTPTS,
      volume=6dB,afade=t=in:st=0:d=0.20,adelay=43450|43450[roomclose];

    [3:a]asplit=3[b0][b1][b2];
    [b0]atrim=start=0:end=0.70,asetpts=PTS-STARTPTS,
      volume=7dB,afade=t=out:st=0.50:d=0.20[blanketflash];
    [b1]atrim=start=0:end=1.20,asetpts=PTS-STARTPTS,
      volume=8dB,adelay=4850|4850[blankettransition];
    [b2]atrim=start=0:end=1.25,asetpts=PTS-STARTPTS,
      volume=7dB,adelay=21950|21950[blanketfall];

    [4:a]atrim=start=0:end=1.10,asetpts=PTS-STARTPTS,
      volume=-15dB,adelay=44750|44750[dish];

    [6:a]asplit=3[d0][d1][d2];
    [d0]volume=-18dB,adelay=2800|2800[dropopen];
    [d1]volume=-18dB,adelay=46500|46500[dropclose1];
    [d2]volume=-20dB,adelay=51200|51200[dropclose2];

    [abase][mflash][mmemory][mphone]
      [clockopen][clockclose][roomopen][roomclose]
      [blanketflash][blankettransition][blanketfall]
      [dish][dropopen][dropclose1][dropclose2]
      amix=inputs=15:duration=first:dropout_transition=0,
      loudnorm=I=-16:TP=-1.0:LRA=11,
      aresample=44100:async=1:first_pts=0,asetpts=N/SR/TB[aout]
  ' \
  -map '[vout]' -map '[aout]' \
  -c:v libx264 -preset slow -crf 18 -profile:v high -level 4.1 \
  -c:a aac -b:a 256k -ar 44100 -ac 2 \
  -movflags +faststart -shortest "$OUTPUT"

echo "saved: $OUTPUT"
