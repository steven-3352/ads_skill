#!/usr/bin/env bash
set -euo pipefail

FILE="${1:-}"
[[ -n "$FILE" && -f "$FILE" ]] || { echo "用法: $0 <prompt.json>" >&2; exit 2; }
PROMPT="$(node -e 'const fs=require("fs"); const d=JSON.parse(fs.readFileSync(process.argv[1],"utf8")); process.stdout.write(d.prompt || "")' "$FILE")"
[[ -n "$PROMPT" ]] || { echo "错误: prompt 为空: $FILE" >&2; exit 1; }

# These phrases directly induce forbidden inserts/close-ups and must be removed,
# even when a later negative prompt says not to emphasize the object or face.
BAD='camera looks at the umbrella|camera looks down at the umbrella|camera looks at the cup|camera looks down at the cup|directly in front of the camera|pushes the umbrella handle closer|pushes the cup closer|hand.?held close.?up|tight close.?up|face fills the frame|close view of his face|镜头看一眼伞|镜头看伞|镜头看杯子|放到镜头前|推近|手部近景|人脸特写|脸部特写'
if printf '%s' "$PROMPT" | rg -in "$BAD"; then
  echo "错误: 检测到会诱发商品/道具或人脸特写的冲突措辞: $FILE" >&2
  exit 1
fi
echo "硬约束检查通过: $FILE"
