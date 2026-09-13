# 任务台账（Task Ledger）—— 唯一协作总线

> 规则见 `contracts/production-orchestration-contract.md` §1.5。
> 主 agent 写：新建/更新任务块、验收(已过审/打回)。子 agent 只读**自己那一个任务块**、只回填自己这一块的「交付/provenance/自述」，**禁止改别的块**。
> 状态取值：`待办 | 分派中 | 完成待审 | 已过审 | 打回`。
> HTML 由 `build-review-html` 从本文件 + 产物派生（见契约 §2.5）。

---

## 阶段 0：基础设施（directive 2，先做稳做牢）

### [INFRA-1] 修正 H3 项目图片门禁路由  ·  状态: 已过审
- 执行者: 子agent（机械改脚本，不产创作内容）
- run-id: rid-infra1-20260913a
- 输入(最小相关):
  - `/home/ubuntu/ads_skill/replication/tools/generate-image.sh`（当前第 56 行硬编码 `"$BASE_DIR/validate-seedance-prompt-review.sh" "$PROMPT_FILE" image`）
  - `/home/ubuntu/ads_skill/replication/tools/validate-h3-prompt-review.sh`（已支持 `<f> image`，校验 `h3_prompt_review`）
  - `/home/ubuntu/ads_skill/replication/tools/generate-video.sh` 第 54-57 行（**参考它已有的正确路由写法**：seedance→seedance 校验器，否则→h3 校验器）
- 输出(定死): 只改 `generate-image.sh` 那一行门禁，改为**按提示词 JSON 自动选校验器、非回归**：
  - 若 JSON 含 `.h3_prompt_review`（或 `.model=="MiniMax-H3"` / `.authoring_skill=="h3-prompt-writing"`）→ 调 `validate-h3-prompt-review.sh "$PROMPT_FILE" image`；
  - 否则若含 `.seedance_prompt_review` → 调 `validate-seedance-prompt-review.sh "$PROMPT_FILE" image`（保持 Seedance 项目不回归）；
  - 可选 `--provider minimax|seedance` 覆盖自动判断（与 generate-video.sh 风格一致，但默认走自动判断）。
  - 其余逻辑（exit1 防覆盖、exit4 插入门禁、audit）**一律不动**。
- 约束/SOP: 00 元数据 line 20「不得用 Seedance 字段/校验替代」；契约 §3；不得放宽任何现有闸门。
- 验收判据(主agent): 用一个含 `h3_prompt_review` 的样例 JSON 跑门禁应 pass H3 分支；含 `seedance_prompt_review` 的应仍走 seedance 分支；缺失两者应 fail。
- 分派: 主agent @2026-09-13
— 交付(子agent回填): 改 `replication/tools/generate-image.sh`：新增 `PROVIDER=""`(旧 line17 后)与 `--provider` 解析(case 内)；把旧第 56 行硬编码 seedance 门禁替换为按 JSON 自动选校验器的路由块(新 line56-72)——`--provider minimax|seedance` 覆盖 > `.h3_prompt_review`/`.model==MiniMax-H3`/`.authoring_skill==h3-prompt-writing` 走 H3 > `.seedance_prompt_review` 走 seedance > 否则 exit2。exit1 防覆盖 / exit4 插入门禁 / audit 逻辑均未改动。
— provenance(子agent回填): run-id rid-infra1-20260913a · 执行者 子agent(隔离机械单元, model claude-opus-4-8, generate-image.sh 门禁路由单元)
— 自述(子agent回填): 已实测三分支——含 `h3_prompt_review`/`.model==MiniMax-H3` 走 h3-prompt-writing 校验器、含 `seedance_prompt_review` 走 seedance-prompt-zh 校验器、两者皆缺 exit2 明确报错，`--provider` 可正确覆盖，未放宽任何现有闸门。
— 验收(主agent回填): 已过审 @2026-09-13。主 agent 独立复核：①代码检视 precedence 正确(--provider>H3自测>seedance>exit2)、exit1/exit4/audit 未动；②实跑三分支——合规 H3 JSON 得 `h3 prompt gate: pass (image, h3-prompt-writing)` 后停在防覆盖(未触发生成)、seedance-only 走 seedance 校验器、无块 exit2。非回归确认。

### [INFRA-2] provenance/run-id 校验 + PreToolUse hook（付费闸门）  ·  状态: 已过审
- 执行者: 子agent（机械建工具/hook，不产创作内容）
- run-id: rid-infra2-20260913a
- 输入(最小相关):
  - `generate-image.sh` / `generate-video.sh`（付费入口；INFRA-1 已修好图片门禁路由）
  - `validate-h3-prompt-review.sh` / `validate-seedance-prompt-review.sh`
  - 项目 hook/settings 位置（先确认 `/home/ubuntu/ads_skill/.claude/settings.local.json` 与 `/home/ubuntu/.claude/settings.json`）
