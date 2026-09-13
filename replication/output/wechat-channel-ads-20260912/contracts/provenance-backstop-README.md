# 出处不可自证后盾（Provenance Backstop）— INFRA-2

> 落地契约 `production-orchestration-contract.md` §3「出处不可自证后盾（付费单元强制）」与 §4「诚实边界」。
> 本组件只建工具/闸门，不产创作内容。付费单元 T4（生图）/ T5（生视频）受此后盾约束。

## 1. 组成

| 文件 | 作用 |
|---|---|
| `tools/validate-provenance.sh <prompt.json>` | 出处 sidecar 校验器（sidecar 存在 + run_id 在台账合法状态块 + sha 匹配）；**并在末尾调用 `validate-skill-provenance.sh`（INFRA-4 叠加）** |
| `tools/validate-skill-provenance.sh <prompt.json>` | **INFRA-4 流程不可绕过锁（fail-closed，仅对本项目 `prompts/`）**：要求 transcript 库中存在一份**隔离子 agent** transcript 同时 (a) 真调用了 X 所需 skill 且 (b) 写出了 X.json 本文件路径；否则 deny。见 §7。 |
| `tools/hook-paid-gate.sh` | Claude Code **PreToolUse** hook：拦本项目 `prompts/` 下 `--prompt` 的 `generate-image.sh`/`generate-video.sh` 付费调用，独立复跑「模型 validator + 出处校验（含 skill 出处）」，任一失败 → deny |
| `X.provenance.json` | 每个付费提示词 `X.json` 旁的出处 sidecar（约定见 §2） |
| 本 README | 出处约定 + arming（settings 片段）+ **诚实天花板** |

模型 validator（既有、本组件不改、不放宽）：
`replication/tools/validate-h3-prompt-review.sh <f> {image|video}`、
`replication/tools/validate-seedance-prompt-review.sh <f> {image|video}`。

## 2. provenance sidecar 约定（Schema）

付费提示词 `X.json` 旁**同目录同名**写 `X.provenance.json`：

```json
{
  "run_id":              "rid-<任务>-<日期><序>",  // 主 agent 派单时发放、写进 TASKS.md 对应块的 `run-id:` 行
  "dispatched_task_id":  "T4",                    // 该单元在 TASKS.md 的任务ID
  "subagent_session_id": "<执行本单元的子 agent / session id>",
  "authored_at":         "2026-09-13T00:00:00.000Z",  // ISO8601
  "prompt_sha256":       "<64位 hex>"             // 必须 == 该 X.json 的「已评审 sha」
}
```

- **`prompt_sha256` 必须等于** `X.json` 的 `.h3_prompt_review.reviewed_prompt_sha256`
  （若为 seedance 路径则 `.seedance_prompt_review.reviewed_prompt_sha256`）。
  即：出处凭证锚定的是「被评审的那份提示词文本」的哈希；提示词改动后 sha 变、sidecar 即失效。
- 全部 5 个字段非空；`run_id`/`prompt_sha256` 格式受校验（sha 须 64 位）。

## 3. validate-provenance.sh 校验规则

按序校验，任一不满足即非零退出并打印原因：
1. sidecar `X.provenance.json` 存在且为合法 JSON 对象；
2. 5 字段齐全且非空（`prompt_sha256` 为 64 位）；
3. `prompt_sha256` == `X.json` 的已评审 sha；
4. `run_id` 出现在 `contracts/TASKS.md` 某任务块的 `run-id:` 行，
   且该块 `状态:` ∈ {`分派中`, `完成待审`, `已过审`}（`待办`/`打回` 等不放行）。

> 台账路径默认 `<project>/contracts/TASKS.md`，可用环境变量 `PROVENANCE_TASKS_FILE` 覆盖（测试用）。

## 4. hook 行为（fail-safe）

- **只在**命令同时满足以下两点时才介入：
  (i) 调用 `generate-image.sh` 或 `generate-video.sh`；
  (ii) `--prompt` 指向的文件解析后位于**本项目** `prompts/` 目录下。
- 介入时：按脚本名选 asset_type（image/video），镜像 `generate-image.sh` 的 provider/JSON 路由选模型 validator，
  **独立复跑** 模型 validator + `validate-provenance.sh`；任一失败 → **deny**。
- **其余一切**（非 Bash 工具、无关命令、他项目路径、认不出 `--prompt`、无 jq）→ **静默放行**（exit 0，无输出）。
  绝不误杀他项目 / 他命令 / 机器上其它会话。
- deny 输出（三重保险，任一解析路径下结论恒为 block）：
  决策 JSON 同时写 stdout 与 stderr 并 `exit 2`：
  ```json
  {"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny","permissionDecisionReason":"..."},"systemMessage":"..."}
  ```

