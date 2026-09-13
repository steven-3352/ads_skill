# 生产编排契约（Production Orchestration Contract）

> 本契约对本项目一切生产步骤具有强制约束，优先级高于「赶进度」等任何理由。
> 起因：主 agent 曾把 SOP 三段压成模板脚本 + 自盖 `generated_by_skill` 章，绕过分工与独立复审。
> 本契约用「架构」而非「自律」来锁住 SOP：没有任何执行者能攒齐三个角色。

## 0. 角色铁律

### 主 agent（唯一常驻、有状态）
只允许做四类动作，**其余一律禁止**：
1. **Intake**：项目启动时与用户对话，问全做视频所缺线索（选品/路线/钩子/卖点/情绪/形式发散/事实边界/预算/约束/人物casting），信息不足不开工。
2. **编任务单**：把生产拆成一串**单元任务**，每条显式定义 `输入 → 输出`，任务间靠输出文件衔接。
3. **调用/分派**：用 `Bash` 跑脚本/命令；用 `Agent`（**全新隔离子 agent，禁止 fork**）分派每一个单元任务。
4. **监控/验收/打回**：对照 项目约束 + SOP 链路 + 闸门 + 经验记忆 逐条核；合规才放行，不合规**打回子 agent 重做**。

**主 agent 明令禁止：**
- 用 `Write`/`Edit` 产出任何**交付内容**（剧本、分镜文案、图片/视频提示词、字幕文案）。Write/Edit 仅限**总控工件**（本契约、任务单、检查清单、成本账、provenance 记录、intake）。
- 「顺手帮子 agent 改一下」——检查发现问题**只打回、不亲手改**（亲手改=三角重新合并成一人，是翻车病根）。
- 用 `subagent_type: "fork"`（fork 继承主上下文，违背隔离）。

### 子 agent（一次性、无状态、隔离）
- 每个单元任务**单独启动一个全新子 agent**；
- **不继承主 agent 上下文**：只拿到「本单元的输入白名单 + 指令」，看不到整段对话；
- 只**机械执行本单元**：不发挥、不跨步、不合并别的任务；
- 完成、交回输出文件后**立即销毁**：不复用、不留状态、不被 SendMessage 拉回接别的活（那等于恢复上下文）。下一个单元另起新 agent。

## 1. 上下文隔离规则（最小相关输入）
主 agent 给子 agent 的 prompt **只给与当前这一个单元任务直接相关的输入，不多给**：本单元**输入文件的路径**、**产物输出规格**、**必须遵守的约束清单**、**要调用的 skill 名**。
- **禁止过量输入**：不塞对话历史、不塞其他单元/其他商品的内容、不塞与本镜无关的整篇文档——只投喂本任务真正用到的那一段/那几个文件。
- 判据：若删掉某条输入不影响本单元产出，就不该给它。宁可精确到「本商品本镜的那一段 + 对应事实卡的那一条」，也不整本丢过去。

## 1.5 单一任务台账（Task Ledger）—— 唯一协作总线

**全项目只有一个任务文件：`contracts/TASKS.md`。** 任务分派、子 agent 读任务、子 agent 写交付、状态流转，**全部经由这一个文件**，不另开协作渠道。

- **主 agent 写**：新建/更新任务块（任务定义、输入、输出规格、约束、指定 skill、`分派中`）；验收后写 `已过审` 或 `打回+原因`。
- **子 agent 读**：只读**自己那一个任务块**（= 该单元的最小相关输入：输入文件路径 + 输出规格 + 约束 + skill 名），不读别的块、不读对话。
- **子 agent 写**：完成后**只改自己这一个任务块**，回填「交付」（输出文件路径）、`完成待审`、provenance（run-id/凭证）、一句自述。**禁止改别的任务块。**
- **并发安全**：每块以唯一 `任务ID` 为锚；并发单元用不同 ID、各写各块；主 agent 不让两个子 agent 同时写同一块。
- **HTML 从它派生**：`build-review-html` 解析本文件得到每单元状态与产物链接（见 §2.5），使「任务单 + 成果」在同一页可见。

**每个任务块的固定字段：**
```
### [任务ID] <阶段/单元名>  ·  状态: 待办|分派中|完成待审|已过审|打回
- 执行者: 子agent + skill(如 screenwriting-master / h3-prompt-writing / 机械调脚本)
- 输入(最小相关): <文件路径/参数，只列本单元用到的>
- 输出(定死): <产物文件路径 + 规格>
- 约束/SOP: <本单元必须遵守的约束文档与经验记忆>
- 分派: 主agent @<时间>
— 交付(子agent回填): <实际产物路径>
— provenance(子agent回填): <run-id/凭证>
— 自述(子agent回填): <一句>
— 验收(主agent回填): 已过审 / 打回:<原因> @<时间>
```

## 2. 五阶段流水线 + 单元任务目录