- 输出(定死):
  1. **provenance sidecar 约定**：付费提示词 `X.json` 旁写 `X.provenance.json` = `{run_id, dispatched_task_id, subagent_session_id, authored_at, prompt_sha256}`；`prompt_sha256` 须等于该 JSON 的 reviewed sha。
  2. **`validate-provenance.sh <prompt.json>`**：校验 sidecar 存在、`run_id` 出现在 `contracts/TASKS.md` 某任务块的 `run-id:` 行且该块状态∈{分派中,完成待审,已过审}、`prompt_sha256` 匹配；否则非零退出。
  3. **PreToolUse hook 脚本**：拦截 Bash 里对本项目 `prompts/` 下 `--prompt` 的 `generate-image.sh`/`generate-video.sh` 调用，独立复跑「模型 validator + validate-provenance.sh」，任一失败→deny 并给原因。**fail-safe**：不匹配本项目付费调用的命令一律 allow（绝不误杀他项目/他命令/机器上其它会话）。
  4. **不自动 arm 成 block**：先交付脚本 + 一个显式开关（env 或 settings 片段），并附 dry-run 证明；由主 agent 验收后再决定何时启用 block 模式。
  5. 一份 `contracts/provenance-backstop-README.md`：写明**诚实天花板**（单模型单机、编排者知道 run-id 故 sidecar 非密码学不可伪造；hook 的真保证是"门禁不可被绕过/静默跳过 + 审计留痕"，非"铁证"）＋ 用户需自行 own/lock hook 文件才对编排者成立。
- 约束/SOP: 契约 §3/§4；不得破坏 exit3 余额门禁 [[precheck-balance-canary-before-paid-batch]]；不得放宽现有闸门。
- 验收判据(主agent): dry-run——合规(sidecar+run-id 对)→allow；缺 sidecar/伪 run-id/sha 不符→deny；他项目/无关命令→allow(不误杀)。
- 分派: 主agent @2026-09-13
— 交付(子agent回填):
  - `tools/validate-provenance.sh`（出处 sidecar 校验器：sidecar 存在+5字段+run_id 在台账合法状态块+sha 匹配）
  - `tools/hook-paid-gate.sh`（PreToolUse 付费闸门 hook：fail-safe，仅拦本项目 prompts/ 下 generate-image/video.sh 付费调用，复跑 模型validator+validate-provenance，失败 deny/exit2，其余静默放行）
  - provenance sidecar 约定 `X.provenance.json`=`{run_id,dispatched_task_id,subagent_session_id,authored_at,prompt_sha256}`（schema 见 README）
  - `contracts/provenance-backstop-README.md`（sidecar schema + settings arming 片段[env-gated 5a / hard-wired 5b，未自动 arm]+ 诚实天花板）
  - dry-run 已过：合规→allow(exit0)；缺sidecar/伪run-id/sha不符→deny(exit2+决策JSON)；无关命令/他项目/非Bash→allow(不误杀)
— provenance(子agent回填): run-id rid-infra2-20260913a；执行者=隔离子agent(INFRA-2，机械建工具/hook，未产创作内容、未跑付费)
— 自述(子agent回填): 交付出处 sidecar 约定+validate-provenance.sh+PreToolUse 付费闸门 hook（fail-safe、不自动 arm、不放宽既有 exit3/exit4 门禁），dry-run 六例全绿。
— 验收(主agent回填): 已过审 @2026-09-13。主 agent 独立 dry-run 七例全绿：①合规(有效 sidecar+台账内 run-id+sha 匹配)→allow(exit0)；②缺 sidecar→deny；③伪 run-id→deny(报"未出现在台账")；④sha 非64位→deny(格式)；⑤64位但不符→deny(报 sidecar vs reviewed sha)；⑥非Bash/无关bash/他项目 generate 调用→全 allow(exit0，无误杀)。文件均可执行；未改任何 settings（机器 settings.json mtime 未变、ads_skill/.claude 无改动）；exit3/exit4 未动。诚实天花板 README 已在案。**hook 未 arm——需用户 own/lock hook 脚本+settings 片段后才对主 agent 结构成立（见 §4 诚实边界）。**

### [INFRA-3] build-review-html 确定性构建器  ·  状态: 已过审
- 执行者: 子agent（机械建工具，不产创作内容）
- run-id: rid-infra3-20260913a
- 输入(最小相关):
  - 产物目录约定：`stories/`(剧本/分镜 md)、`prompts/`(提示词 JSON)、`PP/shots/shot-SS/images/*.png`、`PP/shots/shot-SS/video/*.mp4`、`edit/PP-final.mp4`
  - 本文件 `contracts/TASKS.md`（派生每单元状态）
  - 服务地址 `https://www.tonbird.top/ads-review/wechat-channel-ads-20260912/`、媒体走相对路径不入库 [[no-media-in-repo]]
  - 参考现有构建器 `/home/ubuntu/ads_skill/replication/tools/build-output-review.mjs` 的写法
