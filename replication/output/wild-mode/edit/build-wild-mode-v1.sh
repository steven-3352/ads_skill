#!/usr/bin/env bash
set -Eeuo pipefail

THEME_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VIDEOS="$THEME_DIR/videos"
KEYFRAMES="$THEME_DIR/keyframes"
FINAL="$THEME_DIR/final"
AUDIO="$THEME_DIR/audio/source-bgm.wav"

mkdir -p "$FINAL"

ffmpeg -y \
  -i "$VIDEOS/video-opening-room-v1-task.mp4" \
  -i "$VIDEOS/video-shoes-transform-v1-task.mp4" \
  -i "$VIDEOS/video-watch-transform-v1-task.mp4" \
  -i "$VIDEOS/video-glasses-transform-v1-task.mp4" \
  -i "$VIDEOS/video-belt-transform-v1-task.mp4" \
  -i "$VIDEOS/video-hat-transform-v1-task.mp4" \
  -i "$VIDEOS/video-final-exit-v1-task.mp4" \
  -loop 1 -framerate 30 -t 3 -i "$KEYFRAMES/kf-01-final-look-v2.png" \
  -i "$AUDIO" \
  -filter_complex "
    [0:v]trim=start=0:end=0.662,setpts=PTS-STARTPTS,fps=30,scale=720:1256:force_original_aspect_ratio=increase,crop=720:1256,setsar=1[v0];
    [1:v]trim=start=0.10:end=4.60,setpts=(PTS-STARTPTS)/1.929276,fps=30,scale=720:1256:force_original_aspect_ratio=increase,crop=720:1256,setsar=1[v1];
    [2:v]trim=start=0.10:end=4.50,setpts=(PTS-STARTPTS)/2.339181,fps=30,scale=720:1256:force_original_aspect_ratio=increase,crop=720:1256,setsar=1[v2];
    [3:v]trim=start=0.10:end=4.50,setpts=(PTS-STARTPTS)/2.354200,fps=30,scale=720:1256:force_original_aspect_ratio=increase,crop=720:1256,setsar=1[v3];
    [4:v]trim=start=0.10:end=4.50,setpts=(PTS-STARTPTS)/2.339181,fps=30,scale=720:1256:force_original_aspect_ratio=increase,crop=720:1256,setsar=1[v4];
    [5:v]trim=start=0.10:end=4.50,setpts=(PTS-STARTPTS)/2.354200,fps=30,scale=720:1256:force_original_aspect_ratio=increase,crop=720:1256,setsar=1[v5];
    [7:v]split=5[hero1][hero2][hero3][hero4][hero5];
    [hero1]crop=560:977:245:560,scale=720:1256,zoompan=z='min(zoom+0.003,1.08)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1256:fps=30,trim=duration=0.476,setpts=PTS-STARTPTS[s1];
    [hero2]crop=430:750:520:430,scale=720:1256,zoompan=z='min(zoom+0.003,1.08)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1256:fps=30,trim=duration=0.465,setpts=PTS-STARTPTS[s2];
    [hero3]crop=520:907:250:420,scale=720:1256,zoompan=z='min(zoom+0.003,1.08)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1256:fps=30,trim=duration=0.476,setpts=PTS-STARTPTS[s3];
    [hero4]crop=480:837:285:40,scale=720:1256,zoompan=z='min(zoom+0.003,1.08)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1256:fps=30,trim=duration=0.464,setpts=PTS-STARTPTS[s4];
    [hero5]crop=881:1537:71:0,scale=720:1256,zoompan=z='min(zoom+0.0015,1.04)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1256:fps=30,trim=duration=0.465,setpts=PTS-STARTPTS[s5];
    [6:v]trim=start=0:end=3.00,setpts=(PTS-STARTPTS)/1.368613,fps=30,scale=720:1256:force_original_aspect_ratio=increase,crop=720:1256,setsar=1[v6];
    [v0][v1][v2][v3][v4][v5][s1][s2][s3][s4][s5][v6]concat=n=12:v=1:a=0,eq=contrast=1.035:saturation=1.07:brightness=0.005,unsharp=5:5:0.35:5:5:0,format=yuv420p[vout];
    [1:a]atrim=start=0.10:end=4.60,asetpts=PTS-STARTPTS,atempo=1.929276,highpass=f=300,volume=0.20,adelay=662:all=1[a1];
    [2:a]atrim=start=0.10:end=4.50,asetpts=PTS-STARTPTS,atempo=2.0,atempo=1.169590,highpass=f=300,volume=0.18,adelay=2995:all=1[a2];
    [3:a]atrim=start=0.10:end=4.50,asetpts=PTS-STARTPTS,atempo=2.0,atempo=1.177100,highpass=f=300,volume=0.18,adelay=4876:all=1[a3];
    [4:a]atrim=start=0.10:end=4.50,asetpts=PTS-STARTPTS,atempo=2.0,atempo=1.169590,highpass=f=300,volume=0.18,adelay=6745:all=1[a4];
    [5:a]atrim=start=0.10:end=4.50,asetpts=PTS-STARTPTS,atempo=2.0,atempo=1.177100,highpass=f=300,volume=0.18,adelay=8626:all=1[a5];
    [6:a]atrim=start=0:end=3.00,asetpts=PTS-STARTPTS,atempo=1.368613,highpass=f=250,volume=0.24,adelay=12841:all=1[a6];
    [8:a]atrim=start=0:end=15.033,asetpts=PTS-STARTPTS,apad=pad_dur=0.1,volume=0.94[bgm];
    [bgm][a1][a2][a3][a4][a5][a6]amix=inputs=7:duration=first:dropout_transition=0:normalize=0,alimiter=limit=0.95[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -t 15.033 -r 30 \
  -c:v libx264 -preset slow -crf 17 -profile:v high -pix_fmt yuv420p \
  -c:a aac -b:a 192k -ar 44100 \
  -movflags +faststart \
  "$FINAL/wild-mode-fast-cut-v1.mp4"