顶层流水线（顺序执行；**阶段2/3 的子 agent 必须被喂入该阶段对应的「约束/SOP 文档」作为输入并遵守**）：

`S1 信息收集 → S2 剧本编写改写 → S3 分析剧本·做分镜（分镜表 / 资产 / 图片提示词 / 视频提示词） → S4 生图 → S5 生视频（含成片）`

| 阶段 | 单元任务 | 执行者 | 输入（最小相关） | 输出（定死） | 验收闸门（主 agent） |
|---|---|---|---|---|---|
| **S1 信息收集** | T1 项目 intake | **主 agent 与用户对话**（唯一主 agent 直接做，属沟通/总控，非创作产出） | 用户答复 | `contracts/project-intake.json`（选品/路线/钩子/卖点/情绪/形式发散/事实边界/预算/casting/约束） | 线索齐全才进 S2 |
| **S2 剧本** | T2 剧本编写改写（每商品1单元） | 子 agent 调 `screenwriting-master` | 该商品锁定路由、内容锁定稿对应段、事实卡对应条、**剧本约束/SOP 文档**、模型=H3 | `stories/PP-XX-screenplay.md`（核心动作/结构/对白/潜台词，可摄影；**并在剧本层判定并标注驱动分层**） | 遵剧本红线；**驱动分层按本故事实判、非套模板**（依 story-drive §1：对话类→对白驱动，感官/演示类→动作·物件·对比·音乐驱动；氛围不得单独驱动；主引擎/动力/点睛/缝合各由谁承担须写明）；每支形式发散不雷同；显性「为什么买」[[daihuo-must-show-why-buy]]；事实闸门无违规 |
| **S3 分镜** | T3a 分镜表+资产清单（每商品1单元） | 子 agent 调 `ad-creative-expert`(§2.5 分镜内置验证) | 该商品 screenplay、**分镜约束/SOP 文档**、模型能力(I2VA/FL2VA/最短4s) | `stories/PP-XX-storyboard.md`（逐镜：内容/景别运镜/输入模式/卖点情绪落位/声音/对白落点/收尾字幕）+ `assets/PP-assets.md`（资产清单：母版图/参考/字体/音效） | §2.5 内置验证过；镜头语言按场景 [[shot-language-by-scene-not-uniform]]；覆盖非幻灯 [[coverage-continuity-editing-vs-slideshow]]；状态变化 FL2VA [[fl2va-for-state-change-actions]] |
| **S3 分镜** | T3b 图片提示词（每帧1单元） | 子 agent 调 `h3-prompt-writing`（本项目 H3 锁定；`seedance-prompt-zh` 为 codex 侧技能、Claude 不可用，短期忽略） | 该镜 storyboard 段、输入模式、参考母版路径、casting/事实约束、768x1344 | `prompts/PP-shot-SS-{first\|last}.json`（`h3_prompt_review`(asset_type=image)+`narrative_alignment`，作者=h3-prompt-writing） | `validate-h3-prompt-review.sh <f> image` 过（不得用 Seedance 字段/校验替代，见 00 元数据）；锁中国人 [[daihuo-casting-must-be-chinese]]；商品位后期贴真图、母版仅英雄帧 img2img [[img2img-edits-overpreserves-portrait-magnet]]；画幅 768×1344 [[gpt-image-h3-aspect-mismatch-distortion]]；极近景框死面部不入画 [[extreme-closeup-framing-gpt-image]] |
| **S3 分镜** | T3c 视频提示词（每镜1单元，**依赖 S4 关键帧路径，故排在 S4 后**） | 子 agent 调 `h3-prompt-writing` | 该镜 storyboard 段、输入模式、首/尾关键帧路径、声音设计、约束 | `prompts/PP-shot-SS-video.json`（首尾帧对齐语法/9:16/无烧字约束/`h3_prompt_review` 技能产出） | `validate-h3-prompt-review.sh <f> video` 过；无烧字 [[h3-dialogue-burns-subtitles-nondeterministic]] |
| **S4 生图** | T4 图片生成（每帧/批1单元） | 子 agent 机械调 `generate-image.sh` | 过审图片提示词 JSON、`--size 768x1344`、`--reference`(如需)、独立`--audit-dir` | `PP/shots/shot-SS/images/{first\|last}.png` + audit | QC：选角/构图/母版还原/无穿帮/无违规文案 |
| **S5 生视频** | T5 视频生成（每镜1单元） | 子 agent 机械调 `generate-video.sh --wait --download` | 过审视频提示词 JSON、绝对`--reference`(FL2VA:first→last)、独立`--audit-dir` | `PP/shots/shot-SS/video/clip.mp4` | 金丝雀先/见拒即停 exit3 [[precheck-balance-canary-before-paid-batch]] [[background-generation-pitfalls]]；看片：动作兑现/连贯/无烧字/casting；记账 [[media-generation-costs]] |
| **S5 生视频** | T6 成片合成（每商品1单元） | 子 agent 机械调 ffmpeg 脚本 | 各镜 clip、对白字幕文本、收尾字幕、Noto CJK、loudnorm、xfade 0.25s | `edit/PP-final.mp4` | 覆盖剪辑非幻灯 [[coverage-continuity-editing-vs-slideshow]] [[ai-live-action-no-slideshow-sop]]；字幕对画面 [[align-voice-to-picture-not-overlay]]；HTTP200；无媒体入库 [[no-media-in-repo]] |