- 输出(定死): `build-review-html`（脚本），扫产物 + 读 TASKS.md 重生成项目评审 HTML（放项目根/review 下），满足契约 §2.5「可见标准」：剧本 md 渲染、提示词文本可见、图片内嵌、视频 `<video>` 可播、成片+收尾字幕/时长/成本可见、每单元状态可见。确定性、可重复跑、不手写 HTML 内容。
- 约束/SOP: 契约 §2.5；媒体相对路径不入库。
- 分派: —
— 交付(子agent回填): 构建器 `tools/build-review-html.mjs`（项目内 `tools/` 目录）；输出 `review/index.html`（单页，媒体相对路径引用）。运行：`node tools/build-review-html.mjs`（cwd 无关，脚本按自身位置定位项目根）。
— provenance(子agent回填): run-id rid-infra3-20260913a；session 1aa0b253-8d39-48ca-8d5d-ef34e9bbd77c（隔离子 agent，机械建工具，未生成任何媒体、未提交）。
— 自述(子agent回填): 纯 Node 无依赖、确定性幂等地扫 stories/prompts/(NN|顶层)shots/edit + 解析 TASKS.md，渲染剧本 md、提示词文本、内嵌图片、可播视频、成片+收尾字幕/时长/成本与每单元状态到 review/index.html。
— 验收(主agent回填): 已过审 @2026-09-13。主 agent 独立复核：①连跑两次 sha256 字节一致(幂等)；②`(src|href)` 无 `/home`/`/tmp`/`file:` 绝对路径泄漏，媒体全走 `../` 相对；③HTML 引用的 82 张图/视频实存(missing=0)；④任务面板含 INFRA-1/2/3+REMEDIATE-1 状态、03 成片 36s/¥7.20 可见。符合契约 §2.5 可见标准。

### [INFRA-4] 出处校验强化：验证 skill 真在隔离子 agent 里跑过（流程不可绕过锁）  ·  状态: 已过审
- 执行者: 子agent（机械建工具，不产创作内容）
- run-id: rid-infra4-20260913b（前次 rid-infra4-20260913a 打回）
- 输入(最小相关):
  - `tools/validate-provenance.sh`（现只查 sidecar 字段+run_id 在台账+sha 匹配）
  - `tools/hook-paid-gate.sh`（PreToolUse 付费闸门，已调 validate-provenance.sh）
  - 付费提示词 JSON 的 `authoring_skill`/`h3_prompt_review.skill`（= 该产物应由哪个 skill 产出）
  - 子 agent transcript 存储位置需**自行勘察**：本会话 tasks 目录形如 `/tmp/claude-1000/<项目slug>/<session-id>/tasks/<agentId>.output`（symlink 到 JSONL）；勘察真实 JSONL 里「Skill 工具调用」与「写文件工具调用(Write/输出到某路径)」两类记录的结构
- 输出(定死): 给出处校验**叠加一条 fail-closed 规则**（改 `validate-provenance.sh` 或新增被它/hook 调用的 `validate-skill-provenance.sh`）：对某付费提示词 X.json，必须能在 transcript 库中找到**一个隔离子 agent transcript**同时满足 (a) 真调用了 X 对应 skill（H3 图/视频＝`h3-prompt-writing`；从 X 的 `authoring_skill`/review.skill 读取所需 skill 名）**且** (b) 该 transcript 里有写出 **X.json 本文件路径**的工具调用；找不到→**deny（fail-closed，付费路径宁可拦错不可放过）**。
  - session 目录须**动态定位**（重启后 session-id 会变；用 env/最新目录等稳妥法，别写死当前 id）。
  - 更新 `contracts/provenance-backstop-README.md` 诚实天花板：现强制「skill 确在隔离子 agent 里跑过并产出了这份文件」，残余伪造＝手工伪造一整份 transcript（响亮/留痕/故意）。
  - 不动 exit3/exit4；对**非付费**路径与他项目仍 fail-safe 放行（本条 fail-closed 只作用于本项目 prompts/ 下的付费调用）。