## 5. Arming（启用 block）—— 主 agent 验收后再做

**本组件不自动 arm。** 交付时未写入任何 settings。经主 agent 验收后，由**用户**把下列片段并入
`/home/ubuntu/ads_skill/.claude/settings.local.json` 的顶层（与现有 `permissions` 同级）。
（不要改机器级 `/home/ubuntu/.claude/settings.json`。）

### 5a. 验收/试运行阶段：env-gated（默认不拦，仅当 `ADS_PAID_GATE=1` 时才拦）

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "timeout": 60,
          "command": "if [ \"$ADS_PAID_GATE\" = \"1\" ]; then bash /home/ubuntu/ads_skill/replication/output/wechat-channel-ads-20260912/tools/hook-paid-gate.sh; else exit 0; fi"
        }
      ]
    }
  ]
}
```
- 未设 `ADS_PAID_GATE` → hook 恒放行（等于未 arm，安全试跑）。
- 设 `ADS_PAID_GATE=1` 后重启 Claude Code → 进入 block 模式。

### 5b. 正式阶段：hard-wired（无条件启用）

```json
"hooks": {
  "PreToolUse": [
    {
      "matcher": "Bash",
      "hooks": [
        {
          "type": "command",
          "timeout": 60,
          "command": "bash /home/ubuntu/ads_skill/replication/output/wechat-channel-ads-20260912/tools/hook-paid-gate.sh"
        }
      ]
    }
  ]
}
```
> settings 改动需**重启 Claude Code** 才生效（hook 在会话启动时加载）。

## 6. 诚实天花板（必须读）

- **非密码学不可伪造**：本项目子 agent 与主 agent **同模型、同机、同一人可触达**。`run_id` 由主 agent（编排者）派发、
  它本就知道每个 run-id，故理论上能自造一份「run_id 对、sha 对」的 sidecar。sidecar 的价值是
  **威慑 + 审计留痕**（谁、何时、哪个 session、对哪份 sha 负责），**不是**「第三方铁证」。
- **hook 的真正保证（INFRA-2 + INFRA-4）**：付费闸门**不可被静默跳过 / 经正常工具路径绕过**——只要 hook 被 arm 且用户持有，
  主 agent 想发付费调用就**必须**过「模型评审 + 出处 sidecar 校验 + **skill 出处校验**」三道。
  - INFRA-2 已保证：发不出「无凭证 / sha 不符 / run-id 不在合法状态」的付费请求。
  - **INFRA-4 再收紧**：现还强制「**该 skill 确在一个隔离子 agent 里真跑过，并在同一份 transcript 里写出了这份 X.json**」。
    仅有对味的 sidecar **不再足够**——主 agent 若**手产**提示词、**跳过** skill（skill 未在任何隔离子 agent transcript 中调用），
    付费路径 **fail-closed 直接 deny**。它把 §0–§2 里的「君子协定」+「sidecar 自证」进一步变成
    「**正常工具路径下、必须真走过 skill 子 agent 流程**」的结构强制。
- **INFRA-4 残余伪造面（诚实、不夸大）**：单模型单机下，这**不是**密码学铁证。要骗过 INFRA-4，主 agent 需
  **手工伪造一整份 JSONL transcript**——里面同时编造「`Skill` 工具调用（`.input.skill==所需 skill`）」+「写出 X.json 精确路径的工具调用」，
  且这两条**记录本身**带 `isSidechain==true`、并**共享同一个非空 `agentId`**（打回后修复：不再是随便凑三条解耦记录即可，
  必须让同一个伪造子 agent 既"跑了 skill"又"写了 X"）——再把它落到 transcript 库（或经 `ADS_TRANSCRIPT_DIR` 指过去）。
  这种伪造是**响亮的、留痕的、故意的**：它要凭空构造平时由 harness 自动写入的运行记录，且这份伪造 transcript 本身即成为「蓄意造假」的证据。
  与 INFRA-2 的「填个 sidecar」相比，作案成本与暴露度都显著抬高——但**并非不可能**，天花板到此为止。
- **绑定编排者的前提（不变）**：hook 脚本、`validate-provenance.sh`、`validate-skill-provenance.sh` 与 settings 必须由**用户 own/lock**
  （用户拥有、主 agent 无写权）。若主 agent 能改这些脚本、`settings.local.json`（含 `ADS_PAID_GATE`）、
  或能自由写 `ADS_TRANSCRIPT_DIR`/伪造 transcript 库，即可自行放宽——那样后盾对编排者不再成立。
- **仍不改既有闸门**：本组件是**叠加**层，`generate-image.sh` 的 exit4 图片门禁、`generate-video.sh` 的 exit3
  余额门禁一律不动、不放宽（见 [[precheck-balance-canary-before-paid-batch]]）。
- **边界残余**：单模型单机下，独立性是「流程上的」（隔离上下文/单元/即毁/transcript 即证据），
  非真·独立第三方审（契约 §4）。本后盾把结构强制补到「正常工具路径 + 必须真走过 skill 子 agent」这一层，天花板即到此为止。

## 7. skill 出处校验（INFRA-4）—— 流程不可绕过锁

`tools/validate-skill-provenance.sh <prompt.json>`，被 `validate-provenance.sh` 末尾调用（故 hook 自动生效）。

**作用域**：**仅对本项目 `prompts/` 下的文件 fail-closed**；文件不在本项目 `prompts/` → fail-safe 放行（exit 0），
不回归 INFRA-2 对他项目/他用途的行为。

**判定所需 skill**（按序）：`.authoring_skill` → `.h3_prompt_review.skill` → `.seedance_prompt_review.skill`
→ 若 `.model=="MiniMax-H3"` 或含 `.h3_prompt_review` 则 `h3-prompt-writing`。本项目付费提示词判不出所需 skill → **deny**。

**通过条件**：在 transcript 库中找到一份 transcript，其中**同一个非空 `agentId`（隔离子 agent）**同时满足：
- (a) 有真实 `Skill` 工具调用，`tool_use.name=="Skill"` 且 `.input.skill==所需 skill`，且**该记录本身**为隔离子 agent（`isSidechain==true` 或 `agentId` 非空）；
- (b) 有写出 X.json **精确路径**的工具调用：`Write/Edit/NotebookEdit` 的 `input.file_path` 等于/以该路径结尾，
  或任一 `Bash` 命令串包含该路径（覆盖 gen 脚本/重定向/generate-*.sh 落盘），且**该记录本身**为隔离子 agent；
- (c) (a) 与 (b) 的两条记录**同属一个非空 `agentId`**（同一子 agent 既跑了 skill 又写了这份文件）。

> **【打回后修复 rid-infra4-20260913b】** 前版把 (a)/(b)/隔离性三条**在同一文件内彼此解耦**地判定，
> 导致「主会话自身 `isSidechain==false` 的 Skill 调用 + 主会话自身的写 X + 任一无关 `isSidechain==true` 记录」
> 被误判 pass（= 主 agent 在自己上下文里加载 skill 并手写提示词即可绕过）。现改为**按 `agentId` 聚合求交集**，
> 要求存在一个非空 `agentId` 同时命中 (a) 与 (b)；并**删除**「文件位于 `subagents/`/`tasks/` 目录即自动满足隔离性」
> 这个过松捷径——主会话 jsonl 亦被扫入，目录位置不构成证明，隔离性必须来自记录自身的 `isSidechain`/`agentId`。

三条缺一 → **deny（exit 1）**。

**transcript 库动态定位**（绝不写死 session-id；重启后 session-id 变）：
1. `ADS_TRANSCRIPT_DIR`（若设置：递归其下 `*.jsonl`/`*.output`，测试/fixture 用）；
2. `${CLAUDE_PROJECTS_DIR:-$HOME/.claude/projects}` 下所有 `slug/*/subagents/*.jsonl` 与 `slug/*/tasks/*.output`（跨所有 session 并集）；
3. `/tmp/claude-1000/<slug>/<session>/tasks/*.output`（symlink→JSONL 镜像）。

因绑定要求写出 X.json 的**精确路径**（项目唯一），跨 slug 搜索不会误命中他项目。

**真实 JSONL schema（本机勘察所得）**：
- `isSidechain` 与 `agentId` 是**记录顶层字段**（不在 `.message` 内）。主会话记录：`isSidechain==false`、`agentId==null`；
  隔离子 agent 记录：`isSidechain==true`、`agentId`=非空（与 `subagents/agent-<id>.jsonl` 文件名一致）。
- Skill 调用行：`{"type":"assistant", "isSidechain":true, "agentId":"<id>", "message":{"content":[{"type":"tool_use","name":"Skill","input":{"skill":"<名>"}}]}}`。
  （可用技能清单在 `type=="attachment"` 记录里也含 `"Skill"` 字样，但**不是** `tool_use`，本校验只认 `type=="assistant"` 的 `tool_use`。）
- 写文件行：`...{"type":"tool_use","name":"Write","input":{"file_path":"<绝对路径>","content":"..."}}`（Read/Edit 同用 `input.file_path`；Bash 用 `input.command`）。
- **绑定实现**（jq）：先逐行 `fromjson? // empty` 得容错记录流，再 `-s` 聚合：分别取「名下有 req_skill Skill 调用的非空 agentId 集合」
  与「名下有写出 X 精确路径的非空 agentId 集合」，二者**交集非空**即 pass（同一子 agent 既跑 skill 又写 X）。
