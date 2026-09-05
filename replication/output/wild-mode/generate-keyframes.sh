#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
THEME_DIR="$ROOT_DIR/replication/output/wild-mode"
TOOL="$ROOT_DIR/replication/tools/generate-image.sh"

for frame in \
  kf-01-final-look-v1 \
  kf-02-room-anchor-v1 \
  kf-03-shoes-triptych-v1 \
  kf-04-watch-triptych-v1 \
  kf-05-glasses-triptych-v1 \
  kf-06-belt-triptych-v1 \
  kf-07-hat-triptych-v1
do
  "$TOOL" \
    --prompt "$THEME_DIR/prompts/$frame.json" \
    --output-dir "$THEME_DIR/keyframes" \
    --output-name "$frame.png" \
    --size 1024x1536
done