- 约束/SOP: 契约 §3/§4；[[real-lock-means-process-not-bypassable]]；[[main-agent-orchestrator-only]]；不得放宽既有闸门。
- 验收判据(主agent): dry-run——①有一份「真调过对应 skill 且写了该 X.json」的 transcript → pass；②有 sidecar 但**无**此类 transcript（模拟主 agent 手产、跳过 skill）→ deny 并给原因；③他项目/非付费命令仍 allow。
- 分派: 主agent @2026-09-13
— 交付(子agent回填): **【打回后修复 rid-infra4-20260913b】** 修补 `transcript_proves()` 的结构性漏洞（(a)/(b)/隔离性三条在同一文件内彼此解耦、目录位置即算隔离，导致「主会话自产 + 任一无关子agent记录」误判 pass）。
  - 改写 `tools/validate-skill-provenance.sh` 的 `transcript_proves()`：两段式 jq——先逐行 `fromjson? // empty` 得容错记录流，再 `-s` 聚合按 **agentId 求交集**。分别取「名下有 `Skill` tool_use(`.input.skill==所需 skill`)且该记录本身为隔离子agent(`isSidechain==true` 或 `agentId` 非空)的**非空 agentId 集合**」与「名下有写出 X.json 精确路径 tool_use 且本身为隔离子agent 的**非空 agentId 集合**」，二者**交集非空**才 pass。即把 (a)(b) 绑定到**同一个非空 agentId**（同一子agent既跑skill又写该文件）。
  - **删除**过松捷径：原「文件位于 `subagents/`/`tasks/` 目录即自动满足隔离性」已移除（主会话 jsonl 亦被扫入，目录位置不构成证明）；隔离性只来自记录自身的 `isSidechain`/`agentId`。
  - 更新 `contracts/provenance-backstop-README.md` §6/§7：通过条件改为「同一非空 agentId 命中 (a)&(b)」、真实 schema 注明 `isSidechain`/`agentId` 为记录**顶层字段**（主会话 false/null，子agent true/非空）、残余伪造面改为「须伪造同一 agentId 既跑skill又写X的两条 isSidechain==true 记录」。
  - 未改：作用域(仅本项目 prompts/ fail-closed、他项目/非付费 fail-safe)、动态定位(`ADS_TRANSCRIPT_DIR` 覆盖仍有效)、`validate-provenance.sh` 末尾调用链、exit3/exit4、settings(未 arm)。未产创作内容、未跑付费。
  - 五例 dry-run 全绿(用 `ADS_TRANSCRIPT_DIR` 指向临时 fixture，测试后已清理)：TEST1(手产/默认根,无fixture)→DENY(exit1)；TEST2(prompts/外 contracts/TASKS.md)→ALLOW(exit0)；TEST3(**回归**:主会话 isSidechain==false 的 Skill+Write(X精确路径)+无关 isSidechain==true 记录)→**DENY(exit1)**(前版误判 pass,现堵住)；TEST4(同一非空 agentId 既 Skill 又 Write X)→PASS(exit0)；TEST5(agentId A 跑 Skill、agentId B 写 X,同文件)→DENY(exit1,证同agentId绑定)。
— provenance(子agent回填): run-id rid-infra4-20260913b（前次 rid-infra4-20260913a 打回）；执行者=隔离子 agent(INFRA-4 post-打回修复单元，机械建工具，model claude-opus-4-8)，session=1aa0b253-8d39-48ca-8d5d-ef34e9bbd77c(CLAUDE_CODE_SESSION_ID)。真实 JSONL schema 本机勘察确认：`isSidechain`/`agentId` 均为记录**顶层字段**——主会话 assistant 记录 `isSidechain==false`/`agentId==null`，隔离子 agent 记录 `isSidechain==true`/`agentId`=非空(与 `subagents/agent-<id>.jsonl` 文件名一致)；Skill 调用=`type=="assistant"` 行 `.message.content[]|select(.type=="tool_use" and .name=="Skill").input.skill`(attachment 技能清单不算)；写文件=`tool_use.name==Write/Edit` 的 `.input.file_path` 或 Bash 的 `.input.command`。
— 自述(子agent回填): 修复主 agent 打回的结构性漏洞——原来 skill调用/写X/隔离性三条只需在同一文件内各自出现即可(还把目录位置当隔离证明)，主 agent 在自己上下文里加载 skill 并手写提示词、同会话恰有任意子agent记录就能绕过。现按 agentId 求交集，强制「**同一个隔离子 agent 既真跑了所需 skill 又写出了这份 X.json**」才放行，并删掉目录捷径。回归+新增五例 dry-run 证明 TEST3(病根反例)已由误判 pass 变为 DENY，TEST5 证同agentId绑定，其余四项行为不变。
— 验收(主agent回填): **打回 @2026-09-13。** 主 agent 独立 adversarial dry-run 发现**结构性漏洞**：`transcript_proves()` 把 (a)Skill调用 / (b)写X路径 / (c)隔离子agent 三条**在同一文件内彼此解耦地**判定，未要求出自同一子agent记录。实测反例(TEST 3)：一份含①主会话自身 `isSidechain==false` 的 `Skill(h3-prompt-writing)` 调用 + ②主会话自身 `isSidechain==false` 的 `Write(X精确路径)` + ③任一条无关的 `isSidechain==true` 记录 的 transcript → **误判 pass**。即「主 agent 在自己上下文里加载 skill 并亲手写提示词、同会话恰有任意子agent记录」就能绕过——正是本锁要堵的病根。**必须修**：把 (a) 与 (b) 绑定到子agent上下文——证明用的 `Skill` 调用记录**本身** `isSidechain==true`(或 `agentId` 非空)，且写 X 的记录**本身**也 `isSidechain==true`(或 `agentId` 非空)，二者**同属一个非空 `agentId`**(同一子agent既跑了skill又写了该文件)；删掉「文件位于 tasks//subagents/ 目录即自动满足(c)」这个过松捷径(主会话 jsonl 亦被扫入)。回归判据：TEST 1(手产)仍 deny、TEST 4(真子agent同agentId跑skill+写文件)仍 pass、**新增 TEST 3(主会话自产+无关子agent记录)必须 deny**。其余(作用域/动态定位/README/不动exit3+4)保留。
  **重做 b 已过审 @2026-09-13。** 主 agent 独立复核：①代码检视——`transcript_proves()` 改为两段式 jq，求「名下有 req_skill 的 Skill tool_use 的**子agent** agentId 集合」∩「名下有写出 X 精确路径的**子agent** agentId 集合」，交集非空(同一非空 agentId 既跑 skill 又写该文件)才 pass；目录捷径已删。②adversarial dry-run 六例全绿：T1 手产→deny、T2 prompts/外→allow、**T3 旧漏洞反例(主会话自产 isSidechain:false skill+write ＋无关子agent记录)→现 deny**、T4 同一 agentId 跑skill+写文件→pass、T5 skill/写分属两 agentId→deny、T6 skill由主/写由子agent→deny。作用域/动态定位/exit3+4 未回归。**流程不可绕过锁成立（诚实天花板：残余伪造=手工伪造整份含 Skill+写X+同 agentId 的 JSONL，响亮/留痕/故意）。**

