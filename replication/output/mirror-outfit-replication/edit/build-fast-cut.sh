#!/usr/bin/env bash
set -Eeuo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_DIR="$(cd "$THEME_DIR/../../.." && pwd)"
VIDEO_DIR="$THEME_DIR/videos"
IMAGE_DIR="$THEME_DIR/images"
FINAL_DIR="$THEME_DIR/final"
SOURCE_VIDEO="/Users/wmzuo/Downloads/ad/v0300fg10000d90n1qnog65gud4n88ag.MP4"
OUTPUT="$FINAL_DIR/mirror-outfit-fast-cut-v1.mp4"

command -v ffmpeg >/dev/null || { echo "需要 ffmpeg" >&2; exit 1; }
[[ -f "$SOURCE_VIDEO" ]] || { echo "找不到原片音乐来源: $SOURCE_VIDEO" >&2; exit 1; }

mkdir -p "$FINAL_DIR"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

video_clip() {
  local input="$1" start="$2" duration="$3" speed="$4" output="$5"
  ffmpeg -loglevel error -y -ss "$start" -t "$duration" -i "$input" -an \
    -vf "setpts=PTS/$speed,scale=-2:1280,crop=720:1280:(in_w-720)/2:0,setsar=1,fps=30,format=yuv420p" \
    -c:v libx264 -preset medium -crf 18 -movflags +faststart "$output"
}

photo_push() {
  local input="$1" duration="$2" output="$3"
  ffmpeg -loglevel error -y -framerate 30 -loop 1 -t "$duration" -i "$input" -an \
    -vf "scale=960:1440:force_original_aspect_ratio=increase,crop=960:1440,zoompan=z='min(zoom+0.003,1.06)':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1280:fps=30,format=yuv420p" \
    -c:v libx264 -preset medium -crf 18 -movflags +faststart "$output"
}

photo_pull() {
  local input="$1" duration="$2" output="$3"
  ffmpeg -loglevel error -y -framerate 30 -loop 1 -t "$duration" -i "$input" -an \
    -vf "scale=960:1440:force_original_aspect_ratio=increase,crop=960:1440,zoompan=z='if(eq(on,0),1.06,max(1.0,zoom-0.003))':x='iw/2-(iw/zoom/2)':y='ih/2-(ih/zoom/2)':d=1:s=720x1280:fps=30,format=yuv420p" \
    -c:v libx264 -preset medium -crf 18 -movflags +faststart "$output"
}

flash_clip() {
  local output="$1"
  ffmpeg -loglevel error -y -f lavfi -i "color=c=white:s=720x1280:r=30:d=0.10" -an \
    -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p "$output"
}

# Opening: wake-up action immediately, then the phone selector fills the frame.
video_clip "$VIDEO_DIR/71730363b7524f1eadf6eb3c2af88745.mp4" 0.25 2.90 1.80 "$WORK_DIR/001-intro.mp4"
video_clip "$VIDEO_DIR/video-02-task.mp4" 0.35 2.35 1.70 "$WORK_DIR/002-phone-a.mp4"
flash_clip "$WORK_DIR/003-flash.mp4"

# Black look: one clear action plus two fast outdoor result stills.
video_clip "$VIDEO_DIR/no-mirror-video-03-05-combined-task.mp4" 0.00 2.75 1.70 "$WORK_DIR/004-black-video.mp4"
photo_push "$IMAGE_DIR/outdoor-black-01-full.png" 0.36 "$WORK_DIR/005-black-full.mp4"
photo_pull "$IMAGE_DIR/outdoor-black-02-detail.png" 0.30 "$WORK_DIR/006-black-detail.mp4"
video_clip "$VIDEO_DIR/video-02-task.mp4" 2.25 1.15 1.65 "$WORK_DIR/007-phone-b.mp4"
flash_clip "$WORK_DIR/008-flash.mp4"

# White look: remove the long static hold and retain the sleeve action.
video_clip "$VIDEO_DIR/no-mirror-video-03-05-combined-task.mp4" 4.15 2.70 1.85 "$WORK_DIR/009-white-video.mp4"
photo_push "$IMAGE_DIR/outdoor-white-01-full.png" 0.36 "$WORK_DIR/010-white-full.mp4"
photo_pull "$IMAGE_DIR/outdoor-white-02-detail.png" 0.30 "$WORK_DIR/011-white-detail.mp4"
video_clip "$VIDEO_DIR/video-02-task.mp4" 3.30 1.25 1.70 "$WORK_DIR/012-phone-c.mp4"
flash_clip "$WORK_DIR/013-flash.mp4"

# Navy final look and a short exit payoff.
video_clip "$VIDEO_DIR/no-mirror-video-03-05-combined-task.mp4" 10.00 2.75 1.70 "$WORK_DIR/014-navy-video.mp4"
photo_push "$IMAGE_DIR/outdoor-navy-01-full.png" 0.42 "$WORK_DIR/015-navy-full.mp4"
photo_pull "$IMAGE_DIR/outdoor-navy-02-detail.png" 0.52 "$WORK_DIR/016-navy-detail.mp4"
video_clip "$VIDEO_DIR/no-mirror-video-06-task.mp4" 4.15 3.20 1.60 "$WORK_DIR/017-exit.mp4"

CONCAT_LIST="$WORK_DIR/concat.txt"
for clip in "$WORK_DIR"/[0-9][0-9][0-9]-*.mp4; do
  printf "file '%s'\n" "$clip" >> "$CONCAT_LIST"
done

ffmpeg -loglevel error -y -f concat -safe 0 -i "$CONCAT_LIST" -c copy "$WORK_DIR/visual.mp4"

# The original soundtrack is used only as a rhythm reference for this replication draft.
ffmpeg -loglevel error -y -i "$WORK_DIR/visual.mp4" -stream_loop -1 -i "$SOURCE_VIDEO" \
  -map 0:v:0 -map 1:a:0 -c:v copy -c:a aac -b:a 192k \
  -af "volume=0.9,afade=t=in:st=0:d=0.12" -shortest -movflags +faststart "$OUTPUT"

echo "快节奏剪辑样片已生成: $OUTPUT"
