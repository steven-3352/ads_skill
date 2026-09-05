#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$BASE_DIR/../.." && pwd)"
ENV_FILE="$PROJECT_DIR/.env"
[[ -f "$ENV_FILE" ]] || { echo "找不到项目配置: $ENV_FILE" >&2; exit 1; }
set -a; source "$ENV_FILE"; set +a

PROMPT_FILE=""
OUTPUT_DIR="./generated-images"
OUTPUT_NAME="generated-$(date +%s).png"
CLI_REFERENCES=()

usage() {
  cat >&2 <<'USAGE'
用法:
  generate-image.sh --prompt <prompt.json> --output-dir <目录> [选项]

选项:
  --output-name <文件名.png>    输出文件名，默认 generated-时间戳.png
  --reference <图片路径>        参考图，可重复传入
  --model <模型>                默认读取 GPT_IMAGE_MODEL 或 gpt-image-2
  --size <宽x高>                默认读取 GPT_IMAGE_SIZE 或 1024x1536

兼容旧用法:
  generate-image.sh <prompt.json> [output.png] [reference-image ...]
USAGE
  exit 2
}

if [[ "${1:-}" != --* ]]; then
  PROMPT_FILE="${1:-}"
  if [[ -n "${2:-}" ]]; then OUTPUT_DIR="$(dirname "$2")"; OUTPUT_NAME="$(basename "$2")"; fi
  if [[ "$#" -gt 2 ]]; then CLI_REFERENCES=("${@:3}"); fi
else
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prompt) PROMPT_FILE="${2:-}"; shift 2 ;;
      --output-dir) OUTPUT_DIR="${2:-}"; shift 2 ;;
      --output-name) OUTPUT_NAME="${2:-}"; shift 2 ;;
      --reference) CLI_REFERENCES+=("${2:-}"); shift 2 ;;
      --model) GPT_IMAGE_MODEL="${2:-}"; shift 2 ;;
      --size) GPT_IMAGE_SIZE="${2:-}"; shift 2 ;;
      -h|--help) usage ;;
      *) echo "未知参数: $1" >&2; usage ;;
    esac
  done
fi

[[ -n "$PROMPT_FILE" && -f "$PROMPT_FILE" ]] || usage
OUTPUT="$OUTPUT_DIR/$OUTPUT_NAME"
[[ -n "${GPT_IMAGE_API_KEY:-}" ]] || { echo "缺少 GPT_IMAGE_API_KEY" >&2; exit 1; }
command -v jq >/dev/null || { echo "需要 jq" >&2; exit 1; }
command -v curl >/dev/null || { echo "需要 curl" >&2; exit 1; }
command -v base64 >/dev/null || { echo "需要 base64" >&2; exit 1; }

BASE_URL="${GPT_IMAGE_BASE_URL:-https://api.openai.com/v1}"
BASE_URL="${BASE_URL%/}"
[[ "$BASE_URL" == */v1 ]] || BASE_URL="$BASE_URL/v1"
MODEL="${GPT_IMAGE_MODEL:-gpt-image-2}"
SIZE="${GPT_IMAGE_SIZE:-1024x1536}"
PROMPT="$(jq -er '.prompt' "$PROMPT_FILE")"
if [[ "${#CLI_REFERENCES[@]}" -gt 0 ]]; then
  REFERENCES="$(printf '%s\n' "${CLI_REFERENCES[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')"
else
  REFERENCES="$(jq -c '.references // []' "$PROMPT_FILE")"
fi
mkdir -p "$(dirname "$OUTPUT")"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
RESPONSE="$TEMP_DIR/response.json"
if [[ "$REFERENCES" != "[]" ]]; then
  CURL_ARGS=(--fail-with-body -sS -X POST "$BASE_URL/images/edits"
    -H "Authorization: Bearer $GPT_IMAGE_API_KEY"
    -F "model=$MODEL" -F "prompt=$PROMPT" -F "size=$SIZE"
    -F 'quality=high' -F 'output_format=png')
  while IFS= read -r reference; do
    [[ -n "$reference" ]] || continue
    if [[ "$reference" != /* && ! -f "$reference" ]]; then reference="$PROJECT_DIR/$reference"; fi
    [[ -f "$reference" ]] || { echo "找不到参考图: $reference" >&2; exit 1; }
    CURL_ARGS+=( -F "image[]=@$reference" )
  done < <(jq -r '.[]' <<< "$REFERENCES")
  curl "${CURL_ARGS[@]}" > "$RESPONSE"
else
  jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --arg size "$SIZE" \
    '{model:$model,prompt:$prompt,size:$size,quality:"high",output_format:"png"}' \
    | curl --fail-with-body -sS -X POST "$BASE_URL/images/generations" \
        -H 'Content-Type: application/json' \
        -H "Authorization: Bearer $GPT_IMAGE_API_KEY" \
        --data-binary @- > "$RESPONSE"
fi

B64="$(jq -r '.data[0].b64_json // empty' "$RESPONSE")"
URL="$(jq -r '.data[0].url // empty' "$RESPONSE")"
if [[ -n "$B64" ]]; then
  printf '%s' "$B64" | base64 --decode > "$OUTPUT"
elif [[ -n "$URL" ]]; then
  curl --fail-with-body -sS -L "$URL" -o "$OUTPUT"
else
  jq . "$RESPONSE" >&2
  echo "图片接口未返回图片数据" >&2
  exit 1
fi
[[ -s "$OUTPUT" ]] || { echo "图片文件为空: $OUTPUT" >&2; exit 1; }
echo "图片已保存: $OUTPUT"