### [REMEDIATE-1] 纠正历史伪造出处标记  ·  状态: 已过审
- 执行者: 子agent（机械核对+标注，不产创作内容）
- run-id: rid-remediate1-20260913a
- 输入(最小相关):
  - 历史关键帧提示词 JSON：`prompts/01-*.json 02-*.json 04-*.json 05-*.json 06-*.json`（含被主 agent 手填的 `authorship:"generated_by_skill"`/`result:"pass"` 与 `seedance_prompt_review{skill:"seedance-prompt-zh"}`）
  - 生成器 `tmp/gen-*.js`（自盖章来源）
  - 契约 §3、§4；00 元数据 line 20
- 输出(定死): 把这些历史 JSON 的 review 章如实降级为「未经技能生成/待重做」的标记（不是删证据、是停止冒充"生成前通过"）；产出一份 `contracts/remediation-report.md` 列清哪些文件被标记、为何、后续如何重走 S2/S3。**不得再自盖任何 `generated_by_skill`。**
- 约束/SOP: 三-skill-SOP §112「历史生成记录不得事后补签为生成前通过」。
- 分派: 主agent @2026-09-13
— 交付(子agent回填): `contracts/remediation-report.md`；relabeled 65 个历史关键帧 JSON(01:13 / 02:15 / 04:15 / 05:11 / 06:11，共 130 个 review 章降级为 `hand_filled_unverified`+`not_generated_by_skill`+`remediation_note`)；另给 6 个自盖章生成器(gen-01/02/04/05/06-keys.js、gen-hooks.js)加顶部不可信声明。未动任何 03-* 与生成 03 的 gen-s02*/gen-s3-s9.js；prompt 文本与 reviewed_prompt_sha256 全部逐字节保留(65/65 sha 校验一致)。
— provenance(子agent回填): run-id rid-remediate1-20260913a；agent=remediate1-subagent(isolated)，session=unknown(env 未暴露 CLAUDE_SESSION_ID)。仅机械核对+标注，未产创作内容、未跑生成、未重签。
— 自述(子agent回填): 如实把 01/02/04/05/06 历史手填的伪"生成前通过"标记降级为待重做(不删证据)，其余字段与 03 试点保持原样。
— 验收(主agent回填): 已过审 @2026-09-13。主 agent 独立复核：①65 个在案 JSON 全 hand_filled_unverified+not_generated_by_skill+remediation_note，在案 `generated_by_skill` 残留=0；②65/65 recompute sha256(.prompt)==reviewed sha(prompt 文本零改动)；③抽样 02/05 提示词现被 validate-h3-prompt-review.sh 正确拒绝(不再冒充过审)；④03 试点 22 个仍 generated_by_skill/pass、0 remediation_note、未被动；⑤6 个在案自盖生成器加不可信声明、4 个 03-only 生成器未动；报告 contracts/remediation-report.md 在案。历史诚实债已清。

---

## 阶段 1：商品 01 试点（directive 1，基础设施+纠错通过后）
> 保留现有 01 关键帧（`01/shots/shot-0N/images/first.png`＋02/03/04/07 的 `last.png`；关键帧提示词 `prompts/01-hook.json`、`prompts/01-shot-0N-first/last.json` 一律不动），按隔离子 agent 流程生成 9 条 H3 视频 + 合成成片，判断"保留原图后的视频质量"。
> 商品：**优勤吸盘花洒支架 1I**（喜剧/动作·事件驱动/后期烧字幕无 TTS）。拍摄脚本唯一事实源 `stories/01-1i-shooting-script.md`；事实卡 `01-产品事实与核验边界.md` 的「01」。
> 镜头模式：shot-02/03/04/07=**FL2VA**（取下/按入/卡入等状态·位置变化，摆落点+逐动词，见 [[fl2va-for-state-change-actions]]）；shot-01/05/06/08/09=I2VA。