> 横切要求：**每个单元完成的前提是其输出已同步进 HTML 且可直接查看（见 §2.5）**；付费单元(T4/T5)受 §3 出处后盾强制。

## 2.5 HTML 同步（每个单元的完成定义 Definition of Done）
**任何单元任务，只有当其输出「同步进项目 HTML 且能在 HTML 中直接看到」时，才算完成。** 产物文件生成但 HTML 未更新 = 未完成，主 agent 不得放行下一环。

- **可见标准**（按单元类型）：剧本(U1)→ md 渲染成可读分镜表；图片提示词(U2)→ 提示词文本 + 参考母版可见；图片(U3)→ 缩略/原图内嵌可看；视频提示词(U4)→ 提示词文本可见；视频(U5)→ `<video>` 可直接播放；成片(U6)→ 成片 `<video>` + 收尾字幕/时长/成本可见。
- **单一评审面**：HTML 位于项目根、走服务地址 `https://www.tonbird.top/ads-review/wechat-channel-ads-20260912/`，媒体用**相对路径**引用（媒体不入库 [[no-media-in-repo]]，仅存本地由 nginx 提供）。
- **同步机制（确定性构建，非人工拼装）**：由一个 `build-review-html`（扫描 `stories/ prompts/ **/images **/video edit/` 等产物自动重生成 HTML）负责。
  - 该构建工具本身是一个**单元任务**，由子 agent 创建（属工具/基础设施，非主 agent 亲手产出）。
  - 每个单元通过验收后，主 agent 用 `Bash` 跑一次 `build-review-html`（调用脚本=允许的编排动作），HTML 即随之刷新。构建从产物派生，主 agent 不手写 HTML 内容。
- **进度可见**：HTML 同时展示任务单状态（每单元 待办/进行/已过审/打回），使「成果 + 流程状态」都能在同一页看到。
## 3. 出处不可自证后盾（付费单元强制）
现状 validator 只查「字段齐全 + SHA 匹配」，`generated_by_skill` 可被主 agent 手填伪造。**必须补：**
- **provenance 校验**：`*_prompt_review` 必须带流程发放、主 agent 造不出的凭证（子 agent run-id / transcript 哈希），validator 校验其与本次派单一致；
- **PreToolUse hook**：卡住 `generate-image.sh` / `generate-video.sh`，凭证不合规直接 block，付费调用发不出。hook 归仓库/用户所有，主 agent 无权改、无权绕——这是唯一满足「任何时候」的层。

## 4. 诚实边界
子 agent 与主 agent 同模型，独立性是**流程上的**（隔离上下文/单元/即毁/transcript 即证据），非第三方人审——为本环境最优，但非真·独立第三方。第 3 层后盾未落地前，第 0–2 层仍含君子协定成分；后盾落地后方为结构强制。

## 5. 约束文档指针（钉死；改约束只改源头文件）
子 agent 收到的「约束/SOP 文档」输入，**按阶段从下表取，主 agent 不复述其条文、只投喂文件路径**：

| 阶段 | 「剧本约束/分镜约束」= 这些文件 |
|---|---|
| **通用（S2+S3 都遵）** | `references/video-production-sop.md`（唯一生产权威：原文忠实 / 驱动分层 / 连续性 / 分镜粒度 / 生成与验收闸门） |
| **S2 剧本约束** | 上 + 本商品 `03-六商品详细内容脚本.md` 对应锁定稿段 + `01-产品事实与核验边界.md` 对应事实卡与红线 |
| **S3 分镜约束** | 上 + `references/video-production-sop.md` 第 8-9 节完整分镜模板 + H3 能力边界（I2VA 只首帧 / FL2VA 锁首尾状态 / 最短时长以当前模型能力为准） + 商品 100% 还原（真图裁切+后期贴图，商品位留干净） |
| **S3/S4 提示词与生图** | 模型=H3 → 唯一作者 `h3-prompt-writing`；`seedance-prompt-zh` 为 codex 技能、Claude 不可用、短期忽略；图片门禁 `validate-h3-prompt-review.sh <f> image`、视频门禁 `... video`（00 元数据：不得用 Seedance 字段/校验替代） |

> 事实闸门（六商品红线）源头＝`01-产品事实与核验边界.md` + `03` 末尾事实闸门表 + `00-项目元数据.md` §事实闸门；未补证据的表述一律不进公开成片。
