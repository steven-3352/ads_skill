#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROMPTS_DIR="$BASE_DIR/prompts"
REFERENCES_FILE="$BASE_DIR/references.json"
API_URL="${DEEPKEY_API_URL:-https://deepkey.top/v1/videos}"
MODEL="${DEEPKEY_VIDEO_MODEL:-Minimax-H3-768p-933-15s}"

usage() { echo "用法: $0 character|cover|video-1|video-2" >&2; exit 2; }
[[ $# -eq 1 ]] || usage
[[ -n "${DEEPKEY_API_KEY:-}" ]] || { echo "请先设置 DEEPKEY_API_KEY" >&2; exit 1; }
[[ -f "$REFERENCES_FILE" ]] || { echo "找不到参考图配置: $REFERENCES_FILE" >&2; exit 1; }

case "$1" in
  character) FILE="$PROMPTS_DIR/character.json"; IMAGES='[]'; ENDPOINT="${DEEPKEY_IMAGE_API_URL:-https://deepkey.top/v1/images}" ;;
  cover|video-1|video-2) FILE="$PROMPTS_DIR/$1.json"; ENDPOINT="$API_URL" ;;
  *) usage ;;
esac

GLOBAL_VISUAL_CONSTRAINT='HUMAN-FIRST COMPOSITION: The face, direct eye contact, micro-expressions and relationship atmosphere must remain the visual focus. Every prop is only a small unbranded story detail and should occupy less than about 10 percent of the frame. Never place a prop close to the lens, centered as the subject, isolated in a close-up, rotated for display, or emphasized with product-photography lighting or shallow focus. No package front, readable label, brand, price, flavor, specification, product feature, purchase cue or commercial demonstration.'
PROMPT="$(jq -r '.prompt' "$FILE") $GLOBAL_VISUAL_CONSTRAINT"
"$BASE_DIR/../../../scripts/check-generation-constraints.sh" "$FILE"
if [[ -n "${NAN_IMAGE_URL:-}" ]]; then IMAGES="[$(jq -Rn --arg u "$NAN_IMAGE_URL" '$u')]"; else IMAGES="$(jq -c --arg key "$1" '.[$key] // .identity // []' "$REFERENCES_FILE")"; fi
if [[ -n "${NAN_LAST_FRAME_URL:-}" && "$1" == video-2 ]]; then IMAGES="$(jq -c --argjson refs "$IMAGES" --arg u "$NAN_LAST_FRAME_URL" '$refs + [$u]')"; fi
if [[ "$1" == character ]]; then
  jq -n --arg prompt "$PROMPT" '{prompt:$prompt}' | curl -fsS -X POST "$ENDPOINT" -H 'Content-Type: application/json; charset=utf-8' -H "Authorization: Bearer ${DEEPKEY_API_KEY}" --data-binary @-
else
  jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --argjson images "$IMAGES" '{model:$model,prompt:$prompt,images:$images,aspect_ratio:"9:16"}' | curl -fsS -X POST "$ENDPOINT" -H 'Content-Type: application/json; charset=utf-8' -H "Authorization: Bearer ${DEEPKEY_API_KEY}" --data-binary @-
fi
