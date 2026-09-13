#!/usr/bin/env bash
# validate-provenance.sh <prompt.json>
#
# 出处后盾校验器（INFRA-2）。校验一个付费提示词 JSON 旁的 provenance sidecar：
#   1. sidecar 文件 `X.provenance.json`（与 `X.json` 同目录同名）存在且为合法 JSON；
#   2. sidecar 含非空 run_id / dispatched_task_id / subagent_session_id / authored_at / prompt_sha256；
#   3. sidecar.run_id 出现在 contracts/TASKS.md 某任务块的 `run-id:` 行，
#      且该任务块状态 ∈ {分派中, 完成待审, 已过审}；
#   4. sidecar.prompt_sha256 == 该提示词 JSON 的「已评审 sha」
#      （.h3_prompt_review.reviewed_prompt_sha256 或 .seedance_prompt_review.reviewed_prompt_sha256）。
# 任一不满足 → 非零退出并打印原因到 stderr。
#
# 说明：本脚本只做「出处凭证」校验，不替代模型评审门禁
#   （validate-h3-prompt-review.sh / validate-seedance-prompt-review.sh）。
#   付费入口应两者都过。诚实边界见 contracts/provenance-backstop-README.md。
set -Eeuo pipefail

[[ $# -eq 1 ]] || { echo "usage: validate-provenance.sh <prompt.json>" >&2; exit 2; }
prompt_file="$1"
[[ -f "$prompt_file" ]] || { echo "provenance gate: 缺少提示词文件: $prompt_file" >&2; exit 1; }
command -v jq >/dev/null || { echo "provenance gate: 需要 jq" >&2; exit 1; }

# 定位 contracts/TASKS.md：本脚本位于 <project>/tools/，台账在 <project>/contracts/TASKS.md
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
TASKS_FILE="${PROVENANCE_TASKS_FILE:-$PROJECT_DIR/contracts/TASKS.md}"
[[ -f "$TASKS_FILE" ]] || { echo "provenance gate: 找不到任务台账: $TASKS_FILE" >&2; exit 1; }

# sidecar 路径：X.json -> X.provenance.json（若无 .json 后缀则直接追加）
if [[ "$prompt_file" == *.json ]]; then
  sidecar="${prompt_file%.json}.provenance.json"
else
  sidecar="${prompt_file}.provenance.json"
fi
[[ -f "$sidecar" ]] || { echo "provenance gate: 缺少出处 sidecar: $sidecar" >&2; exit 1; }
jq -e 'type == "object"' "$sidecar" >/dev/null 2>&1 || { echo "provenance gate: sidecar 非合法 JSON 对象: $sidecar" >&2; exit 1; }

# 校验 sidecar 必填字段齐全且非空
jq -e '
  (.run_id | type == "string" and length > 0) and
  (.dispatched_task_id | type == "string" and length > 0) and
  (.subagent_session_id | type == "string" and length > 0) and
  (.authored_at | type == "string" and length > 0) and
  (.prompt_sha256 | type == "string" and length == 64)
' "$sidecar" >/dev/null 2>&1 || { echo "provenance gate: sidecar 字段缺失或非法 (需 run_id/dispatched_task_id/subagent_session_id/authored_at/prompt_sha256[64位])" >&2; exit 1; }

run_id="$(jq -r '.run_id' "$sidecar")"
claimed_sha="$(jq -r '.prompt_sha256' "$sidecar")"

# 取提示词 JSON 的「已评审 sha」（H3 优先，其次 seedance）
reviewed_sha="$(jq -r '
  .h3_prompt_review.reviewed_prompt_sha256
  // .seedance_prompt_review.reviewed_prompt_sha256
  // empty
' "$prompt_file")"
[[ -n "$reviewed_sha" ]] || { echo "provenance gate: 提示词 JSON 无 reviewed_prompt_sha256（缺评审块）: $prompt_file" >&2; exit 1; }

# sidecar.prompt_sha256 必须等于提示词 JSON 的已评审 sha
[[ "$claimed_sha" == "$reviewed_sha" ]] || {
  echo "provenance gate: prompt_sha256 与提示词已评审 sha 不符 (sidecar=$claimed_sha reviewed=$reviewed_sha)" >&2
  exit 1
}

# run_id 必须出现在 TASKS.md 某任务块的 `run-id:` 行，且该块状态 ∈ 允许集合
#   任务块头形如: ### [ID] 名称  ·  状态: 分派中
#   run-id 行形如: - run-id: rid-infra2-20260913a
allowed_status="$(awk -v rid="$run_id" '
  # 记录当前任务块状态（遇到新的 ### 头刷新）
  /^###[[:space:]]/ {
    cur_status = ""
    if (match($0, /状态:[[:space:]]*([^ \t]+)/, m)) { cur_status = m[1] }
    # 兼容无 \t 情况，取 状态: 之后到行尾去空白
    else if (idx = index($0, "状态:")) {
      s = substr($0, idx + length("状态:"))
      gsub(/[[:space:]]/, "", s)
      cur_status = s
    }
    next
  }
  # run-id 行：包含目标 rid 视为命中（作为独立词/子串均可，需精确等值判断）
  /run-id:/ {
    line = $0
    sub(/^.*run-id:[[:space:]]*/, "", line)
    gsub(/[[:space:]]/, "", line)
    if (line == rid) { print cur_status; found=1; exit }
  }
  END { if (!found) exit 0 }
' "$TASKS_FILE")"

if [[ -z "$allowed_status" ]]; then
  echo "provenance gate: run_id 未出现在任务台账的任何 run-id: 行: $run_id ($TASKS_FILE)" >&2
  exit 1
fi

case "$allowed_status" in
  分派中|完成待审|已过审) : ;;
  *)
    echo "provenance gate: run_id=$run_id 所属任务块状态为「$allowed_status」，不在允许集合{分派中,完成待审,已过审}" >&2
    exit 1
    ;;
esac

# ---- INFRA-4 叠加：skill 流程不可绕过锁（fail-closed，仅对本项目 prompts/ 生效）----
# 校验「所需 skill 确在隔离子 agent 里跑过并写出了这份 X.json」。
# validate-skill-provenance.sh 自身对非本项目 prompts/ 的文件 fail-safe 放行，故此处无条件调用即可，
# 不回归 INFRA-2 对他项目/他用途的行为。
SKILL_PROV="$SCRIPT_DIR/validate-skill-provenance.sh"
if [[ -x "$SKILL_PROV" ]]; then
  "$SKILL_PROV" "$prompt_file" || {
    echo "provenance gate: skill 出处校验未过（见上）" >&2
    exit 1
  }
else
  echo "provenance gate: 找不到 skill 出处校验器: $SKILL_PROV" >&2
  exit 1
fi

echo "provenance gate: pass (run_id=$run_id 状态=$allowed_status sha=$reviewed_sha)"
