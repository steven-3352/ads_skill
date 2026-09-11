# 模型选择与提示词路由 SOP

## 启动必问

新项目创建时必须询问：

> 本项目使用哪个视频生成模型：MiniMax-H3，还是 Seedance 2.0？后续可切换，但切换会冻结生成、重写提示词并重新审查。

未得到明确选择，状态为 `model_selection_pending`，不生成图片、视频或付费请求。

## 路由

- MiniMax-H3：读取 `/home/ubuntu/.codex/skills/h3-prompt-writing/SKILL.md`；根据输入选择 T2VA、I2VA、FL2VA、L2VA 或 Ref2VA；遵循 H3 的英文结构化字段和 `<Picture N>` 等标签。
- Seedance 2.0：读取 `/home/ubuntu/.codex/skills/seedance2-skill/zh/SKILL.md`；遵循 `@图片N`、`@视频N`、`@音频N` 引用和中文分时段提示词。

## 模型切换

用户明确告知模型变更后：

1. 设置 `model_migration_pending`，停止所有新的 POST。
2. 读取目标模型 skill，重写受影响镜头提示词。
3. 重新检查首尾帧、引用格式、输入数量、时长、声音和 provider 参数。
4. 重新进行目标模型可实现性审查，并更新提示词 hash。
5. 重算成本和预算，更新页面及编排状态。
6. 用户确认迁移后的页面提示词后才允许生成。

旧模型生成的素材继续保留其原模型、原提示词和 QC 证据，不能在新模型页面中混为同一生产版本。

