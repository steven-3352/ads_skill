#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$BASE_DIR/../.." && pwd)"
ENV_FILE="/home/ubuntu/ads_skill/.env"
[[ -f "$ENV_FILE" ]] || { echo "missing env: $ENV_FILE" >&2; exit 1; }
set -a
source "$ENV_FILE"
set +a

PROMPT_FILE=""
OUTPUT_DIR="./generated-images"
OUTPUT_NAME="generated-$(date +%s).png"
CLI_REFERENCES=()
AUDIT_DIR=""
REQUEST_ID=""

usage() {
  cat >&2 <<'USAGE'
Usage:
  generate-image.sh --prompt <prompt.json> --output-dir <dir> [options]
Options:
  --output-name <file.png>
  --reference <image>        Repeatable; overrides references in JSON.
  --model <model>
  --size <widthxheight>
  --audit-dir <dir>          Persist request/response lifecycle evidence.
  --request-id <id>          Idempotency key for one paid request.
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
      --audit-dir) AUDIT_DIR="${2:-}"; shift 2 ;;
      --request-id) REQUEST_ID="${2:-}"; shift 2 ;;
      -h|--help) usage ;;
      *) echo "unknown option: $1" >&2; usage ;;
    esac
  done
fi

[[ -n "$PROMPT_FILE" && -f "$PROMPT_FILE" ]] || usage
"$BASE_DIR/validate-seedance-prompt-review.sh" "$PROMPT_FILE" image
OUTPUT="$OUTPUT_DIR/$OUTPUT_NAME"
[[ ! -e "$OUTPUT" ]] || { echo "refusing to overwrite existing output: $OUTPUT" >&2; exit 1; }
if [[ -n "$AUDIT_DIR" || -n "$REQUEST_ID" ]]; then
  [[ -n "$AUDIT_DIR" && -n "$REQUEST_ID" ]] || { echo "audit-dir and request-id must be used together" >&2; exit 2; }
  mkdir -p "$AUDIT_DIR"
fi
[[ -n "${GPT_IMAGE_API_KEY:-}" ]] || { echo "missing GPT_IMAGE_API_KEY" >&2; exit 1; }
command -v jq >/dev/null || { echo "jq is required" >&2; exit 1; }
command -v curl >/dev/null || { echo "curl is required" >&2; exit 1; }
command -v base64 >/dev/null || { echo "base64 is required" >&2; exit 1; }

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

# 生成门禁（不可绕过）：静物/插入镜的"肖像磁吸"。
# images/edits(图生图)端点会过度保留参考图构图——给插入/静物镜喂人物参考，
# 输出会被拽成肖像脸(实测：咖啡杯→挡风玻璃、道具→开车的女人、手部插入→人脸)。
# 规则：判定为插入/静物镜时禁止携带任何参考图，必须走文生图(images/generations)。
if [[ "$REFERENCES" != "[]" ]]; then
  PROMPT_LC="$(printf '%s' "$PROMPT" | tr '[:upper:]' '[:lower:]')"
  INSERT_HITS=0
  for kw in "tight insert" "still-life" "still life" "insert shot" "macro close-up" \
            "macro product" "fills the frame" "面部不入画" "no human face" \
            "not a portrait" "not a wide" "填满画面"; do
    [[ "$PROMPT_LC" == *"$kw"* ]] && INSERT_HITS=$((INSERT_HITS + 1))
  done
  if [[ "$INSERT_HITS" -ge 2 ]]; then
    # 可审计豁免：人工验收过的"物体锚定插入镜"(被一张紧物体参考主导、成片正确)可在
    # 提示词 JSON 里显式写 "insert_ref_verified": true 放行。默认(缺省/false)仍硬拦。
    INSERT_ACK="$(jq -r '.insert_ref_verified // false' "$PROMPT_FILE" 2>/dev/null || echo false)"
    if [[ "$INSERT_ACK" != "true" ]]; then
      REF_N="$(jq 'length' <<< "$REFERENCES")"
      echo "生成门禁拦截：检测到插入/静物镜特征(命中 $INSERT_HITS 项关键词)但携带 $REF_N 张参考图。" >&2
      echo "images/edits 会'肖像磁吸'导致主体走形。插入/静物镜默认必须文生图：去掉 --reference 且 JSON .references 置空。" >&2
      echo "若确为已验收的物体锚定插入镜，在提示词 JSON 加 \"insert_ref_verified\": true 显式豁免(可审计)。" >&2
      exit 4
    fi
  fi
fi
mkdir -p "$(dirname "$OUTPUT")"

TEMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TEMP_DIR"' EXIT
RESPONSE="${AUDIT_DIR:-$TEMP_DIR}/response.json"

write_lifecycle() {
  [[ -n "$AUDIT_DIR" ]] || return 0
  local state="$1"
  local detail="${2:-}"
  local tmp
  tmp="$(mktemp "$AUDIT_DIR/.lifecycle.XXXXXX")"
  jq -n --arg id "$REQUEST_ID" --arg state "$state" --arg at "$(date -Is)" --arg detail "$detail" \
    '{request_id:$id,state:$state,at:$at,detail:$detail,automatic_retry:false}' > "$tmp"
  mv "$tmp" "$AUDIT_DIR/lifecycle.json"
}

