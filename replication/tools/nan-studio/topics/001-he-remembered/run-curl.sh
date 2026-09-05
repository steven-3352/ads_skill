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
API_URL="${MINIMAX_H3_API_URL:-$API_V1/videos}"
MODEL="${DEEPKEY_VIDEO_MODEL:-Minimax-H3-768p-933-15s}"

usage() { echo "用法: $0 video-1|video-2" >&2; exit 2; }
die() { echo "错误: $*" >&2; exit 1; }
[[ $# -eq 1 ]] || usage
[[ -n "${MINIMAX_H3_API_KEY:-}" ]] || die "请在 $PROJECT_DIR/.env 设置 MINIMAX_H3_API_KEY"
command -v curl >/dev/null || die "需要 curl"
command -v jq >/dev/null || die "需要 jq"
[[ -f "$REFERENCES_FILE" ]] || die "找不到参考图配置: $REFERENCES_FILE"

SEGMENT="$1"
case "$SEGMENT" in video-1|video-2) ;; *) usage ;; esac
PROMPT_FILE="$PROMPTS_DIR/$SEGMENT.json"
[[ -f "$PROMPT_FILE" ]] || die "找不到提示词: $PROMPT_FILE"

PROMPT="$(jq -er '.prompt' "$PROMPT_FILE")"
"$PROJECT_DIR/scripts/check-generation-constraints.sh" "$PROMPT_FILE"
IMAGES="$(jq -ce --arg key "$SEGMENT" '.[$key] // []' "$REFERENCES_FILE")"
[[ "$(jq 'length' <<<"$IMAGES")" -gt 0 ]] || die "$SEGMENT 至少需要一个人物公网参考图"

if [[ "$SEGMENT" == video-2 ]]; then
  [[ -n "${NAN_LAST_FRAME_URL:-}" ]] || die "视频二必须设置 NAN_LAST_FRAME_URL（视频一最后一帧公网地址）"
  IMAGES="$(jq -c --argjson refs "$IMAGES" --arg last "$NAN_LAST_FRAME_URL" '$refs + [$last]')"
fi

jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --argjson images "$IMAGES" \
  '{model:$model,prompt:$prompt,images:$images,aspect_ratio:"9:16"}' \
  | curl --fail-with-body -sS -X POST "$API_URL" \
      -H 'Content-Type: application/json; charset=utf-8' \
      -H "Authorization: Bearer ${MINIMAX_H3_API_KEY}" --data-binary @-
echo
