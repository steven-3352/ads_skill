#!/usr/bin/env bash
set -Eeuo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"; PROJECT_DIR="$(cd "$BASE_DIR/../../../../.." && pwd)"
set -a; [[ -f "$PROJECT_DIR/.env" ]] && source "$PROJECT_DIR/.env"; set +a
[[ $# -eq 1 && ( "$1" =~ ^video-[1-5]$ || "$1" == replica ) ]] || { echo "用法: $0 video-1|video-2|video-3|video-4|video-5|replica" >&2; exit 2; }
[[ -n "${MINIMAX_H3_API_KEY:-}" ]] || { echo "请设置 MINIMAX_H3_API_KEY" >&2; exit 1; }
PROMPT="$(python3 - "$BASE_DIR/prompts/$1.json" <<'PY'
import json, sys
d=json.load(open(sys.argv[1])); print(d['prompt'] + ('\n\nNEGATIVE PROMPT: ' + d['negative_prompt'] if d.get('negative_prompt') else ''))
PY
)"
"$BASE_DIR/../../check-generation-constraints.sh" "$BASE_DIR/prompts/$1.json"
GLOBAL='HUMAN-FIRST COMPOSITION: props under 10 percent, no commercial framing, labels, logos, prices or sales cues.'
RESPONSE_FILE="${NAN_RESPONSE_FILE:-}"
REQUEST_FILE="$(mktemp)"
trap 'rm -f "$REQUEST_FILE"' EXIT
python3 - "$PROMPT" "$GLOBAL" "$BASE_DIR/references.json" "$1" "$BASE_DIR" "${DEEPKEY_VIDEO_MODEL:-Minimax-H3-768p-933-15s}" > "$REQUEST_FILE" <<'PY'
import base64, json, mimetypes, pathlib, sys
prompt, global_prompt, refs_file, key, base_dir, model = sys.argv[1:]
d=json.load(open(refs_file))
items=d.get(key, d.get('identity', []))
images=[]
for item in items:
    if isinstance(item, str):
        images.append(item)
        continue
    local_path=pathlib.Path(item['local_path'])
    if not local_path.is_absolute():
        local_path=pathlib.Path(base_dir) / local_path
    mime=mimetypes.guess_type(local_path.name)[0] or 'image/png'
    encoded=base64.b64encode(local_path.read_bytes()).decode('ascii')
    images.append(f'data:{mime};base64,{encoded}')
payload = {'model':model, 'prompt':prompt+' '+global_prompt, 'aspect_ratio':'9:16'}
if images:
    payload['images'] = images
print(json.dumps(payload))
PY
if [[ -n "$RESPONSE_FILE" ]]; then
  mkdir -p "$(dirname "$RESPONSE_FILE")"
  curl --fail-with-body -sS -X POST "${MINIMAX_H3_API_URL:-${GPT_IMAGE_BASE_URL:-https://deepkey.top/v1}/videos}" -H 'Content-Type: application/json; charset=utf-8' -H "Authorization: Bearer ${MINIMAX_H3_API_KEY}" --data-binary "@$REQUEST_FILE" | tee "$RESPONSE_FILE"
else
  curl --fail-with-body -sS -X POST "${MINIMAX_H3_API_URL:-${GPT_IMAGE_BASE_URL:-https://deepkey.top/v1}/videos}" -H 'Content-Type: application/json; charset=utf-8' -H "Authorization: Bearer ${MINIMAX_H3_API_KEY}" --data-binary "@$REQUEST_FILE"
fi
echo
