#!/usr/bin/env bash
set -euo pipefail

# Generate a character or cover image from the topic prompt using curl.

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$BASE_DIR/prompts"
ENDPOINT="${DEEPKEY_IMAGE_API_URL:-https://deepkey.top/v1/images/generations}"
MODEL="${DEEPKEY_IMAGE_MODEL:-gpt-image-2}"
OUTPUT_DIR="${IMAGE_OUTPUT_DIR:-/home/ubuntu/tonbirds-studio/public/uploads/1/user_upload/image}"
PUBLIC_BASE="${PUBLIC_IMAGE_BASE:-https://www.tonbird.top/uploads/1/user_upload/image}"

usage() { echo "用法: $0 character|cover [输出文件名.png]" >&2; exit 2; }
[[ $# -ge 1 && $# -le 2 ]] || usage
[[ -n "${DEEPKEY_API_KEY:-}" ]] || { echo "请先设置 DEEPKEY_API_KEY" >&2; exit 1; }
command -v curl >/dev/null || { echo "需要 curl" >&2; exit 1; }
command -v jq >/dev/null || { echo "需要 jq" >&2; exit 1; }
command -v base64 >/dev/null || { echo "需要 base64" >&2; exit 1; }

case "$1" in
  character) PROMPT_FILE="$PROMPTS_DIR/character.json"; DEFAULT_NAME="chen-yu-master-$(date +%s).png"; SIZE="1024x1536" ;;
  cover) PROMPT_FILE="$PROMPTS_DIR/cover.json"; DEFAULT_NAME="episode-001-cover-$(date +%s).png"; SIZE="1024x1536" ;;
  *) usage ;;
esac

[[ -f "$PROMPT_FILE" ]] || { echo "找不到提示词文件: $PROMPT_FILE" >&2; exit 1; }
GLOBAL_VISUAL_CONSTRAINT='HUMAN-FIRST COMPOSITION: The face, direct eye contact, micro-expressions and relationship atmosphere must remain the visual focus. Every prop is only a small unbranded story detail and should occupy less than about 10 percent of the frame. No product-focused framing, prop close-up, centered product, package display, readable label, brand, price, feature demonstration or commercial lighting.'
PROMPT="$(jq -er '.prompt' "$PROMPT_FILE") $GLOBAL_VISUAL_CONSTRAINT"
NAME="${2:-$DEFAULT_NAME}"
[[ "$NAME" == *.png ]] || NAME="$NAME.png"
[[ "$NAME" != */* ]] || { echo "输出文件名不能包含目录分隔符" >&2; exit 2; }
mkdir -p "$OUTPUT_DIR"
RESPONSE_FILE="$(mktemp)"
trap 'rm -f "$RESPONSE_FILE"' EXIT

jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --arg size "$SIZE" \
  '{model:$model,prompt:$prompt,size:$size,quality:"high",output_format:"png"}' \
  | curl -fsS -X POST "$ENDPOINT" \
      -H 'Content-Type: application/json; charset=utf-8' \
      -H "Authorization: Bearer ${DEEPKEY_API_KEY}" \
      --data-binary @- > "$RESPONSE_FILE"

OUTPUT="$OUTPUT_DIR/$NAME"
B64="$(jq -r '.data[0].b64_json // empty' "$RESPONSE_FILE")"
URL="$(jq -r '.data[0].url // empty' "$RESPONSE_FILE")"
if [[ -n "$B64" ]]; then
  printf '%s' "$B64" | base64 --decode > "$OUTPUT"
elif [[ -n "$URL" ]]; then
  curl -fsS -L "$URL" -o "$OUTPUT"
else
  echo "接口响应中没有 data[0].b64_json 或 data[0].url:" >&2
  jq . "$RESPONSE_FILE" >&2
  exit 1
fi

[[ -s "$OUTPUT" ]] || { echo "图片保存失败: $OUTPUT" >&2; exit 1; }
echo "本地文件: $OUTPUT"
echo "公网地址: $PUBLIC_BASE/$NAME"
