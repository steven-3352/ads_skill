#!/usr/bin/env bash
# validate-skill-provenance.sh <prompt.json>
#
# 出处强化闸门（INFRA-4）——「流程不可绕过锁」。
# 在 INFRA-2 的 sidecar 校验之上再叠加一条 **fail-closed** 规则：
#   对本项目 prompts/ 下的付费提示词 X.json，必须能在 transcript 库中找到
#   **同一份隔离子 agent transcript** 同时满足：
#     (a) 真调用了 X 对应的 skill（Skill 工具 tool_use，.input.skill == 所需 skill）；
#     (b) 该 transcript 里有写出 X.json **本文件路径** 的工具调用
#         （Write/Edit/NotebookEdit 的 file_path，或任一 Bash 命令串包含该路径）；
#     (c) (a) 与 (b) 出自**同一个隔离子 agent**：产生 Skill 调用的记录**本身**
#         `isSidechain==true`（或 `agentId` 非空），写出 X 的记录**本身**也如此，
#         且二者**同属一个非空 `agentId`**（同一子 agent 既跑了 skill 又写了这份文件）。
#   三者缺一 → deny（非零退出）。这把「主 agent 手产提示词、跳过 skill」堵在付费路径上：
#   跳过 skill 就没有满足 (a)&(b) 且绑定到同一子 agent 的 transcript，付费闸门即拦下。
#
#   【打回后修复 rid-infra4-20260913b】前版把 (a)/(b)/(c) 在同一文件内**彼此解耦**地判定，
#   导致「主会话自身 isSidechain==false 的 Skill 调用 + 主会话自身的写 X + 任一无关 isSidechain==true
#   记录」被误判 pass。现改为：按 agentId 聚合，要求**存在一个非空 agentId**同时满足
#   (a-in-subagent) 与 (b-in-subagent)；并**删除**「文件位于 tasks//subagents/ 目录即自动满足 (c)」
#   的过松捷径（主会话 jsonl 亦被扫入，目录位置不构成证明）。
#
# 作用域（不回归 INFRA-2）：
#   - **仅对本项目 `prompts/` 下的文件 fail-closed**；
#   - 其它项目 / 非本项目路径 / 判不出所需 skill 之外的情形 → fail-safe 放行（exit 0）。
#
# transcript 库定位（**动态**，绝不写死 session-id；重启后 session-id 会变）：
#   1. 环境变量 `ADS_TRANSCRIPT_DIR`（若设置：递归其下所有 *.jsonl / *.output，测试/fixture 用）；
#   2. `${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}` 下所有 slug/*/subagents/*.jsonl 与
#      slug/*/tasks/*.output（跨所有 session 目录，取并集）；
#   3. `/tmp/claude-1000/<slug>/<session>/tasks/*.output`（symlink→JSONL 的镜像）。
#   —— 因绑定要求「写出 X.json 的**精确路径**」，该路径本身即项目唯一，跨 slug 搜索不会误命中他项目。
#
# 诚实边界：单模型单机下这不是密码学铁证；残余伪造 = 手工伪造一整份含
#   「Skill 调用 + 写 X 路径 + isSidechain」的 JSONL transcript（响亮 / 留痕 / 故意）。
#   详见 contracts/provenance-backstop-README.md §6。
set -Eeuo pipefail

