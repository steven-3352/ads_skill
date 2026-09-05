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
    [hero1]crop=560:977:245:560,scale=720:1256,zoompan=z='min(zoom+0.004,1.06)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1256:fps=30,trim=duration=0.26,setpts=PTS-STARTPTS,fade=t=in:st=0:d=0.045:color=white[s1];
    [hero2]crop=430:750:520:430,scale=720:1256,zoompan=z='min(zoom+0.004,1.06)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1256:fps=30,trim=duration=0.26,setpts=PTS-STARTPTS,fade=t=in:st=0:d=0.045:color=white[s2];
    [hero3]crop=520:907:250:420,scale=720:1256,zoompan=z='min(zoom+0.004,1.06)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1256:fps=30,trim=duration=0.26,setpts=PTS-STARTPTS,fade=t=in:st=0:d=0.045:color=white[s3];
    [hero4]crop=480:837:285:40,scale=720:1256,zoompan=z='min(zoom+0.003,1.05)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1256:fps=30,trim=duration=0.26,setpts=PTS-STARTPTS,fade=t=in:st=0:d=0.045:color=white[s4];
    [hero5]crop=881:1537:71:0,scale=720:1256,zoompan=z='min(zoom+0.0012,1.035)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1256:fps=30,trim=duration=1.25,setpts=PTS-STARTPTS,
      drawbox=x=0:y='min(h-30,max(0,(t/1.25)*h-30))':w=iw:h=30:color=0x51c8ff@0.13:t=fill,
      drawbox=x=0:y='min(h-4,max(0,(t/1.25)*h-4))':w=iw:h=4:color=0x8de7ff@0.78:t=fill,
      drawbox=x=30:y=38:w=75:h=3:color=0x75dfff@0.62:t=fill,
      drawbox=x=30:y=38:w=3:h=75:color=0x75dfff@0.62:t=fill,
      drawbox=x=w-105:y=38:w=75:h=3:color=0x75dfff@0.62:t=fill,
      drawbox=x=w-33:y=38:w=3:h=75:color=0x75dfff@0.62:t=fill,
      drawbox=x=30:y=h-41:w=75:h=3:color=0x75dfff@0.62:t=fill,
      drawbox=x=30:y=h-113:w=3:h=75:color=0x75dfff@0.62:t=fill,
      drawbox=x=w-105:y=h-41:w=75:h=3:color=0x75dfff@0.62:t=fill,
      drawbox=x=w-33:y=h-113:w=3:h=75:color=0x75dfff@0.62:t=fill[hero_full];

    [6:v]trim=start=0:end=1.916,setpts=(PTS-STARTPTS)/1.368571,fps=30,scale=900:1570:force_original_aspect_ratio=increase,crop=720:1256:(iw-ow)/2:40,setsar=1[exit];
    [6:v]trim=start=1.916:end=1.950,setpts=PTS-STARTPTS,fps=30,scale=900:1570:force_original_aspect_ratio=increase,crop=720:1256:(iw-ow)/2:40,setsar=1,tpad=stop_mode=clone:stop_duration=0.804[exit_hold];
    color=c=black:s=720x1256:r=30:d=0.55[black];
    [exit_hold][black]xfade=transition=circleclose:duration=0.55:offset=0.288[close];

    [v0][v1][v2][v3][v4][v5][s1][s2][s3][s4][hero_full][exit][close]concat=n=13:v=1:a=0,
      eq=contrast=1.045:saturation=1.10:brightness=0.008,
      colorbalance=bs=0.012:rs=0.010,
      unsharp=5:5:0.38:5:5:0,
      vignette=PI/14,
      noise=alls=1.2:allf=t,
      format=yuv420p[vout];

    [1:a]atrim=start=0.10:end=4.60,asetpts=PTS-STARTPTS,atempo=1.929276,highpass=f=300,volume=0.20,adelay=662:all=1[a1];
    [2:a]atrim=start=0.10:end=4.50,asetpts=PTS-STARTPTS,atempo=2.0,atempo=1.169590,highpass=f=300,volume=0.18,adelay=2995:all=1[a2];
    [3:a]atrim=start=0.10:end=4.50,asetpts=PTS-STARTPTS,atempo=2.0,atempo=1.177100,highpass=f=300,volume=0.18,adelay=4876:all=1[a3];
    [4:a]atrim=start=0.10:end=4.50,asetpts=PTS-STARTPTS,atempo=2.0,atempo=1.169590,highpass=f=300,volume=0.18,adelay=6745:all=1[a4];
    [5:a]atrim=start=0.10:end=4.50,asetpts=PTS-STARTPTS,atempo=2.0,atempo=1.177100,highpass=f=300,volume=0.18,adelay=8626:all=1[a5];
    [6:a]atrim=start=0:end=1.916,asetpts=PTS-STARTPTS,atempo=1.368571,highpass=f=250,volume=0.21,adelay=12785:all=1[a6];
    anoisesrc=color=pink:duration=1.25:amplitude=0.055:sample_rate=44100,highpass=f=1300,lowpass=f=5200,afade=t=in:st=0:d=0.22,afade=t=out:st=0.78:d=0.47,adelay=11535:all=1[scan];
    sine=frequency=105:duration=0.22:sample_rate=44100,afade=t=out:st=0.025:d=0.195,volume=0.34,adelay=14390:all=1[lock_low];
    sine=frequency=840:duration=0.09:sample_rate=44100,afade=t=out:st=0.008:d=0.082,volume=0.15,adelay=14390:all=1[lock_hi];
    [8:a]atrim=start=0:end=15.033,asetpts=PTS-STARTPTS,apad=pad_dur=0.1,volume=0.92[bgm];
    [bgm][a1][a2][a3][a4][a5][a6][scan][lock_low][lock_hi]amix=inputs=10:duration=first:dropout_transition=0:normalize=0,alimiter=limit=0.94[aout]
  " \
  -map "[vout]" -map "[aout]" \
  -t 15.033 -r 30 \
  -c:v libx264 -preset slow -crf 17 -profile:v high -pix_fmt yuv420p \
  -c:a aac -b:a 192k -ar 44100 \
  -movflags +faststart \
  "$FINAL/wild-mode-fast-cut-v2.mp4"
