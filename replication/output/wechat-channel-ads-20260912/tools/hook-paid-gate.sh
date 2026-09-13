#!/usr/bin/env bash
# hook-paid-gate.sh — PreToolUse 付费闸门 hook（INFRA-2 出处后盾）
#
# 作用：在 Claude Code 真正执行 Bash 命令之前拦一道。仅当命令是
#   「本项目 prompts/ 下 --prompt 文件的 generate-image.sh / generate-video.sh 付费调用」时，
#   本 hook 独立复跑「模型评审 validator + validate-provenance.sh」；任一失败 → deny（挡下付费调用）。
# 对其它一切命令（他项目、他命令、无关 Bash）→ 静默放行（fail-safe：绝不误杀）。
#
# Claude Code PreToolUse hook 约定：
#   - stdin 是 JSON，含 .tool_name 与（Bash 时）.tool_input.command。
#   - 放行：无输出、exit 0。
#   - 拦截：输出 deny 决策 JSON 到 stdout，并 exit 2（stderr 作为原因）——双保险，
#     无论宿主按「JSON 决策」还是「exit code 2」解析，结论都恒为 block、绝不误判成 allow。
#
# 归属：本文件须由用户 own/lock（仓库内、用户可控），主 agent 无权改、无权绕，
#   否则对编排者不成立。诚实边界见 contracts/provenance-backstop-README.md。
set -Eeuo pipefail

# ---- 本项目锚点（写死，避免被 cwd 影响）----
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"          # .../wechat-channel-ads-20260912
PROMPTS_DIR="$PROJECT_DIR/prompts"
# 模型 validator 位于仓库 replication/tools/（付费入口脚本同目录）
GEN_TOOLS_DIR="$(cd -- "$PROJECT_DIR/../../tools" && pwd 2>/dev/null || echo "$PROJECT_DIR/../../tools")"
VALIDATE_H3="$GEN_TOOLS_DIR/validate-h3-prompt-review.sh"
VALIDATE_SEEDANCE="$GEN_TOOLS_DIR/validate-seedance-prompt-review.sh"
VALIDATE_PROVENANCE="$SCRIPT_DIR/validate-provenance.sh"

allow() { exit 0; }   # fail-safe 放行：无输出

deny() {
  # $1 = 原因
  local reason="PreToolUse 付费闸门拦截: $1"
  # 三重保险：
  #   - hookSpecificOutput.permissionDecision=deny + permissionDecisionReason（官方 docs 结构化路径）
  #   - systemMessage（hook-development skill 示例字段）
  #   - 决策 JSON 同时写 stdout 与 stderr，并 exit 2（exit code 2 恒为 block）
  # 无论宿主按哪种方式解析，结论都恒为 deny，绝不误判成 allow。
  local json
  if command -v jq >/dev/null 2>&1; then
    json="$(jq -nc --arg r "$reason" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: $r
      },
      systemMessage: $r
    }')"
  else
    local esc; esc="$(printf '%s' "$reason" | sed 's/\\/\\\\/g; s/"/\\"/g')"
    json="{\"hookSpecificOutput\":{\"hookEventName\":\"PreToolUse\",\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"$esc\"},\"systemMessage\":\"$esc\"}"
  fi
  printf '%s\n' "$json"          # stdout（exit-0 结构化解析路径）
  printf '%s\n' "$json" >&2      # stderr（exit-2 解析路径）
  exit 2
}

# ---- 读 stdin ----
STDIN_JSON="$(cat || true)"
[[ -n "$STDIN_JSON" ]] || allow
command -v jq >/dev/null 2>&1 || allow   # 无 jq 无法判定 → fail-safe 放行（付费脚本自身仍有门禁）

tool_name="$(printf '%s' "$STDIN_JSON" | jq -r '.tool_name // empty' 2>/dev/null || true)"
[[ "$tool_name" == "Bash" ]] || allow

command_str="$(printf '%s' "$STDIN_JSON" | jq -r '.tool_input.command // empty' 2>/dev/null || true)"
[[ -n "$command_str" ]] || allow

# ---- 只对 generate-image.sh / generate-video.sh 生效 ----
asset_type=""
if printf '%s' "$command_str" | grep -Eq '(^|[/[:space:]])generate-image\.sh([[:space:]]|$)'; then
  asset_type="image"
elif printf '%s' "$command_str" | grep -Eq '(^|[/[:space:]])generate-video\.sh([[:space:]]|$)'; then
  asset_type="video"
else
  allow
fi

