# Nan Studio 工具箱（本项目副本）

这些文件从 `/Users/wmzuo/Documents/project/tonbirds-studio/nan-studio/` 复制而来，服务于本次镜前换装复刻。

## 文件用途

- `character-cards.md`：人物参考图和三视图生成提示词。
- `script-system.md`：Seedance 图生视频提示词结构和素材引用规范。
- `production-workflow.md`：素材确认、分段生成和版本管理流程。
- `production-constraints.md`：生成前检查、动作复杂度和画面质量约束。
- `check-generation-constraints.sh`：检查 JSON 提示词中是否有会诱发特写的冲突措辞。
- `extract-last-frame.sh`：从视频提取末帧；使用前需改成本项目的输出目录。

## 本项目覆盖规则

- 不生成品牌、Logo、账号名、平台水印、价格或购买按钮。
- 手机界面只表达“穿搭选择”，界面文字由后期添加，不依赖 AI 生成可读文字。
- 手机是叙事核心，可以占据较大画面；原 Nan Studio 的“道具弱化”规则不适用于手机选择段。
- 服装、镜子和人物先生成静态参考图，再分段生成视频。
