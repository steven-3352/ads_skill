#!/usr/bin/env bash
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; PROJECT_DIR="$(cd "$BASE_DIR/../../.." && pwd)"
set -a; [[ -f "$PROJECT_DIR/.env" ]] && source "$PROJECT_DIR/.env"; set +a
[[ $# -eq 1 && ( "$1" =~ ^video-[1-5]$ || "$1" == replica ) ]] || { echo "用法: $0 video-1|video-2|video-3|video-4|video-5|replica" >&2; exit 2; }
[[ -n "${MINIMAX_H3_API_KEY:-}" ]] || { echo "请设置 MINIMAX_H3_API_KEY" >&2; exit 1; }
PROMPT="$(python3 - "$BASE_DIR/prompts/$1.json" <<'PY'
import json, sys
d=json.load(open(sys.argv[1])); print(d['prompt'] + ('\n\nNEGATIVE PROMPT: ' + d['negative_prompt'] if d.get('negative_prompt') else ''))
PY
)"
"$BASE_DIR/../../../scripts/check-generation-constraints.sh" "$BASE_DIR/prompts/$1.json"
IMAGES="$(python3 - "$BASE_DIR/references.json" "$1" <<'PY'
import json, sys
d=json.load(open(sys.argv[1])); print(json.dumps(d.get(sys.argv[2], d['identity']), separators=(',', ':')))
PY
)"
GLOBAL='HUMAN-FIRST COMPOSITION: props under 10 percent, no commercial framing, labels, logos, prices or sales cues.'
python3 - "$PROMPT" "$GLOBAL" "$IMAGES" "${DEEPKEY_VIDEO_MODEL:-Minimax-H3-768p-933-15s}" <<'PY' | curl --fail-with-body -sS -X POST "${MINIMAX_H3_API_URL:-${GPT_IMAGE_BASE_URL:-https://deepkey.top/v1}/videos}" -H 'Content-Type: application/json; charset=utf-8' -H "Authorization: Bearer ${MINIMAX_H3_API_KEY}" --data-binary @-
import json, sys
payload = {'model':sys.argv[4], 'prompt':sys.argv[1]+' '+sys.argv[2], 'aspect_ratio':'9:16'}
images = json.loads(sys.argv[3])
if images:
    payload['images'] = images
print(json.dumps(payload))
PY
echo
