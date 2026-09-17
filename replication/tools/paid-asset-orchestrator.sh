#!/usr/bin/env bash
set -Eeuo pipefail

die() { echo "error: $*" >&2; exit 1; }
usage() {
  cat >&2 <<'USAGE'
Usage:
  paid-asset-orchestrator.sh validate <state.json>
  paid-asset-orchestrator.sh run-asset <state.json> <asset-id>
  paid-asset-orchestrator.sh accept <state.json> <asset-id> <evidence> <note> <reviewer>
  paid-asset-orchestrator.sh reject <state.json> <asset-id> <evidence> <note> <reviewer>
  paid-asset-orchestrator.sh auto-qc <state.json> <asset-id>
  paid-asset-orchestrator.sh reconcile-no-post <state.json> <asset-id> <evidence-dir> <note> <reviewer>
USAGE
  exit 2
}
[[ $# -ge 2 ]] || usage
cmd="$1"
state="$2"
[[ -f "$state" ]] || die "missing state: $state"
command -v jq >/dev/null || die "jq is required"
command -v flock >/dev/null || die "flock is required"
state="$(cd "$(dirname "$state")" && pwd)/$(basename "$state")"
dir="$(dirname "$state")"
root="$(cd "$(dirname "$BASH_SOURCE")/../.." && pwd)"
exec 9>"$state.lock"
flock -n 9 || die "state is locked by another process"

save() {
  local tmp
  tmp="$(mktemp "$dir/.state.XXXXXX")"
  jq "$@" "$state" > "$tmp" && mv "$tmp" "$state"
}
snap() {
  local tmp
  tmp="$(mktemp "$dir/.manifest.XXXXXX")"
  jq . "$state" > "$tmp" && mv "$tmp" "$dir/manifest.json"
}
idx() { jq -er --arg id "$1" '.assets | map(.id) | index($id)' "$state"; }
now() { date -Is; }
assert_state() {
  jq -e '
    .schema_version == 1 and
    (.assets | type == "array") and
    ((.assets | map(.id) | length) == (.assets | map(.id) | unique | length)) and
    (.budget.committed_yuan | type == "number") and
    (.budget.hard_cap_yuan | type == "number") and
    (.authorization.committed_yuan | type == "number") and
    (.authorization.increment_cap_yuan | type == "number") and
    (.budget.committed_yuan <= .budget.hard_cap_yuan) and
    (.authorization.committed_yuan <= .authorization.increment_cap_yuan)
  ' "$state" >/dev/null || die "state invariant failed"
}
assert_state
case "$cmd" in
validate)
  jq '{project_id,episode,status,budget,authorization,assets:[.assets[]|{id,kind,status,cost_yuan,depends_on,output}],events:(.events|length)}' "$state"
  ;;
run-asset)
  [[ $# -eq 3 ]] || usage
  id="$3"
  i="$(idx "$id")" || die "unknown asset: $id"
  jq -e '([.assets[]|select(.status=="submitting" or .status=="ambiguous_submission")]|length==0) and ((.authorization.allow_pending_semantic_qc // false) or ([.assets[]|select(.status=="generated_pending_qc")]|length==0))' "$state" >/dev/null || die "another paid asset is unsettled; gate closed"
  a="$(jq -c --argjson i "$i" '.assets[$i]' "$state")"
  kind="$(jq -r '.kind' <<<"$a")"
  status="$(jq -r '.status' <<<"$a")"
  [[ "$kind" == image || "$kind" == video || "$kind" == speech ]] || die "unsupported asset kind: $kind"
  [[ "$status" == ready ]] || die "asset is not ready: $status"
  jq -e --arg id "$id" '.authorization.asset_ids|index($id)!=null' "$state" >/dev/null || die "asset is outside authorization"
  jq -e --arg id "$id" '
    . as $root |
    ((.assets[]|select(.id==$id)|.depends_on)//[]) as $deps |
    all($deps[]; . as $d | any($root.assets[]; .status=="accepted" and (.id==$d or (.replaces//"")==$d)))
  ' "$state" >/dev/null || die "dependencies are not accepted"
  cost="$(jq -r '.cost_yuan' <<<"$a")"
  jq -e --argjson c "$cost" '.budget.committed_yuan+$c<=.budget.hard_cap_yuan and .authorization.committed_yuan+$c<=.authorization.increment_cap_yuan' "$state" >/dev/null || die "budget gate failed"
  prompt="$(jq -r '.prompt_file' <<<"$a")"
  out="$(jq -r '.output' <<<"$a")"
  [[ "$prompt" = /* ]] || prompt="$root/$prompt"
  [[ "$out" = /* ]] || out="$root/$out"
  [[ -f "$prompt" ]] || die "missing prompt: $prompt"
  if [[ "$kind" == video && "$(jq -r '.model // .provider // "Seedance-2.0"' <<<"$a")" == "MiniMax-H3" ]]; then
    "$root/replication/tools/validate-h3-prompt-review.sh" "$prompt" video
  elif [[ "$kind" == video ]]; then
    "$root/replication/tools/validate-seedance-prompt-review.sh" "$prompt" video
  elif [[ "$kind" == image ]]; then
    "$root/replication/tools/validate-seedance-prompt-review.sh" "$prompt" image
  fi
  # kind==speech：无对应 prompt-review 校验器（配音由 stage5 语义 accept 把关），跳过技术评审
  [[ ! -e "$out" ]] || die "refusing to overwrite: $out"
  audit="$dir/requests/$id"
  mkdir -p "$audit" "$(dirname "$out")"
  ts="$(now)"
  save --argjson i "$i" --arg id "$id" --arg ts "$ts" --arg cost "$cost" --arg audit "${audit#$root/}" '
    .assets[$i].status="submitting" |
    .assets[$i].submission_started_at=$ts |
    .assets[$i].audit_dir=$audit |
    .status="paid_call_in_progress" |
    .updated_at=$ts |
    .events += [{at:$ts,type:"submission_started",asset_id:$id,cost_yuan:($cost|tonumber)}]
  '
  snap
  set +e
  if [[ "$kind" == image ]]; then
    "$root/replication/tools/generate-image.sh" --prompt "$prompt" --output-dir "$(dirname "$out")" --output-name "$(basename "$out")" --audit-dir "$audit" --request-id "$id"
    rc=$?
  elif [[ "$kind" == speech ]]; then
    # generate-speech.sh 原生支持 --audit-dir/--request-id，自写 lifecycle.json（submitting→
    # ambiguous_submission/ambiguous_result→completed）与 output.sha256，与 image 同构，无需补齐。
    "$root/replication/tools/generate-speech.sh" --prompt "$prompt" --output-dir "$(dirname "$out")" --output-name "$(basename "$out")" --audit-dir "$audit" --request-id "$id"
    rc=$?
  else
    # generate-video.sh 不接受 --audit-dir、不写 lifecycle.json（保持可单独执行的原子工具，不改它）。
    # 编排层在此为 video 补齐 audit 证据 + lifecycle 归类，让失败分类逻辑（下方 case）对
    # video 与 image 一致，修复"已付费视频被误判为 cost=0"的 bug。
    vresp="$(dirname "$out")/$(basename "${out%.mp4}.json")"
    "$root/replication/tools/generate-video.sh" --prompt "$prompt" --output-dir "$(dirname "$out")" --output-name "$(basename "${out%.mp4}.json")" --wait --download
    rc=$?
    vtask=""; vret=""
    if [[ -s "$vresp" ]]; then
      vtask="$(jq -r '.id // .task_id // .data.id // .data.task_id // empty' "$vresp" 2>/dev/null || true)"
      vret="$(jq -r '.RetCode // .base_resp.status_code // empty' "$vresp" 2>/dev/null || true)"
      cp "$vresp" "$audit/response.json" 2>/dev/null || true
      [[ -f "$vresp.status.json" ]] && cp "$vresp.status.json" "$audit/status.json" 2>/dev/null || true
    fi
    if [[ $rc -eq 0 ]]; then                                  vlife=completed
    elif [[ ! -s "$vresp" ]]; then                            vlife=local_preflight_failed   # 未触达 POST → cost 0
    elif [[ -n "$vtask" ]]; then                              vlife=ambiguous_submission     # 任务已创建 → 计费
    elif [[ -n "$vret" && "$vret" != "0" ]]; then             vlife=local_preflight_failed   # 业务拒绝(积分不足等)，无任务 → cost 0
    else                                                      vlife=ambiguous_submission     # POST 已达但无 task_id → 保守计费
    fi
    jq -cn --arg s "$vlife" --arg id "$id" --arg tid "$vtask" --arg at "$(now)" \
      '{state:$s,asset_id:$id,task_id:$tid,at:$at,source:"orchestrator-video-backfill"}' > "$audit/lifecycle.json"
  fi
  set -e
  life="$(jq -r '.state // empty' "$audit/lifecycle.json" 2>/dev/null || true)"
  ts="$(now)"
  if [[ $rc -ne 0 ]]; then
    case "$life" in
      submitting|ambiguous_submission|response_received|ambiguous_result|completed)
        save --argjson i "$i" --argjson c "$cost" --arg id "$id" --arg ts "$ts" --argjson rc "$rc" --arg life "$life" '
          .assets[$i].status="ambiguous_submission" |
          .assets[$i].error_exit_code=$rc |
          .assets[$i].lifecycle_state=$life |
          .budget.committed_yuan += $c |
          .authorization.committed_yuan += $c |
          .status="blocked_ambiguous_submission" |
          .updated_at=$ts |
          .events += [{at:$ts,type:"submission_ambiguous",asset_id:$id,cost_yuan:$c,exit_code:$rc,lifecycle_state:$life}]
        '
        ;;
      *)
        save --argjson i "$i" --arg id "$id" --arg ts "$ts" --argjson rc "$rc" --arg life "$life" '
          .assets[$i].status="blocked_local_error" |
          .assets[$i].error_exit_code=$rc |
          .assets[$i].lifecycle_state=($life // "none") |
          .status="blocked_local_error" |
          .updated_at=$ts |
          .events += [{at:$ts,type:"local_preflight_failed",asset_id:$id,exit_code:$rc,lifecycle_state:($life // "none"),cost_yuan:0}]
        '
        ;;
    esac
    snap
    exit 1
  fi
  [[ -s "$out" ]] || {
    save --argjson i "$i" --argjson c "$cost" --arg id "$id" --arg ts "$ts" '
      .assets[$i].status="ambiguous_submission" |
      .budget.committed_yuan += $c |
      .authorization.committed_yuan += $c |
      .status="blocked_ambiguous_submission" |
      .updated_at=$ts |
      .events += [{at:$ts,type:"missing_output_after_success",asset_id:$id,cost_yuan:$c}]
    '
    snap
    die "provider returned without a usable output; do not retry"
  }
  hash="$(sha256sum "$out"|awk '{print $1}')"
  save --argjson i "$i" --argjson c "$cost" --arg id "$id" --arg ts "$ts" --arg hash "$hash" '
    .assets[$i].status="generated_pending_qc" |
    .assets[$i].sha256=$hash |
    .budget.committed_yuan += $c |
    .authorization.committed_yuan += $c |
    .status="blocked_pending_semantic_qc" |
    .updated_at=$ts |
    .events += [{at:$ts,type:"generation_received",asset_id:$id,cost_yuan:$c,sha256:$hash}]
  '
  snap
  echo "generated; semantic QC required: $out"
  ;;
accept|reject)
  [[ $# -eq 6 ]] || usage
  id="$3"; evidence="$4"; note="$5"; reviewer="$6"; i="$(idx "$id")" || die "unknown asset"
  [[ -f "$evidence" ]] || die "missing evidence: $evidence"
  [[ "$(jq -r --argjson i "$i" '.assets[$i].status' "$state")" == generated_pending_qc ]] || die "asset is not pending QC"
  ts="$(now)"; result="$cmd"; new_status=accepted
  [[ "$cmd" == reject ]] && new_status=rejected
  save --argjson i "$i" --arg id "$id" --arg status "$new_status" --arg result "$result" --arg ts "$ts" --arg evidence "$evidence" --arg note "$note" --arg reviewer "$reviewer" '
    .assets[$i].status=$status | .assets[$i].accepted_at=(if $status=="accepted" then $ts else .assets[$i].accepted_at end) |
    .assets[$i].semantic_qc={result:$result,at:$ts,evidence:$evidence,note:$note,reviewer:$reviewer} |
    .events += [{at:$ts,type:("semantic_qc_"+$result),asset_id:$id,evidence:$evidence,note:$note,reviewer:$reviewer}] |
    .status=(if $status=="accepted" then "gate_recalculating" else "blocked_qc_rejected" end) |
    .updated_at=$ts
  '
  if [[ "$cmd" == accept ]]; then
    ts="$(now)"
    save --arg ts "$ts" '
      . as $root |
      .assets |= map(
        if .status=="blocked" and ((.depends_on//[])|all(. as $d|any($root.assets[];.status=="accepted" and (.id==$d or (.replaces//"")==$d))))
        then .status="ready" else . end
      ) |
      .status=(if any(.assets[];.status=="ready") then "gate_open_for_next_authorized_asset" else "stage_complete_or_waiting_authorization" end) |
      .updated_at=$ts
    '
  fi
  snap
  echo "$id -> $new_status"
  ;;
reconcile-no-post)
  [[ $# -eq 6 ]] || usage
  id="$3"; evidence_dir="$4"; note="$5"; reviewer="$6"; i="$(idx "$id")" || die "unknown asset"
  [[ -d "$evidence_dir" ]] || die "missing evidence directory: $evidence_dir"
  current="$(jq -r --argjson i "$i" '.assets[$i].status' "$state")"
  [[ "$current" == ambiguous_submission || "$current" == blocked_local_error ]] || die "asset is not reconcilable: $current"
  life="$(jq -r '.state // empty' "$evidence_dir/lifecycle.json" 2>/dev/null || true)"
  [[ -z "$life" || "$life" == prepared || "$life" == local_preflight_failed ]] || die "audit shows provider interaction: $life"
  [[ ! -e "$evidence_dir/response.json" ]] || die "response evidence exists; provider reconciliation required"
  [[ ! -e "$evidence_dir/request-body.json" ]] || die "request body exists; provider reconciliation required"
  [[ -e "$evidence_dir/submission.locked" ]] && mv "$evidence_dir/submission.locked" "$evidence_dir/submission.locked.reconciled-no-post"
  cost="$(jq -r --argjson i "$i" '.assets[$i].cost_yuan' "$state")"
  ts="$(now)"
  save --argjson i "$i" --argjson c "$cost" --arg id "$id" --arg ts "$ts" --arg note "$note" --arg reviewer "$reviewer" --arg evidence "$evidence_dir" '
    .assets[$i].status="ready" |
    del(.assets[$i].error_exit_code,.assets[$i].lifecycle_state,.assets[$i].submission_started_at) |
    .budget.committed_yuan -= (if .budget.committed_yuan >= $c then $c else 0 end) |
    .authorization.committed_yuan -= (if .authorization.committed_yuan >= $c then $c else 0 end) |
    .status="gate_open_for_next_authorized_asset" |
    .updated_at=$ts |
    .events += [{at:$ts,type:"reconciled_no_post",asset_id:$id,cost_yuan:0,evidence:$evidence,note:$note,reviewer:$reviewer}]
  '
  snap
  echo "$id reconciled as no-post; cost returned to zero"
  ;;
auto-qc)
  [[ $# -eq 3 ]] || usage
  id="$3"; i="$(idx "$id")" || die "unknown asset"
  a="$(jq -c --argjson i "$i" '.assets[$i]' "$state")"
  [[ "$(jq -r '.status' <<<"$a")" == generated_pending_qc ]] || die "asset is not pending QC"
  out="$(jq -r '.output' <<<"$a")"; [[ "$out" = /* ]] || out="$root/$out"
  [[ -s "$out" ]] || die "missing generated output"
  kind="$(jq -r '.kind' <<<"$a")"; technical=pass
  if [[ "$kind" == image ]]; then
    command -v identify >/dev/null || die "identify required"
    identify -format '%wx%h' "$out" >/dev/null 2>&1 || technical=fail
  elif [[ "$kind" == video ]]; then
    command -v ffprobe >/dev/null || die "ffprobe required"
    ffprobe -v error "$out" >/dev/null 2>&1 || technical=fail
  elif [[ "$kind" == speech ]]; then
    command -v ffprobe >/dev/null || die "ffprobe required"
    # 音频解码 + 存在音频流 + 时长>0
    ffprobe -v error -select_streams a -show_entries stream=codec_type -of csv=p=0 "$out" 2>/dev/null | grep -q audio || technical=fail
  else
    technical=fail
  fi
  ts="$(now)"
  if [[ "$technical" == fail ]]; then
    save --argjson i "$i" --arg id "$id" --arg ts "$ts" '
      .assets[$i].status="rejected" |
      .assets[$i].technical_qc={result:"fail",at:$ts} |
      .status="blocked_technical_qc_rejected" | .updated_at=$ts |
      .events += [{at:$ts,type:"technical_qc_reject",asset_id:$id}]
    '
    snap; echo "$id -> rejected (technical QC)"; exit 1
  fi
  qc_cmd="$(jq -r '.qc_command // empty' <<<"$a")"
  if [[ -z "$qc_cmd" ]]; then
    save --argjson i "$i" --arg id "$id" --arg ts "$ts" '
      .assets[$i].technical_qc={result:"pass",at:$ts,note:"structural decode passed"} |
      .assets[$i].semantic_qc={result:"pending",at:$ts,note:"no semantic qc command configured"} |
      .status="blocked_pending_semantic_qc" | .updated_at=$ts |
      .events += [{at:$ts,type:"technical_qc_pass_semantic_pending",asset_id:$id}]
    '
    snap; echo "$id: technical QC passed; semantic QC pending"; exit 0
  fi
  flock -u 9
  if bash -c "$qc_cmd"; then
    "$0" accept "$state" "$id" "$out" "automated semantic QC passed" auto-qc
  else
    "$0" reject "$state" "$id" "$out" "automated semantic QC failed" auto-qc
  fi
  ;;
*) usage ;;
esac
