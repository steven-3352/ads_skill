#!/usr/bin/env bash
set -euo pipefail

# Extract the final video frame into the public upload directory.

DEST_DIR="/home/ubuntu/tonbirds-studio/public/uploads/1/user_upload/image"
PUBLIC_BASE="https://www.tonbird.top/uploads/1/user_upload/image"

usage() {
  echo "用法: $0 <视频文件或包含视频的目录> [输出文件名.png]" >&2
  exit 2
}

[[ $# -ge 1 && $# -le 2 ]] || usage

INPUT="$1"
if [[ -d "$INPUT" ]]; then
  VIDEO=""
  while IFS= read -r -d '' candidate; do
    VIDEO="$candidate"
    break
  done < <(find "$INPUT" -maxdepth 1 -type f \( \
    -iname '*.mp4' -o -iname '*.mov' -o -iname '*.m4v' -o -iname '*.webm' -o -iname '*.avi' -o -iname '*.mkv' \
  \) -print0 | sort -z)
  [[ -n "$VIDEO" ]] || { echo "目录中没有找到支持的视频文件: $INPUT" >&2; exit 1; }
elif [[ -f "$INPUT" ]]; then
  VIDEO="$INPUT"
else
  echo "输入路径不存在: $INPUT" >&2
  exit 1
fi

command -v ffmpeg >/dev/null 2>&1 || {
  echo "未找到 ffmpeg，请先安装并确保 ffmpeg 在 PATH 中。" >&2
  exit 1
}

mkdir -p "$DEST_DIR"
NAME="${2:-$(date +%s)-last-frame.png}"
[[ "$NAME" == *.png ]] || NAME="${NAME}.png"
[[ "$NAME" != */* ]] || { echo "输出文件名不能包含目录分隔符: $NAME" >&2; exit 2; }
OUTPUT="$DEST_DIR/$NAME"

# -sseof seeks from the end; -update writes one PNG frame without a sequence suffix.
ffmpeg -hide_banner -loglevel error -sseof -0.1 -i "$VIDEO" \
  -frames:v 1 -fps_mode vfr -update 1 "$OUTPUT"

[[ -s "$OUTPUT" ]] || { echo "抽帧失败，未生成文件: $OUTPUT" >&2; exit 1; }

echo "视频: $VIDEO"
echo "本地文件: $OUTPUT"
echo "公网地址: $PUBLIC_BASE/$NAME"