### [P01-T3c] 生成 01 的 9 条视频提示词  ·  状态: 已过审
- 执行者: **全新隔离子 agent**（真调 `h3-prompt-writing`；主 agent 不产内容）
- run-id: rid-p01t3c-20260913a
- 输入(最小相关，勿多给)：
  - `stories/01-1i-shooting-script.md`（逐镜 verbatim 事实源：驱动四层/买点/逐镜内容/对白/声音设计/事实闸门）
  - `01-产品事实与核验边界.md` 的「01」段（事实闸门：可确认的结构卖点，禁绝对化承重/墙面承诺）
  - 现有关键帧路径：`01/shots/shot-0N/images/first.png`（全 9 镜）＋ `01/shots/shot-{02,03,04,07}/images/last.png`（FL2VA 尾帧）
  - skill：`h3-prompt-writing`（H3 图/视频提示词唯一作者技能；**必须真在本子 agent 里调用**，INFRA-4 会验）
- 输出(定死)：`prompts/01-shot-0N-video.json`（N=01..09，共 9 个），每个含：
  - `model:"MiniMax-H3"`、`authoring_skill:"h3-prompt-writing"`（供 validator/skill-provenance 路由）
  - `mode`：shot-02/03/04/07=`FL2VA`（引用 first+last 关键帧、写死摆落点与逐动词）；其余=`I2VA`（引用 first）
  - `duration_seconds`：≥4（H3 下限 4s 计费，见 [[minimax-h3-min-4s-billing]]）
  - 运动描述按该镜"动作节点"逐拍写（取下—按紧—卡入/滑倒/捡起等），非匀速无快切；单镜内留微运镜
  - 选角锁 **East Asian/中国人**，中老年家庭+成年子女（[[daihuo-casting-must-be-chinese]]）；面部可入画（喜剧需表情）
  - 商品 100% 还原：商品位**留干净给后期贴真图**，**不得**让模型生成包装/logo 小字；02/04/07 近景与 09 英雄镜按"母版还原/img2img"标准，远距可略糊（脚本 line53）
  - **画面无烧字幕**：对白后期 drawtext，H3 只出环境+拟音、画面保持干净（[[h3-dialogue-burns-subtitles-nondeterministic]]）——提示词显式约束"no on-screen text/subtitles/caption"
  - `h3_prompt_review{skill,result,reviewed_prompt_sha256}` 由 skill 如实填（**不得主 agent 手盖**）
  - 同时为每个 X.json 写 **出处 sidecar** `X.provenance.json`={run_id:rid-p01t3c-20260913a, dispatched_task_id:"P01-T3c", subagent_session_id:<本子agent session>, authored_at, prompt_sha256=该 X 的 reviewed sha}
- 约束/SOP：契约 §2.5/§3；不产 TTS；不虚构价格质保；不出绝对化表述；主 agent 只验收/打回不代笔。
- 验收判据(主agent)：①9 个 JSON 齐、mode 与 FL2VA 名单一致、duration≥4；②`validate-h3-prompt-review.sh <f> video` 全 pass；③skill-provenance：`validate-skill-provenance.sh` 对 9 个全 pass（证明确由隔离子 agent 真调 skill 写出）；④选角/商品留位/无烧字幕/事实闸门抽检合规；⑤HTML 重建可见 9 条视频提示词文本。
- 分派: 主agent @2026-09-13（隔离子 agent，真调 h3-prompt-writing）
— 交付(子agent回填): 9 个 `prompts/01-shot-0N-video.json`(N=01..09)+ 各自 `X.provenance.json`。FL2VA={02,03,04,07}(首尾对齐 0.00/4.00s+摆落点+逐动词)，其余 I2VA(引 first)；均 dur=4/9:16/768P/audio=true/watermark=false；每条 prompt 末尾 clean-frame 无字幕 clause；对白不入 H3、拟音在 overall_soundscape；商品位 no logo/brand/packaging 留干净；选角 East Asian/中国人(05/09 无人镜合理无)。`h3_prompt_review` 由 skill 流程产出、sha=对 .prompt 求值并与 sidecar 一致。
— provenance(子agent回填): run-id rid-p01t3c-20260913a；执行者=隔离子 agent(agentId a410ace143490b85d, isSidechain=true, model claude-opus-4-8)，subagent_session_id 81b46c75-144e-4042-bbbb-ad08ff794cea；真调 `h3-prompt-writing`(Skill 工具)后写出 9 文件。
— 自述(子agent回填): 按 h3-prompt-writing base 模式逐镜写(I2VA/FL2VA)，逐镜内容取自 01-1i-shooting-script.md，未生成任何媒体、未改关键帧/事实源/TASKS.md。抛出关键帧缺口(shot-02/07 last.png 缺、shot-05/06 有多余 last.png)供主 agent 在 T5 前修复。
— 验收(主agent回填): 已过审 @2026-09-13。主 agent 独立复核:①validate-h3(video) 9/9 pass；②validate-skill-provenance(INFRA-4) 9/9 pass(同一非空 agentId 既调 skill 又写该文件)；③mode 与 FL2VA 名单一致、dur=4/9:16/audio；④业务抽检——选角中国人(有人镜全含 East Asian/Chinese、05/09 无人合理)、无烧字 clause 9/9、商品位否定式留干净、FL2VA 首尾对齐句在 02/03/04/07、09 英雄镜下三分之一留空给收尾字幕；⑤sidecar 5 字段齐+run-id 在台账合法状态+sha 匹配。**遗留(不属提示词错误、转 T5 前置):FL2VA 的 shot-02/shot-07 缺 last.png 关键帧，shot-05/06 有多余 last.png(I2VA 不用、无害)——见 P01-T4b。**

