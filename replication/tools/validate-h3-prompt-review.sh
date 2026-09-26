#!/usr/bin/env bash
set -Eeuo pipefail
[[ $# -eq 2 ]] || { echo "usage: validate-h3-prompt-review.sh <prompt.json> <image|video>" >&2; exit 2; }
prompt_file="$1"; asset_type="$2"
[[ -f "$prompt_file" ]] || { echo "h3 prompt gate: missing prompt file" >&2; exit 1; }
[[ "$asset_type" == image || "$asset_type" == video ]] || { echo "h3 prompt gate: invalid asset type" >&2; exit 2; }
command -v jq >/dev/null || { echo "h3 prompt gate: jq is required" >&2; exit 1; }
if command -v sha256sum >/dev/null; then
  hash_stdin() { sha256sum | awk '{print $1}'; }
elif command -v shasum >/dev/null; then
  hash_stdin() { shasum -a 256 | awk '{print $1}'; }
else
  echo "h3 prompt gate: sha256sum or shasum is required" >&2
  exit 1
fi
jq -e --arg type "$asset_type" '
  (.prompt | type == "string" and length > 0) and
  (.h3_prompt_review | type == "object") and
  (.h3_prompt_review.skill == "h3-prompt-writing") and
  (.h3_prompt_review.authorship == "generated_by_skill") and
  (.h3_prompt_review.result == "pass") and
  (.h3_prompt_review.asset_type == $type) and
  (.h3_prompt_review.mode | type == "string" and length > 0) and
  (.h3_prompt_review.checks | type == "array" and length > 0) and
  (.h3_prompt_review.unresolved_blockers | type == "array" and length == 0) and
  (.h3_prompt_review.reviewed_prompt_sha256 | type == "string" and length == 64)
' "$prompt_file" >/dev/null || { echo "h3 prompt gate: prompt was not generated and passed by h3-prompt-writing" >&2; exit 1; }
reviewed_hash="$(jq -r '.h3_prompt_review.reviewed_prompt_sha256' "$prompt_file")"
actual_hash="$(jq -jr '.prompt' "$prompt_file" | hash_stdin)"
[[ "$reviewed_hash" == "$actual_hash" ]] || { echo "h3 prompt gate: prompt changed after h3-prompt-writing review" >&2; exit 1; }
echo "h3 prompt gate: pass ($asset_type, h3-prompt-writing)"
