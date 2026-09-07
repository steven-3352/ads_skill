# Replication 文档索引

`replication/` 保存具体 AI 复刻/生产项目的来源、提示词、产物和日志，不与 `references/` 的通用方法混放。

## 目录

- `source/`：原始样本与事实分析。
- `prompts/`：图像/视频生成输入，按项目和镜头组织。
- `references/`：复刻生产通用约束，如角色卡、脚本系统、制作约束。
- `tools/`：生成和验收脚本。
- `output/`：每个项目的 SOP、时间线、素材登记、生产日志和 README。

## 当前项目

- `output/mirror-outfit-replication/`：换装/选择器/照片蒙太奇项目。
- `output/wild-mode/`：真实主体到商品的变形项目。
- `output/love-story-level-5/`：写实现代爱情情景短片《她曾经这样爱过》五集项目。
- `references/nan-studio/`：NAN-TRIO 脚本和角色系统。

## 维护规则

1. 单次生成结果、失败记录和时间线留在对应 `output/<project>/`。
2. 能迁移到其他项目的规律，蒸馏后移入 `../references/`，不要继续堆在 output。
3. 新项目先建项目 README，写清目标、输入、输出、状态和相关通用 SOP。
4. 不删除历史产物；若方法过时，在项目 README 标注状态并链接新 SOP。
