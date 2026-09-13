# 文档总索引

本项目的 Markdown 按“当前 Skill 规范 → 方法论与 SOP → 案例与蒸馏 → 生产记录 → 评估与 PRD”管理。新文档先归类，再加入对应索引；不要把新旧内容随意堆在根目录。

## 1. 当前入口

- [SKILL.md](SKILL.md)：`ad-creative-expert` 的唯一主入口和路由规则。
- [references/video-production-sop.md](references/video-production-sop.md)：所有新视频项目的唯一生产 SOP，内含能力加载目录、项目目录、完整分镜模板、生成与验收闸门。
- [references/README.md](references/README.md)：方法论、SOP、案例蒸馏和学习资料索引。
- [replication/README.md](replication/README.md)：AI 复刻/生产项目的素材、提示词、输出和日志索引。
- [PROJECT-KNOWLEDGE-AUDIT-2026-09-13.md](PROJECT-KNOWLEDGE-AUDIT-2026-09-13.md)：本次知识、经验、约束、SOP 与正反馈的盘点快照；不是生产规则来源。

## 2. 稳定文档与工作产物

|目录|用途|维护规则|
|---|---|---|
|`references/`|可复用方法、SOP、模板、案例蒸馏|内容稳定后才进入；必须被 `SKILL.md` 或 `references/README.md` 索引|
|`references/cases/`|单一案例的机制和制作决策|写清事实、推断、可迁移机制和边界，不复制资产|
|`replication/references/`|复刻项目的角色、制作约束和脚本系统|只放复刻生产通用规则，不放单次结果|
|`replication/source/`|样本事实分析|保留来源、规格、时间线和证据边界|
|`replication/prompts/`|生成提示词输入|按项目/镜头命名，提示词与生成日志配对|
|`replication/output/`|项目产物、时间线、验收和日志|属于历史生产记录，不与通用方法混写|
|`evaluation/`|测试用例和测试结果|只记录能力验证，不当作创意案例库|
|`prd/`|具体产品/客户需求文档|项目需求，不升级为通用方法，除非蒸馏后另存到 `references/`|

## 3. 主题归并关系

### Brief、策略和平台

- `references/brief-framework.md`：Brief 真值字段、受众和成本基础。
- `references/category-playbook.md`：消费品类创意入口。
- `references/platform-and-testing.md`：平台、Hook、A/B 测试。
- `references/research-sources.md`：外部方法资料与可迁移结论。

### 创意机制与视频蒸馏

- `references/video-replication-framework.md`：通用视频样本蒸馏主框架。
- `references/creative-transfer-thinking.md`：跨品类创意思维迁移。
- `references/sample-set-creative-distillation.md`：特定样本集的机制证据。
- `references/volcengine-video-distillation.md`：Volcengine 本地视频的内容、Hook、拍摄、爽点和购买理由蒸馏。
- `references/creative-reheating-sop.md`：经典广告/旧创意的迁移和升级。

以上文件不是四套模板：通用框架负责方法，样本文件负责证据，具体案例只补充差异；出现重复时以通用框架为准。

### AI 视频生产与三 Skill 协作

- `references/video-production-sop.md`：唯一生产流程；统一 `ads → screenwriting → ads 分镜 → H3/Seedance 视频提示词 → 逐单元生成/验收`，并包含能力目录、项目目录、Shot/Panel/Unit 模板、连续性、成本和状态机。
- `references/cases/`：具体 AI 生产案例，不能替代通用 SOP。

### 数据、案例和迭代

- `references/case-library-template.md`：案例入库格式。
- `references/learned-patterns.md`：待复验的投放规律。
- `references/weekly-iteration.md`：每周数据迭代。

## 4. 文档生命周期

```text
临时分析/项目记录 → replication 或 prd
可复用方法 → references
多次验证后的规则 → learned-patterns 或通用 SOP
仍有历史解释价值的废弃内容 → 标注 Deprecated，并保留迁移链接
已被完整吸收且不再有独立价值的重复内容 → 更新全部引用后删除，由版本历史保留
```

新增 Markdown 必须回答：它属于哪个目录？是否与现有文档重复？谁会读取它？如果是 `references/`，必须加入本索引和 `SKILL.md` 的按需索引。