[[ $# -eq 1 ]] || { echo "usage: validate-skill-provenance.sh <prompt.json>" >&2; exit 2; }
prompt_file="$1"
[[ -f "$prompt_file" ]] || { echo "skill-provenance gate: 缺少提示词文件: $prompt_file" >&2; exit 1; }
command -v jq >/dev/null || { echo "skill-provenance gate: 需要 jq" >&2; exit 1; }

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
PROMPTS_DIR="$(realpath -m -- "$PROJECT_DIR/prompts" 2>/dev/null || echo "$PROJECT_DIR/prompts")"
PROJECT_BASENAME="$(basename -- "$PROJECT_DIR")"   # wechat-channel-ads-20260912

Xabs="$(realpath -m -- "$prompt_file" 2>/dev/null || echo "$prompt_file")"

# ---- 作用域闸门：只对本项目 prompts/ 下的文件 fail-closed；其余 fail-safe 放行 ----
if [[ "$Xabs" != "$PROMPTS_DIR"/* ]]; then
  echo "skill-provenance gate: 非本项目 prompts/（$Xabs），fail-safe 放行"
  exit 0
fi

Xbase="$(basename -- "$Xabs")"
Xtail="$PROJECT_BASENAME/prompts/$Xbase"   # 项目唯一相对尾段，用于匹配 Bash/相对路径写法

# ---- 判定 X 所需 skill ----
req_skill="$(jq -r '
  .authoring_skill
  // .h3_prompt_review.skill
  // .seedance_prompt_review.skill
  // (if (.model == "MiniMax-H3") or (.h3_prompt_review != null) then "h3-prompt-writing" else empty end)
  // empty
' "$prompt_file" 2>/dev/null || true)"

if [[ -z "$req_skill" ]]; then
  # 本项目付费路径判不出所需 skill → fail-closed（宁可拦错，不可放过）
  echo "skill-provenance gate: DENY —— 本项目 prompts/ 付费提示词无法判定所需 skill (.authoring_skill/.h3_prompt_review.skill/.model 均缺): $Xbase" >&2
  exit 1
fi

# ---- 动态汇集候选 transcript 根 ----
roots=()
[[ -n "${ADS_TRANSCRIPT_DIR:-}" && -d "${ADS_TRANSCRIPT_DIR}" ]] && roots+=("$ADS_TRANSCRIPT_DIR")
PROJECTS_DIR="${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}"
[[ -d "$PROJECTS_DIR" ]] && roots+=("$PROJECTS_DIR")
[[ -d "/tmp/claude-1000" ]] && roots+=("/tmp/claude-1000")

if [[ ${#roots[@]} -eq 0 ]]; then
  echo "skill-provenance gate: DENY —— 找不到任何 transcript 库根（ADS_TRANSCRIPT_DIR / $PROJECTS_DIR / /tmp/claude-1000 均不可用）" >&2
  exit 1
fi

# ---- 收集候选文件（跟随 symlink；.output 常为 → JSONL 的 symlink）----
# 先用 grep 预筛：文件须同时提到所需 skill 与 X 的精确路径，缩小到少量再精校。
mapfile -t candidates < <(
  find -L "${roots[@]}" -type f \( -name '*.jsonl' -o -name '*.output' \) 2>/dev/null \
    | sort -u
)

# 单份 transcript 精校：同一文件内，**存在一个非空 agentId**，其名下既有
#   (a) req_skill 的 Skill 工具调用（该记录本身为隔离子 agent）
#   且 (b) 写出 X 路径的工具调用（该记录本身为隔离子 agent）。
# 即把 (a)(b) 绑定到**同一个隔离子 agent**（同一 agentId），杜绝跨记录解耦误判。
transcript_proves() {
  local f="$1"
  # 预筛（快速淘汰）：必须同时含 skill 名与 X 路径字面
  grep -Fq -- "$req_skill" "$f" 2>/dev/null || return 1
  grep -Fq -- "$Xabs" "$f" 2>/dev/null || grep -Fq -- "$Xtail" "$f" 2>/dev/null || return 1

  # 两段式：先逐行 fromjson 得干净记录流（容忍坏行），再 -s 聚合按 agentId 求交集。
  # isSidechain / agentId 均为**记录顶层字段**（本机勘察确认）：
  #   主会话记录 isSidechain==false, agentId==null；隔离子 agent 记录 isSidechain==true, agentId=<非空>。
  local proved
  proved="$(
    jq -R 'fromjson? // empty' "$f" 2>/dev/null | jq -s \
      --arg s "$req_skill" --arg xa "$Xabs" --arg xt "$Xtail" '
      # 隔离子 agent 记录：本身 isSidechain==true 或 agentId 非空，且 agentId 非空（绑定需要共享 agentId）
      def sub_aid:
        select(.type=="assistant")
        | select((.isSidechain==true) or (((.agentId // "")|type=="string") and ((.agentId // "")|length>0)))
        | (.agentId // "")
        | select(type=="string" and length>0);

      # (a) 名下有 req_skill 的 Skill tool_use 的子 agent agentId 集合
      ( [ .[]
          | select(((.message.content?) // []) | type=="array")
          | select(any(.message.content[]?;
                        .type=="tool_use" and .name=="Skill" and ((.input.skill // "")==$s)))
          | sub_aid
        ] | unique ) as $skill_aids
      # (b) 名下有写出 X 精确路径的 tool_use 的子 agent agentId 集合
      | ( [ .[]
          | select(((.message.content?) // []) | type=="array")
          | select(any(.message.content[]?;
                        .type=="tool_use"
                        and ( ((.input.file_path // "" | tostring) == $xa)
                           or ((.input.file_path // "" | tostring) | endswith($xt))
                           or ((.input.command   // "" | tostring) | contains($xa))
                           or ((.input.command   // "" | tostring) | contains($xt)) )))
          | sub_aid
        ] | unique ) as $write_aids
      # 交集非空 → 同一非空 agentId 既跑 skill 又写 X
      | [ $skill_aids[] | select(. as $a | any($write_aids[]; . == $a)) ]
      | (length > 0)
    ' 2>/dev/null
  )"
  [[ "$proved" == "true" ]] || return 1
  return 0
}

for f in "${candidates[@]}"; do
  if transcript_proves "$f"; then
    echo "skill-provenance gate: pass (skill=$req_skill 在隔离子 agent transcript 中真跑过并写出 $Xbase; transcript=$f)"
    exit 0
  fi
done

echo "skill-provenance gate: DENY —— 未找到任何隔离子 agent transcript，其**同一个非空 agentId**既「调用 skill=$req_skill」又「写出 $Xtail」。付费路径 fail-closed：疑似主 agent 手产/跳过 skill。搜索根: ${roots[*]}" >&2
exit 1