# ---- 提取 --prompt / --prompt=... 的取值 ----
# 支持: --prompt X | --prompt=X | --prompt "X" | --prompt 'X'
prompt_arg=""
prompt_arg="$(printf '%s' "$command_str" | grep -oE -- "--prompt(=|[[:space:]]+)('[^']*'|\"[^\"]*\"|[^[:space:]]+)" | head -1 || true)"
[[ -n "$prompt_arg" ]] || allow   # 认不出 --prompt → fail-safe 放行（付费脚本自身 usage 会拦）
# 去掉前缀 --prompt / --prompt= 及引号
prompt_val="${prompt_arg#--prompt}"
prompt_val="${prompt_val#=}"
prompt_val="${prompt_val#"${prompt_val%%[![:space:]]*}"}"   # ltrim
prompt_val="${prompt_val%\"}"; prompt_val="${prompt_val#\"}"
prompt_val="${prompt_val%\'}"; prompt_val="${prompt_val#\'}"
[[ -n "$prompt_val" ]] || allow

# ---- 解析为绝对路径，判定是否在本项目 prompts/ 下 ----
resolved=""
if [[ "$prompt_val" == /* ]]; then
  resolved="$(realpath -m -- "$prompt_val" 2>/dev/null || echo "$prompt_val")"
else
  # 相对路径：分别尝试相对 PROJECT_DIR 与 PROMPTS_DIR；否则退回字面判定
  if [[ -e "$PROJECT_DIR/$prompt_val" ]]; then
    resolved="$(realpath -m -- "$PROJECT_DIR/$prompt_val" 2>/dev/null || echo "")"
  elif [[ -e "$PROMPTS_DIR/$prompt_val" ]]; then
    resolved="$(realpath -m -- "$PROMPTS_DIR/$prompt_val" 2>/dev/null || echo "")"
  fi
fi

in_project=0
PROMPTS_DIR_RESOLVED="$(realpath -m -- "$PROMPTS_DIR" 2>/dev/null || echo "$PROMPTS_DIR")"
if [[ -n "$resolved" && "$resolved" == "$PROMPTS_DIR_RESOLVED"/* ]]; then
  in_project=1
elif printf '%s' "$prompt_val" | grep -Fq "wechat-channel-ads-20260912/prompts/"; then
  # 字面包含本项目 prompts 路径（相对/含中间段），保守视为本项目
  in_project=1
  [[ -n "$resolved" ]] || resolved="$prompt_val"
fi
[[ "$in_project" -eq 1 ]] || allow   # 非本项目付费调用 → fail-safe 放行

# 到这里：确认是本项目付费调用。下面独立复跑门禁；文件缺失/校验失败 → deny。
PF="$resolved"
[[ -f "$PF" ]] || deny "提示词文件不存在或不可读: $prompt_val (resolved=$resolved)"

# ---- 选模型 validator（镜像 generate-image.sh 的路由）----
provider=""
if printf '%s' "$command_str" | grep -Eq -- "--provider(=|[[:space:]]+)minimax"; then
  provider="minimax"
elif printf '%s' "$command_str" | grep -Eq -- "--provider(=|[[:space:]]+)seedance"; then
  provider="seedance"
fi

run_model_validator() {
  if [[ "$provider" == "minimax" ]]; then
    "$VALIDATE_H3" "$PF" "$asset_type"
  elif [[ "$provider" == "seedance" ]]; then
    "$VALIDATE_SEEDANCE" "$PF" "$asset_type"
  elif [[ "$asset_type" == "video" ]]; then
    # 视频默认 H3（镜像 generate-video.sh）
    "$VALIDATE_H3" "$PF" "$asset_type"
  else
    # 图片：H3 优先，其次 seedance（镜像 generate-image.sh）
    if jq -e '(.h3_prompt_review != null) or (.model == "MiniMax-H3") or (.authoring_skill == "h3-prompt-writing")' "$PF" >/dev/null 2>&1; then
      "$VALIDATE_H3" "$PF" "$asset_type"
    elif jq -e '.seedance_prompt_review != null' "$PF" >/dev/null 2>&1; then
      "$VALIDATE_SEEDANCE" "$PF" "$asset_type"
    else
      return 3
    fi
  fi
}

# 复跑模型评审门禁
if [[ ! -x "$VALIDATE_H3" ]]; then deny "找不到模型 validator: $VALIDATE_H3"; fi
model_out=""; model_rc=0
model_out="$(run_model_validator 2>&1)" || model_rc=$?
if [[ $model_rc -ne 0 ]]; then
  deny "模型评审门禁未过 ($asset_type): ${model_out:-rc=$model_rc}"
fi

# 复跑出处 sidecar 校验
[[ -x "$VALIDATE_PROVENANCE" ]] || deny "找不到出处校验器: $VALIDATE_PROVENANCE"
prov_out=""; prov_rc=0
prov_out="$("$VALIDATE_PROVENANCE" "$PF" 2>&1)" || prov_rc=$?
if [[ $prov_rc -ne 0 ]]; then
  deny "出处校验未过: ${prov_out}"
fi

# 全过 → 放行
allow