### [P01-T4b] 补渲 FL2VA 缺失尾帧关键帧（shot-02 / shot-07 last.png）  ·  状态: 作废(误报)
> **【2026-09-13 主 agent 撤销 —— 基于 stale-tree 误判】** 本块与其"关键帧缺口"前提均系**看错关键帧树**所致的伪任务。项目存在两棵并行树:
>   - 旧废树 `shots/shot-0N/images/`(08:41 起,内含厨房空玻璃杯等**错产品**帧 + `*-backup`/`*-discard` 废件;02/07 曾缺 last、05/06 有多余 last)——T3c 子 agent 与本块当时都误指向它;
>   - **正确树 `01/shots/shot-0N/images/`(14:40–14:54 那批)**:9 镜 14 帧齐全且内容正确(吸盘花洒/工具支架、中国选角、场景逐字对、FL2VA 首尾终态正确),FL2VA {02,03,04,07} 的 first+last **本就都在**、无多余 last。
> 主 agent 已逐帧亲验正确树 14 帧全部合规(见 T5 前置核验)。故 FL2VA 尾帧无缺口,本块无需执行。先前往旧废树渲的 2 张 last(¥0.5)为沉没成本,不影响正确树,不再使用。**结论:试点前提「保留现有 01 关键帧」成立。**
> ~~T3c 揭示:FL2VA 的 shot-02/07 无 last.png…(前提作废)~~
- 执行者: 免费部分=全新隔离子 agent(真调 `h3-prompt-writing` 写图片提示词);付费部分=隔离子 agent 机械调 `generate-image.sh`
- run-id: rid-p01t4b-20260913a
- 输入(最小相关)：`stories/01-1i-shooting-script.md` 的 02/07 段(尾帧=喷头已卡稳松手/扫帚柄已卡稳直立松手的**终态**);`shots/shot-02/images/first.png`、`shots/shot-07/images/first.png`(母版·同室同人同商品位,尾帧须场景连续);事实卡「01」;skill `h3-prompt-writing`
- 输出(定死)：重写 `prompts/01-shot-02-last.json`、`prompts/01-shot-07-last.json`(asset_type=image,`h3_prompt_review.authorship=generated_by_skill`,sha 自洽)+ 各自 `X.provenance.json`(run-id rid-p01t4b-20260913a,dispatched_task_id P01-T4b);经门禁后**文生图**渲出 `shots/shot-02/images/last.png`、`shots/shot-07/images/last.png`(商品位留干净、无 logo/包装字、选角同 first、East Asian、面部同人;终态姿势;9:16/768×1344)
- 约束/SOP：契约 §3;文生图不用 img2img(generate-image.sh exit4,[[img2img-edits-overpreserves-portrait-magnet]]);商品100%还原留位;估价 2×¥0.25=¥0.5;先金丝雀(渲 02-last)见拒即停
- 验收判据(主agent)：①2 张 last.png 存在、9:16、与 first 场景/人/商品位连续、终态正确;②图片门禁 validate-h3(image)+skill 出处 pass;③无烧字/无品牌;④T5 的 FL2VA images 引用不再 MISSING
- 分派: 主agent @2026-09-13（免费重写先行）

