#!/usr/bin/env bash
set -Eeuo pipefail

ROOT="/home/ubuntu/ads_skill"
PROJECT="$ROOT/replication/output/love-story-level-5"
LOG="$PROJECT/automation/video-pending-preparation.log"
mkdir -p "$(dirname "$LOG")"
exec > >(tee -a "$LOG") 2>&1

echo "[video-pending] started $(date -Is)"
cd "$ROOT"

for shot in 01 02 03 04 05 06 07 08; do
  contract="$PROJECT/shots/shot-$shot/slots.json"
  test -f "$contract"
  status=$(jq -r '.status' "$contract")
  test "$status" = prompts_ready
  slot_count=$(jq '.slots | length' "$contract")
  test "$slot_count" -gt 0
  echo "[video-pending] shot-$shot contract prompts_ready slots=$slot_count"
done

for prompt in "$PROJECT"/prompts/*.json; do
  type=$(jq -r '.seedance_prompt_review.asset_type // empty' "$prompt")
  case "$type" in
    image|video) "$ROOT/replication/tools/validate-seedance-prompt-review.sh" "$prompt" "$type" >/dev/null ;;
  esac
done

node "$ROOT/replication/tools/build-output-review.mjs"
for shot in 01 02 03 04 05 06 07 08; do
  page="$PROJECT/review/shot-$shot.html"
  test -f "$page"
  grep -q '生成槽位' "$page"
  grep -q '待你确认' "$page"
done

if find "$PROJECT/automation" -maxdepth 2 -type f -name 'submission.locked' -print -quit | grep -q .; then
  echo "[video-pending] ERROR: found locked submission; refusing to claim pending-only state"
  exit 1
fi

echo "[video-pending] all shots prepared; video generation remains confirmation-blocked"
echo "[video-pending] finished $(date -Is)"
