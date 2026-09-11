#!/usr/bin/env bash
set -Eeuo pipefail

[[ $# -eq 2 ]] || { echo "usage: validate-seedance-prompt-review.sh <prompt.json> <image|video>" >&2; exit 2; }
prompt_file="$1"
asset_type="$2"
[[ -f "$prompt_file" ]] || { echo "prompt review gate: missing prompt file: $prompt_file" >&2; exit 1; }
[[ "$asset_type" == image || "$asset_type" == video ]] || { echo "prompt review gate: asset type must be image or video" >&2; exit 2; }
command -v jq >/dev/null || { echo "prompt review gate: jq is required" >&2; exit 1; }
command -v sha256sum >/dev/null || { echo "prompt review gate: sha256sum is required" >&2; exit 1; }

jq -e --arg type "$asset_type" '
  (.prompt | type == "string" and length > 0) and
  (.seedance_prompt_review | type == "object") and
  (.seedance_prompt_review.skill == "seedance-prompt-zh") and
  (.seedance_prompt_review.authorship == "generated_by_skill") and
  (.seedance_prompt_review.result == "pass") and
  (.seedance_prompt_review.asset_type == $type) and
  (.seedance_prompt_review.reviewed_at | type == "string" and length > 0) and
  (.seedance_prompt_review.checks | type == "array" and length > 0) and
  (.seedance_prompt_review.unresolved_blockers | type == "array" and length == 0) and
  (.seedance_prompt_review.reviewed_prompt_sha256 | type == "string" and length == 64) and
  (.narrative_alignment | type == "object") and
  (.narrative_alignment.source_story | type == "string" and length > 0) and
  (.narrative_alignment.related_beats | type == "array" and length > 0) and
  (.narrative_alignment.related_shots | type == "array" and length > 0) and
  (.narrative_alignment.visual_evidence | type == "array" and length > 0) and
  (.narrative_alignment.unresolved_blockers | type == "array" and length == 0)
' "$prompt_file" >/dev/null || {
  echo "prompt review gate: prompt was not generated and passed by seedance-prompt-zh for $asset_type" >&2
  exit 1
}
reviewed_hash="$(jq -r '.seedance_prompt_review.reviewed_prompt_sha256' "$prompt_file")"
actual_hash="$(jq -jr '.prompt' "$prompt_file" | sha256sum | awk '{print $1}')"
[[ "$reviewed_hash" == "$actual_hash" ]] || {
  echo "prompt review gate: prompt changed after seedance-prompt-zh review" >&2
  exit 1
}
echo "prompt review gate: pass ($asset_type, seedance-prompt-zh)"
