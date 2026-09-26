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
  paid-asset-orchestrator.sh reconcile-submitting <state.json> <asset-id> <evidence-dir> <note> <reviewer>
  paid-asset-orchestrator.sh reconcile-failed-task <state.json> <asset-id> <evidence-dir> <note> <reviewer>
  paid-asset-orchestrator.sh supersede <state.json> <rejected-id> <by-accepted-id> <note> <reviewer>
  paid-asset-orchestrator.sh supersede-accepted <state.json> <accepted-loser-id> <by-accepted-id> <note> <reviewer>
  paid-asset-orchestrator.sh authorize-assets <state.json> <assets-array.json> <new-hard-cap> <new-increment-cap> <note> <reviewer>
  paid-asset-orchestrator.sh deauthorize-ready <state.json> <asset-id> <note> <reviewer>
  paid-asset-orchestrator.sh set-pending-qc <state.json> <true|false> <note> <reviewer>
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
  # 视频预校验须与实际生成脚本一致：generate-video.sh 默认 PROVIDER=minimax(H3)，
  # 且本编排层调它时从不传 --provider ⇒ 视频实际永远走 H3。故 model 缺省解析为 MiniMax-H3，
  # 用 h3 评审门；仅当资产显式 model=Seedance-2.0 才落 seedance 分支。
  if [[ "$kind" == video && "$(jq -r '.model // .provider // "MiniMax-H3"' <<<"$a")" == "MiniMax-H3" ]]; then
    "$root/replication/tools/validate-h3-prompt-review.sh" "$prompt" video
  elif [[ "$kind" == video ]]; then
    "$root/replication/tools/validate-seedance-prompt-review.sh" "$prompt" video
  elif [[ "$kind" == image ]]; then
    # image 预校验与下游 generate-image.sh 内部门禁同构：按提示词实际评审块自动选校验器。
    # 修正原硬编码 image→seedance 与实际生成器(有 h3_prompt_review 块则走 h3)不一致、
    # 导致 H3 风格图片提示词在 orchestrator 预检即被误拒的缺陷；seedance 图片(无 h3 块)仍走
    # seedance，校验强度不降（两个校验器都强制 skill review 块 + sha256 防篡改）。
    if jq -e '(.h3_prompt_review != null) or (.model == "MiniMax-H3") or (.authoring_skill == "h3-prompt-writing")' "$prompt" >/dev/null 2>&1; then
      "$root/replication/tools/validate-h3-prompt-review.sh" "$prompt" image
    else
      "$root/replication/tools/validate-seedance-prompt-review.sh" "$prompt" image
    fi
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
    # 图片尺寸须与目标视频画幅对应（避免 GPT Image 与 H3 画幅不符致拉伸变形）。
    # 从 asset.size 读，默认 1536x1024（横版，最接近 16:9 的 gpt-image 档）。
    size="$(jq -r '.size // "1536x1024"' <<<"$a")"
    "$root/replication/tools/generate-image.sh" --prompt "$prompt" --output-dir "$(dirname "$out")" --output-name "$(basename "$out")" --audit-dir "$audit" --request-id "$id" --size "$size"
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
    vtask=""; vret=""; vhttp=""
    if [[ -s "$vresp" ]]; then
      vtask="$(jq -r '.id // .task_id // .data.id // .data.task_id // empty' "$vresp" 2>/dev/null || true)"
      vret="$(jq -r '.RetCode // .base_resp.status_code // empty' "$vresp" 2>/dev/null || true)"
      # 通用网关/代理层 4xx 错误封套(如请求体非法被 json unmarshal 拒绝)——不带 minimax 业务码 RetCode、
      # 不带 task_id。以 http_code 识别，避免此类"未触达生成"被下方保守 else 误判为 ambiguous_submission(计费)。
      vhttp="$(jq -r '.error.http_code // .http_code // .error.status // empty' "$vresp" 2>/dev/null || true)"
      cp "$vresp" "$audit/response.json" 2>/dev/null || true
      [[ -f "$vresp.status.json" ]] && cp "$vresp.status.json" "$audit/status.json" 2>/dev/null || true
    fi
    if [[ $rc -eq 0 ]]; then                                  vlife=completed
    elif [[ ! -s "$vresp" ]]; then                            vlife=local_preflight_failed   # 未触达 POST → cost 0
    elif [[ -n "$vtask" ]]; then                              vlife=ambiguous_submission     # 任务已创建 → 计费
    elif [[ -n "$vret" && "$vret" != "0" ]]; then             vlife=local_preflight_failed   # 业务拒绝(积分不足等)，无任务 → cost 0
    elif [[ -n "$vhttp" && "$vhttp" == 4* && -z "$vtask" ]]; then vlife=local_preflight_failed # 网关4xx拒绝(请求体非法等)，无task_id → 未触达生成、未计费
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
  # 通用网关 4xx 拒绝(如请求体非法被 json unmarshal 拒绝)不带 minimax 业务码 RetCode、不带 task_id，
  # run-asset 旧分类器会保守落成 ambiguous_submission。这类"未触达生成、未计费"等同 no-post：
  # 仅当 response.json 铁证为 4xx 错误封套且无 task_id 时，放行 ambiguous_submission 走本条对账；
  # 下方 task_id / 产物护栏仍逐项复核，任一命中即拒，门不被削弱。
  http4xx_no_task=0
  if [[ "$life" == ambiguous_submission && -s "$evidence_dir/response.json" ]]; then
    _rhttp="$(jq -r '.error.http_code // .http_code // .error.status // empty' "$evidence_dir/response.json" 2>/dev/null || true)"
    _rtid0="$(jq -r '.task_id // .id // .data.task_id // .data.id // empty' "$evidence_dir/response.json" 2>/dev/null || true)"
    [[ -n "$_rhttp" && "$_rhttp" == 4* && -z "$_rtid0" ]] && http4xx_no_task=1
  fi
  [[ -z "$life" || "$life" == prepared || "$life" == local_preflight_failed || "$http4xx_no_task" == 1 ]] || die "audit shows provider interaction: $life"
  # 例外：积分不足(RetCode=226638)等"远端 HTTP200 拒绝"会落 response.json(带 RetCode/无 task_id、无产物),
  # 本质是"未触达生成、未计费",等同 no-post。仅当 response 带 task_id 或已产出结果，才须走 provider 对账。
  if [[ -s "$evidence_dir/response.json" ]]; then
    rtid="$(jq -r '.task_id // .id // .data.task_id // .data.id // empty' "$evidence_dir/response.json" 2>/dev/null || true)"
    ochk="$(jq -r --argjson i "$i" '.assets[$i].output' "$state")"; [[ "$ochk" = /* ]] || ochk="$root/$ochk"
    [[ -z "$rtid" ]] || die "response carries task_id ($rtid); provider reconciliation required"
    [[ ! -e "$ochk" ]] || die "output exists ($ochk); route through QC not reconcile"
  fi
  [[ -e "$evidence_dir/submission.locked" ]] && mv "$evidence_dir/submission.locked" "$evidence_dir/submission.locked.reconciled-no-post"
  cost="$(jq -r --argjson i "$i" '.assets[$i].cost_yuan' "$state")"
  # 退款依据须与"当初是否计入 committed"一致：
  #   ambiguous_submission = run-asset 失败分类时已 += cost（已计费）⇒ 复位应退回 cost；
  #   blocked_local_error  = 本地预检失败分支从不 += committed（cost 恒 0）⇒ 复位不得退款，
  #                          否则会误减掉其它资产贡献的 committed（账实不符）。
  if [[ "$current" == ambiguous_submission ]]; then refund="$cost"; else refund=0; fi
  ts="$(now)"
  save --argjson i "$i" --argjson r "$refund" --arg id "$id" --arg ts "$ts" --arg note "$note" --arg reviewer "$reviewer" --arg evidence "$evidence_dir" '
    .assets[$i].status="ready" |
    del(.assets[$i].error_exit_code,.assets[$i].lifecycle_state,.assets[$i].submission_started_at) |
    .budget.committed_yuan -= (if .budget.committed_yuan >= $r then $r else 0 end) |
    .authorization.committed_yuan -= (if .authorization.committed_yuan >= $r then $r else 0 end) |
    .status="gate_open_for_next_authorized_asset" |
    .updated_at=$ts |
    .events += [{at:$ts,type:"reconciled_no_post",asset_id:$id,cost_yuan:0,refunded_yuan:$r,evidence:$evidence,note:$note,reviewer:$reviewer}]
  '
  snap
  echo "$id reconciled as no-post; refunded=$refund; committed adjusted"
  ;;
reconcile-submitting)
  # 恢复"POST 已发起但进程被中途杀死"卡在 submitting 的资产。
  # 与 reconcile-no-post 的区别：那条要求 audit 未触达 provider（lifecycle 为空/prepared）；
  # 本条专门吃 lifecycle.state==submitting（POST 已发起、被中断），前提是无任何已确认结果：
  # 无产物文件、response.json 不存在或为空、无 task_id。
  # 计费依据：run-asset 设 submitting 时（本文件 L94-101）只追加事件、不加 committed_yuan；
  # 扣费只在其后的失败分类/成功落账发生。被杀在分类之前 ⇒ committed 从未加钱 ⇒ 复位不退款、不减 committed。
  # lifecycle detail 标"potentially billable"：同步图像接口被打断理论上有极小计费可能，事件里如实留痕。
  [[ $# -eq 6 ]] || usage
  id="$3"; evidence_dir="$4"; note="$5"; reviewer="$6"; i="$(idx "$id")" || die "unknown asset"
  [[ -d "$evidence_dir" ]] || die "missing evidence directory: $evidence_dir"
  current="$(jq -r --argjson i "$i" '.assets[$i].status' "$state")"
  [[ "$current" == submitting ]] || die "asset is not in submitting: $current (use reconcile-no-post for ambiguous_submission/blocked_local_error)"
  life="$(jq -r '.state // empty' "$evidence_dir/lifecycle.json" 2>/dev/null || true)"
  [[ "$life" == submitting ]] || die "audit lifecycle is not 'submitting': ${life:-<none>}"
  out="$(jq -r --argjson i "$i" '.assets[$i].output' "$state")"; [[ "$out" = /* ]] || out="$root/$out"
  [[ ! -e "$out" ]] || die "output exists ($out); asset produced a result, route through QC not reconcile"
  [[ ! -s "$evidence_dir/response.json" ]] || die "non-empty response evidence exists; provider result confirmed — provider reconciliation required"
  if [[ -s "$evidence_dir/response.json" ]]; then
    tid="$(jq -r '.id // .task_id // .data.id // .data.task_id // empty' "$evidence_dir/response.json" 2>/dev/null || true)"
    [[ -z "$tid" ]] || die "response carries task_id ($tid); provider reconciliation required"
  fi
  [[ -e "$evidence_dir/submission.locked" ]] && mv "$evidence_dir/submission.locked" "$evidence_dir/submission.locked.reconciled-submitting"
  ts="$(now)"
  save --argjson i "$i" --arg id "$id" --arg ts "$ts" --arg note "$note" --arg reviewer "$reviewer" --arg evidence "$evidence_dir" '
    .assets[$i].status="ready" |
    del(.assets[$i].submission_started_at,.assets[$i].error_exit_code,.assets[$i].lifecycle_state) |
    .status="gate_open_for_next_authorized_asset" |
    .updated_at=$ts |
    .events += [{at:$ts,type:"reconciled_submitting_no_result",asset_id:$id,cost_yuan:0,billed:false,risk:"synchronous POST interrupted; provider-side billing not observed (empty response, no output, no task_id)",evidence:$evidence,note:$note,reviewer:$reviewer}]
  '
  snap
  echo "$id reconciled from submitting; no confirmed result, committed unchanged, status -> ready"
  ;;
reconcile-failed-task)
  # 吃"任务已在 provider 端创建（带 task_id）、但平台把它判为 failed 且用量为 0"的情况。
  # 与 reconcile-no-post 的区别：那条要求未触达生成/无 task_id；本条专门处理"有 task_id 但平台
  # 明确拒稿/失败、input_seconds==0"——即 provider 侧已确认未按量计费（H3 失败任务不计费）。
  # 门槛比 no-post 更严：必须有 status.json 铁证（task.status=="failed" 且 usage.input_seconds==0），
  # 否则一律拒绝。满足则退回保守计入的 cost（账实相符）、资产复位 ready 可重试。
  # 保守计费在 run-asset 失败分类（本文件 ambiguous_submission 分支）时已 += cost，故复位须退回。
  [[ $# -eq 6 ]] || usage
  id="$3"; evidence_dir="$4"; note="$5"; reviewer="$6"; i="$(idx "$id")" || die "unknown asset"
  [[ -d "$evidence_dir" ]] || die "missing evidence directory: $evidence_dir"
  current="$(jq -r --argjson i "$i" '.assets[$i].status' "$state")"
  [[ "$current" == ambiguous_submission ]] || die "asset is not in ambiguous_submission: $current"
  [[ -s "$evidence_dir/status.json" ]] || die "missing provider status evidence: $evidence_dir/status.json"
  tstatus="$(jq -r '.task.status // .status // empty' "$evidence_dir/status.json" 2>/dev/null || true)"
  isecs="$(jq -r '.task.usage.input_seconds // .usage.input_seconds // empty' "$evidence_dir/status.json" 2>/dev/null || true)"
  [[ "$tstatus" == failed ]] || die "provider status is not 'failed' (got: ${tstatus:-<none>}); cannot treat as unbilled"
  [[ "$isecs" == "0" ]] || die "usage.input_seconds is not 0 (got: ${isecs:-<none>}); provider may have billed — manual reconciliation required"
  out="$(jq -r --argjson i "$i" '.assets[$i].output' "$state")"; [[ "$out" = /* ]] || out="$root/$out"
  [[ ! -e "$out" ]] || die "output exists ($out); task did not actually fail — route through QC"
  perr="$(jq -r '.task.error.message // .error.message // empty' "$evidence_dir/status.json" 2>/dev/null || true)"
  ptask="$(jq -r '.task.id // .id // empty' "$evidence_dir/status.json" 2>/dev/null || true)"
  [[ -e "$evidence_dir/submission.locked" ]] && mv "$evidence_dir/submission.locked" "$evidence_dir/submission.locked.reconciled-failed-task"
  cost="$(jq -r --argjson i "$i" '.assets[$i].cost_yuan' "$state")"
  ts="$(now)"
  save --argjson i "$i" --argjson r "$cost" --arg id "$id" --arg ts "$ts" --arg note "$note" --arg reviewer "$reviewer" --arg evidence "$evidence_dir" --arg perr "$perr" --arg ptask "$ptask" '
    .assets[$i].status="ready" |
    del(.assets[$i].error_exit_code,.assets[$i].lifecycle_state,.assets[$i].submission_started_at) |
    .budget.committed_yuan -= (if .budget.committed_yuan >= $r then $r else 0 end) |
    .authorization.committed_yuan -= (if .authorization.committed_yuan >= $r then $r else 0 end) |
    .status="gate_open_for_next_authorized_asset" |
    .updated_at=$ts |
    .events += [{at:$ts,type:"reconciled_failed_task",asset_id:$id,cost_yuan:0,refunded_yuan:$r,provider_task_id:$ptask,provider_error:$perr,provider_input_seconds:0,evidence:$evidence,note:$note,reviewer:$reviewer}]
  '
  snap
  echo "$id reconciled as provider-failed (task=$ptask, input_seconds=0, unbilled); refunded=$cost; status -> ready"
  ;;
supersede)
  # 把一个"被拒旧版"正规标记为"已被某个已接受资产替换"，供 gate-out 安全忽略它。
  # 不改状态(仍 rejected，付费历史与沉没成本保留)，只加 superseded_by 指针 + 事件。
  # gate-out 只放行"rejected 且 superseded_by 指向一个 accepted 资产"的成员；
  # 真正缺失/未替换的被拒关键帧仍会挡住 gate-out，门不被削弱。
  [[ $# -eq 6 ]] || usage
  rid="$3"; byid="$4"; note="$5"; reviewer="$6"
  ri="$(idx "$rid")" || die "unknown rejected asset: $rid"
  bi="$(idx "$byid")" || die "unknown replacement asset: $byid"
  [[ "$(jq -r --argjson i "$ri" '.assets[$i].status' "$state")" == rejected ]] || die "asset to supersede is not rejected: $rid"
  [[ "$(jq -r --argjson i "$bi" '.assets[$i].status' "$state")" == accepted ]] || die "replacement asset is not accepted: $byid"
  rg="$(jq -r --argjson i "$ri" '.assets[$i].group // ""' "$state")"
  bg="$(jq -r --argjson i "$bi" '.assets[$i].group // ""' "$state")"
  [[ "$rg" == "$bg" ]] || die "group mismatch: $rid($rg) vs $byid($bg)"
  ts="$(now)"
  save --argjson i "$ri" --arg rid "$rid" --arg byid "$byid" --arg ts "$ts" --arg note "$note" --arg reviewer "$reviewer" '
    .assets[$i].superseded_by=$byid |
    .updated_at=$ts |
    .events += [{at:$ts,type:"superseded",asset_id:$rid,superseded_by:$byid,note:$note,reviewer:$reviewer}]
  '
  snap
  echo "$rid marked superseded_by $byid"
  ;;
supersede-accepted)
  # 返工退役：把一个"已 accepted 的旧版关键帧"退役为 rejected+superseded_by（配合 stage 的
  # 返工回退 shot_images_accepted->shot_images_pending 使用）。仅当同组存在一个已 accepted 的
  # 替代资产、且二者产物文件不同才允许。付费历史/沉没成本保留（accepted 时已计费，不退款）。
  # 落地为 status=rejected + superseded_by 是刻意复用下游既有逻辑：gate-out 的 resolved() 已放行
  # "rejected 且 superseded_by->accepted"，sha256 账实校验只扫 accepted，审阅页只排除 rejected，
  # 因此无需改动 gate-out / 审阅构建器。provenance 用 superseded_from_accepted+retired_at 如实留痕。
  [[ $# -eq 6 ]] || usage
  rid="$3"; byid="$4"; note="$5"; reviewer="$6"
  ri="$(idx "$rid")" || die "unknown loser asset: $rid"
  bi="$(idx "$byid")" || die "unknown replacement asset: $byid"
  [[ "$rid" != "$byid" ]] || die "cannot supersede an asset by itself: $rid"
  [[ "$(jq -r --argjson i "$ri" '.assets[$i].status' "$state")" == accepted ]] || die "loser asset is not accepted: $rid"
  [[ "$(jq -r --argjson i "$bi" '.assets[$i].status' "$state")" == accepted ]] || die "replacement asset is not accepted: $byid"
  rg="$(jq -r --argjson i "$ri" '.assets[$i].group // ""' "$state")"
  bg="$(jq -r --argjson i "$bi" '.assets[$i].group // ""' "$state")"
  [[ "$rg" == "$bg" ]] || die "group mismatch: $rid($rg) vs $byid($bg)"
  ro="$(jq -r --argjson i "$ri" '.assets[$i].output // ""' "$state")"
  bo="$(jq -r --argjson i "$bi" '.assets[$i].output // ""' "$state")"
  [[ -n "$ro" && "$ro" != "$bo" ]] || die "loser/replacement share the same output (or empty): $ro"
  ts="$(now)"
  save --argjson i "$ri" --arg rid "$rid" --arg byid "$byid" --arg ts "$ts" --arg note "$note" --arg reviewer "$reviewer" '
    .assets[$i].status="rejected" |
    .assets[$i].superseded_by=$byid |
    .assets[$i].superseded_from_accepted=true |
    .assets[$i].retired_at=$ts |
    .updated_at=$ts |
    .events += [{at:$ts,type:"superseded_accepted",asset_id:$rid,superseded_by:$byid,note:$note,reviewer:$reviewer}]
  '
  assert_state
  snap
  echo "$rid retired (accepted -> rejected) superseded_by $byid"
  ;;
authorize-assets)
  # 为下一阶段"上架"一批新资产 + 提额授权，走 sole-writer 正规写路径。
  # 只追加从未触碰过的新资产(status 强制 ready)、扩授权名单、抬 budget/authorization 上限；
  # 不改任何既有资产的状态/成本/付费历史。护栏：id 不重复、kind 合法、
  # depends_on 必须指向已 accepted 的既有资产、新上限≥已用金额。
  [[ $# -eq 7 ]] || usage
  af="$3"; hard="$4"; inc="$5"; note="$6"; reviewer="$7"
  [[ -f "$af" ]] || die "missing assets file: $af"
  jq -e 'type=="array"' "$af" >/dev/null 2>&1 || die "assets file must be a JSON array"
  jq -e 'all(.[]; has("id") and has("kind") and has("cost_yuan") and has("group") and has("output") and has("prompt_file"))' "$af" >/dev/null 2>&1 \
    || die "each new asset needs: id,kind,cost_yuan,group,output,prompt_file"
  dup="$(jq -r --slurpfile n "$af" '(.assets|map(.id)) as $ex|[$n[0][]|select((.id) as $i|($ex|index($i))!=null)|.id]|join(",")' "$state")"
  [[ -z "$dup" ]] || die "assets already present: $dup"
  badkind="$(jq -r --slurpfile n "$af" '[$n[0][]|select((.kind|IN("image","video","speech"))|not)|.id]|join(",")' "$state")"
  [[ -z "$badkind" ]] || die "invalid kind for: $badkind"
  badep="$(jq -r --slurpfile n "$af" '(.assets|map(select(.status=="accepted")|.id)) as $acc|[$n[0][]|.id as $id|(.depends_on//[])[]|select(($acc|index(.))==null)|"\($id)->\(.)"]|join(", ")' "$state")"
  [[ -z "$badep" ]] || die "depends_on not satisfied by accepted assets: $badep"
  committed="$(jq -r '.budget.committed_yuan' "$state")"
  authc="$(jq -r '.authorization.committed_yuan' "$state")"
  awk "BEGIN{exit !($hard+0>=$committed+0)}" || die "new hard cap ($hard) < committed ($committed)"
  awk "BEGIN{exit !($inc+0>=$authc+0)}"     || die "new increment cap ($inc) < committed ($authc)"
  ts="$(now)"
  save --slurpfile n "$af" --argjson hc "$hard" --argjson ic "$inc" --arg ts "$ts" --arg note "$note" --arg rev "$reviewer" '
    ($n[0]|map(.status="ready")) as $add |
    .assets += $add |
    .authorization.asset_ids = ((.authorization.asset_ids//[]) + ($add|map(.id)) | unique) |
    .budget.hard_cap_yuan=$hc |
    .authorization.increment_cap_yuan=$ic |
    .updated_at=$ts |
    .events += [{at:$ts,type:"authorized_batch",count:($add|length),asset_ids:($add|map(.id)),new_hard_cap_yuan:$hc,new_increment_cap_yuan:$ic,note:$note,reviewer:$rev}]
  '
  assert_state
  snap
  echo "authorized $(jq -r --slurpfile n "$af" '$n[0]|length' "$state" 2>/dev/null || echo '?') new assets; hard_cap -> $hard, increment_cap -> $inc"
  ;;

set-pending-qc)
  # 设 authorization.allow_pending_semantic_qc 开关（sole-writer 正规写路径，不绕过账本）。
  # true=资产可停在 generated_pending_qc 也放行下一条 run-asset：以「人工看公网 HTML」代替我逐件语义 accept
  # （合 only-validate-4-texts）。付费安全门（防重复扣费/余额 exit3/防覆盖/未提交互斥）不受影响，仍在。
  [[ $# -eq 4 ]] || usage
  flag="$3"; note="$4"; reviewer="${5:-claude}"
  [[ "$flag" == true || "$flag" == false ]] || die "flag must be true|false"
  ts="$(now)"
  save --argjson f "$flag" --arg ts "$ts" --arg note "$note" --arg rev "$reviewer" '
    .authorization.allow_pending_semantic_qc=$f |
    .updated_at=$ts |
    .events += [{at:$ts,type:"set_pending_qc",value:$f,note:$note,reviewer:$rev}]
  '
  assert_state
  snap
  echo "allow_pending_semantic_qc -> $flag"
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
deauthorize-ready)
  # 撤销一个"从未生成、从未计费"的 ready 资产：从 .assets 与 .authorization.asset_ids 同时移除。
  # 仅用于清理预授权后未用上的重试槽（如一次重生即成功，多留的 v3/v4 会以 status=ready 卡住 gate-out
  # 的"组内每个授权资产须已解决"判定）。护栏：必须 status==ready、无 submission_started_at / audit_dir /
  # sha256 / 任何以该 id 计费的事件——即绝无付费历史，删除零风险、不动 committed 金额、不动上限。
  [[ $# -eq 5 ]] || usage
  id="$3"; note="$4"; reviewer="$5"
  i="$(idx "$id")" || die "unknown asset: $id"
  a="$(jq -c --argjson i "$i" '.assets[$i]' "$state")"
  [[ "$(jq -r '.status' <<<"$a")" == ready ]] || die "asset is not ready (refusing to deauthorize non-ready): $id"
  jq -e '(.submission_started_at//null)==null and (.audit_dir//null)==null and (.sha256//null)==null' <<<"$a" >/dev/null \
    || die "asset shows generation/paid history; refusing to deauthorize: $id"
  billed="$(jq -r --arg id "$id" '[.events[]?|select(.asset_id==$id and ((.cost_yuan//0)>0))]|length' "$state")"
  [[ "$billed" == "0" ]] || die "asset has billed events; refusing to deauthorize: $id"
  ts="$(now)"
  save --arg id "$id" --arg ts "$ts" --arg note "$note" --arg rev "$reviewer" '
    .assets |= map(select(.id != $id)) |
    .authorization.asset_ids = ((.authorization.asset_ids//[]) | map(select(. != $id))) |
    .updated_at=$ts |
    .events += [{at:$ts,type:"deauthorized_ready",asset_id:$id,note:$note,reviewer:$rev}]
  '
  assert_state
  snap
  echo "$id deauthorized (removed from assets + authorization; no paid history)"
  ;;
*) usage ;;
esac