### [P01-T5] 生成 01 的 9 条 H3 视频（付费）  ·  状态: 完成待审(业务)
- 执行者: 隔离子 agent（机械调 `generate-video.sh`，不产创作内容）
- run-id: rid-p01t5-20260913a
- 前置：P01-T3c 已过审；付费 hook 已 arm(settings.local.json 5b 硬接);查余额+金丝雀（[[precheck-balance-canary-before-paid-batch]]）。**关键帧就绪核验(主 agent 已亲验):正确树 `01/shots/shot-0N/images/` 9 镜 14 帧齐全且内容合规;shot-01 模型/出处/skill 三门禁 dry-run 全 pass。**
- 输入(最小相关)：9 个 `prompts/01-shot-0N-video.json`＋其 sidecar；**关键帧走正确树 `01/shots/`(勿用旧废树 `shots/`)**；`generate-video.sh`
- **关键帧喂入(定死):** 提示词 JSON 的 `.images` 仍指向旧废树 `shots/`(不改,以保 sha/出处不变);渲染时**每镜用 `--reference` 覆盖为正确树 `01/shots/` 路径**——I2VA 传 1 张 `01/shots/shot-0N/images/first.png`;FL2VA{02,03,04,07} 按序传 `first.png` 再 `last.png`(role 依序 first_frame/last_frame)。`--reference` 覆盖 `.images` 且**不改 `.prompt`,故不动 sha、不破门禁/出处**。
- 输出(定死)：`01/shots/shot-0N/video/*.mp4`（9 条）；顺序生成、见拒即停（exit3 余额门禁）
- 约束/SOP：估价 9×4s×¥0.2=**¥7.2 起**（受项目 costCap ¥70 约束）；付费闸门三道（模型评审+出处 sidecar+skill 出处）必须全过；不放宽任何门禁；**金丝雀先渲 shot-01,主 agent 视觉 QC(运动/商品位不崩/中国选角/无烧字)+报账后再批量余 8**
- 验收判据(主agent)：①9 条 mp4 存在且时长≥4s；②每条画面无烧字幕、选角为中国人、商品位可后期贴图、FL2VA 有正确状态变化；③成本记账；④HTML 可播放 9 条
- 分派: 主agent @2026-09-13（隔离子 agent；金丝雀 shot-01 先行）
- **交付 @2026-09-13:** 9 条 mp4 全部落 `01/shots/shot-0N/video/shot-0N-response.mp4`，均 768×1344 / 9:16 / 4.458s（计费按 4s 下限）。金丝雀 shot-01 先渲+QC 通过后批量余 8，8/8 成功。
- **成本记账:** 9 镜 × 4s × ¥0.2 = **¥7.2**（金丝雀 ¥0.8 + 批量 ¥6.4），落在 costCap ¥70 内。付费三门（模型评审+出处 sidecar+skill 出处）全程未放宽。
- **视觉 QC(主 agent 亲验 PNG 抽帧，非信 ls/路径):**
  - shot-01 I2VA ✓；shot-02 FL2VA ✓ 爸爸对准卡口→喷头卡入松手搬花盆(兑现)；shot-03 FL2VA ✓ 握支架→整只取下墙留吸印；
  - shot-04 FL2VA ✓ 妈妈按支架→花洒卡入、腾手挤沐浴露(核心兑现①)；shot-05 I2VA ✓ 走廊扫帚倚墙(痛点铺垫，滑倒幅度偏弱、可后期截运动帧)；
  - shot-06 I2VA ✓ 女儿捡帚目光落向墙上支架(承接)；shot-07 FL2VA ✓ 扫帚柄对准卡口→卡稳直立(核心兑现②)；
  - shot-08 I2VA ✓ 妈妈立客厅回眸(选角、无烧字)；shot-09 I2VA ✓ 花洒卡入吸盘支架英雄特写(商品还原到位)。
  - **业务硬线全过:** 状态变化 FL2VA 四镜均演到位；全片选角为中国人；商品位清晰可后期贴图；**9 条无一烧录字幕**([[h3-dialogue-burns-subtitles-nondeterministic]] 风险镜本轮未触发)。
- 待办(不阻塞 T6): `node tools/build-review-html.mjs` 重建 HTML 使 9 条可播。
- **业务待审要点(交用户):** ①带货兑现三连(02/04/07)是否够劲；②shot-05 滑倒幅度偏弱是否需重渲(¥0.2)；③选角/商品还原/观感是否符合要求。

### [P01-T6] 合成 01 成片  ·  状态: 完成待审(业务)
- 执行者: 隔离子 agent（机械剪辑/合成，不产创作内容）
- run-id: rid-p01t6-20260913a
- 前置：P01-T5 已过审
- 输入(最小相关)：9 条 clip mp4；`stories/01-1i-shooting-script.md` 的「三连兑现回现」「对白」「收尾字幕」「声音设计」段；后期字幕字体 Noto CJK
- 输出(定死)：`edit/01-final.mp4`——按动作节点剪（覆盖/快切非幻灯片，[[coverage-continuity-editing-vs-slideshow]]）；02/04/07 各截 0.5–0.7s 快切成三连兑现；后期 drawtext 烧对白(S1/S2/S3/S6/S7/S8)+收尾买点字幕；loudnorm 统一；无 TTS
- 约束/SOP：[[ai-live-action-no-slideshow-sop]]（共享锚点/微运镜/统一调色/按动作节点拆）；[[align-voice-to-picture-not-overlay]]；媒体不入库（[[no-media-in-repo]]）
- 验收判据(主agent)：①成片可播、时长落在脚本预期；②三连兑现+对白字幕+收尾字幕在位；③无幻灯片感、无慢感五因；④成本/时长在 HTML 可见
- 分派: 待 P01-T5 过审后分派
- **交付 @2026-09-13:** `edit/01-final.mp4` — 768×1344/9:16/30fps/25.04s/H.264 yuv420p/AAC 48k 立体声(loudnorm I=-16)。12 段按动作节点硬切(非幻灯片):01-08 逐镜裁到动作节拍 + 02/04/07 尾段快切三连兑现 + 09 英雄镜收尾。字幕 drawtext(NotoSansCJK,textfile 免转义)。
- **验收(主 agent 亲抽 6 帧读像素):** 6 段对白(S1/S2/S3/S6/S7/S8)verbatim 在位、长句折两行、白字半透黑底底部;收尾主句两行+品牌小字于下方干净区。中文全渲染无豆腐/乱码、无串字、画面不变形。三连兑现无字幕干净。**事实闸门合规**(收尾无绝对化承重/墙面承诺)。
- **待用户观感终审:** 节奏/喜剧感/带货兑现力度、shot-05 滑倒偏弱是否影响观感。