if [[ -n "$AUDIT_DIR" ]]; then
  [[ ! -e "$AUDIT_DIR/submission.locked" ]] || { echo "request id already used: $REQUEST_ID" >&2; exit 1; }
  cp "$PROMPT_FILE" "$AUDIT_DIR/source-prompt.json"
  jq -n --arg id "$REQUEST_ID" --arg prompt "$PROMPT_FILE" --arg output "$OUTPUT" \
    --arg model "$MODEL" --arg size "$SIZE" --argjson references "$REFERENCES" \
    '{request_id:$id,prompt_file:$prompt,output:$output,model:$model,size:$size,references:$references,automatic_retry:false}' \
    > "$AUDIT_DIR/request-meta.json"
  write_lifecycle prepared "inputs validated; no POST has started"
fi

if [[ "$REFERENCES" != "[]" ]]; then
  CURL_ARGS=(--fail-with-body -sS -X POST "$BASE_URL/images/edits"
    -H "Authorization: Bearer $GPT_IMAGE_API_KEY"
    -F "model=$MODEL" -F "prompt=$PROMPT" -F "size=$SIZE"
    -F 'quality=high' -F 'output_format=png')
  while IFS= read -r reference; do
    [[ -n "$reference" ]] || continue
    if [[ "$reference" != /* && ! -f "$reference" ]]; then reference="$PROJECT_DIR/$reference"; fi
    [[ -f "$reference" ]] || { write_lifecycle local_preflight_failed "missing reference: $reference"; echo "missing reference: $reference" >&2; exit 1; }
    CURL_ARGS+=( -F "image[]=@$reference" )
  done < <(jq -r '.[]' <<< "$REFERENCES")
  ENDPOINT="images/edits"
else
  REQUEST_BODY="$TEMP_DIR/request-body.json"
  jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --arg size "$SIZE" \
    '{model:$model,prompt:$prompt,size:$size,quality:"high",output_format:"png"}' > "$REQUEST_BODY"
  [[ -n "$AUDIT_DIR" ]] && cp "$REQUEST_BODY" "$AUDIT_DIR/request-body.json"
  CURL_ARGS=(--fail-with-body -sS -X POST "$BASE_URL/images/generations"
    -H 'Content-Type: application/json'
    -H "Authorization: Bearer $GPT_IMAGE_API_KEY"
    --data-binary "@$REQUEST_BODY")
  ENDPOINT="images/generations"
fi

if [[ -n "$AUDIT_DIR" ]]; then
  [[ ! -e "$AUDIT_DIR/submission.locked" ]] || { echo "request id already used: $REQUEST_ID" >&2; exit 1; }
  : > "$AUDIT_DIR/submission.locked"
  jq --arg endpoint "$ENDPOINT" --arg at "$(date -Is)" '. + {endpoint:$endpoint,request_ready_at:$at}' \
    "$AUDIT_DIR/request-meta.json" > "$AUDIT_DIR/request-meta.next.json"
  mv "$AUDIT_DIR/request-meta.next.json" "$AUDIT_DIR/request-meta.json"
  write_lifecycle submitting "POST started; interruption is potentially billable"
fi

set +e
curl "${CURL_ARGS[@]}" > "$RESPONSE"
CURL_RESULT=$?
set -e
if [[ "$CURL_RESULT" -ne 0 ]]; then
  write_lifecycle ambiguous_submission "curl exit $CURL_RESULT; do not resubmit"
  exit "$CURL_RESULT"
fi
write_lifecycle response_received "provider response received"

B64="$(jq -r '.data[0].b64_json // empty' "$RESPONSE" 2>/dev/null || true)"
URL="$(jq -r '.data[0].url // empty' "$RESPONSE" 2>/dev/null || true)"
if [[ -z "$B64" && -z "$URL" ]]; then
  write_lifecycle ambiguous_result "response did not contain image data; reconcile provider task before any retry"
  jq . "$RESPONSE" >&2 2>/dev/null || true
  exit 1
fi
if [[ -n "$B64" ]]; then
  printf '%s' "$B64" | base64 --decode > "$OUTPUT" || { write_lifecycle ambiguous_result "image payload decode failed"; exit 1; }
else
  curl --fail-with-body -sS -L "$URL" -o "$OUTPUT" || { write_lifecycle ambiguous_result "image download failed after provider response"; exit 1; }
fi
[[ -s "$OUTPUT" ]] || { write_lifecycle ambiguous_result "empty image output"; exit 1; }
if [[ -n "$AUDIT_DIR" ]]; then
  sha256sum "$OUTPUT" > "$AUDIT_DIR/output.sha256"
  write_lifecycle completed "image saved; semantic QC still required"
fi
echo "image saved: $OUTPUT"
