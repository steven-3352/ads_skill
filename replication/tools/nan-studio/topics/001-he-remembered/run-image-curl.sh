#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$BASE_DIR/../../.." && pwd)"
if [[ -f "$PROJECT_DIR/.env" ]]; then
  set -a
  source "$PROJECT_DIR/.env"
  set +a
fi
PROMPTS_DIR="$BASE_DIR/prompts"
REFERENCES_FILE="$BASE_DIR/references.json"
API_BASE="${GPT_IMAGE_BASE_URL:-https://deepkey.top}"
API_BASE="${API_BASE%/}"
if [[ "$API_BASE" == */v1 ]]; then API_V1="$API_BASE"; else API_V1="$API_BASE/v1"; fi
API_KEY="${GPT_IMAGE_API_KEY:-}"
MODEL="${GPT_IMAGE_MODEL:-gpt-image-2}"
OUTPUT_DIR="${IMAGE_OUTPUT_DIR:-/home/ubuntu/tonbirds-studio/public/uploads/1/user_upload/image}"
PUBLIC_BASE="${PUBLIC_IMAGE_BASE:-https://www.tonbird.top/uploads/1/user_upload/image}"
SIZE="${GPT_IMAGE_SIZE:-1024x1536}"

usage() { echo "用法: $0 character|cover [输出文件名.png]" >&2; exit 2; }
die() { echo "错误: $*" >&2; exit 1; }
[[ $# -ge 1 && $# -le 2 ]] || usage
[[ -n "$API_KEY" ]] || die "请在 $PROJECT_DIR/.env 设置 GPT_IMAGE_API_KEY"
command -v curl >/dev/null || die "需要 curl"
command -v jq >/dev/null || die "需要 jq"
command -v base64 >/dev/null || die "需要 base64"

MODE="$1"
case "$MODE" in
  character) PROMPT_FILE="$PROMPTS_DIR/character.json"; DEFAULT_NAME="001-chen-yu-$(date +%s).png" ;;
  cover) PROMPT_FILE="$PROMPTS_DIR/cover.json"; DEFAULT_NAME="001-cover-$(date +%s).png" ;;
  *) usage ;;
esac
[[ -f "$PROMPT_FILE" ]] || die "找不到提示词: $PROMPT_FILE"

PROMPT="$(jq -er '.prompt' "$PROMPT_FILE")"
NAME="${2:-$DEFAULT_NAME}"
[[ "$NAME" == *.png ]] || NAME="$NAME.png"
[[ "$NAME" != */* ]] || die "输出文件名不能包含目录"
mkdir -p "$OUTPUT_DIR"

TEMP_DIR="$(mktemp -d)"
RESPONSE_FILE="$TEMP_DIR/response.json"
trap 'rm -rf "$TEMP_DIR"' EXIT

if [[ "$MODE" == character ]]; then
  jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --arg size "$SIZE" \
    '{model:$model,prompt:$prompt,size:$size,quality:"high",output_format:"png"}' \
    | curl --fail-with-body -sS -X POST "$API_V1/images/generations" \
        -H 'Content-Type: application/json; charset=utf-8' \
        -H "Authorization: Bearer $API_KEY" --data-binary @- > "$RESPONSE_FILE"
else
  mapfile -t REF_URLS < <(jq -er '.cover[]' "$REFERENCES_FILE")
  ((${#REF_URLS[@]} > 0)) || die "references.json 的 cover 至少需要一个公网参考图"
  CURL_ARGS=(--fail-with-body -sS -X POST "$API_V1/images/edits" -H "Authorization: Bearer $API_KEY" -F "model=$MODEL" -F "prompt=$PROMPT" -F "size=$SIZE" -F "quality=high" -F "output_format=png")
  for index in "${!REF_URLS[@]}"; do
    ref_file="$TEMP_DIR/reference-$index"
    curl --fail-with-body -sS -L "${REF_URLS[$index]}" -o "$ref_file"
    CURL_ARGS+=(-F "image[]=@$ref_file;filename=reference-$index.png;type=image/png")
  done
  curl "${CURL_ARGS[@]}" > "$RESPONSE_FILE"
fi

OUTPUT="$OUTPUT_DIR/$NAME"
B64="$(jq -r '.data[0].b64_json // empty' "$RESPONSE_FILE")"
URL="$(jq -r '.data[0].url // empty' "$RESPONSE_FILE")"
if [[ -n "$B64" ]]; then
  printf '%s' "$B64" | base64 --decode > "$OUTPUT"
elif [[ -n "$URL" ]]; then
  curl --fail-with-body -sS -L "$URL" -o "$OUTPUT"
else
  jq . "$RESPONSE_FILE" >&2
  die "图片接口未返回 data[0].b64_json 或 data[0].url"
fi

[[ -s "$OUTPUT" ]] || die "图片文件为空: $OUTPUT"
echo "本地文件: $OUTPUT"
echo "公网地址: $PUBLIC_BASE/$NAME"
