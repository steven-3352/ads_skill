# 《小猪起床了》— 项目 README

## 目标
一条约 48 秒（60 秒以内）、横屏 16:9、对白驱动的纯情感短片。男主分手后回忆起和女主一个赖床耍赖的暖色早晨；冷（现在）暖（回忆）双时空并置。无商品植入。

## 当前阶段
`keyframes_generated` —— 资产母图已通过；15 张逐镜端点关键帧已生成（横屏 16:9，gpt-image-2 文生图锁 1344×768=H3 768P 16:9，全部 references[] 文生图、闸门 pass、sha256==prompt 核验通过）。**等待用户确认关键帧画面**。审阅页：`assets/keyframe-review.html`（母图审阅仍在 `assets/review.html`）。确认后进入付费 H3 视频生成（逐 Unit，付费前再报价+金丝雀）。

- 模型已锁：MiniMax-H3（`contracts/prompt-policy.json`）
- 契约：`contracts/{visual-grammar,assets,production-plan}.json`（production-plan 已过 validate-production-plan，**10 shots** valid，含 S10 手机"一年前的今天"收尾）
- 分镜审阅稿：`review/storyboard.md`（A–G / H1–H4 / 资产 / 关键帧计划）
- 资产母图：`assets/prompts/*.json`（h3-prompt-writing 授权+闸门通过）、`assets/images/*.png`（未入库）

## 权威文件
- 生产流程：仓库 `references/video-production-sop.md`
- 铁律与路由：仓库根 `SKILL.md`
- 原始需求：`story/source.md`（不覆盖）
- 确认剧本：`story/screenplay.md`

## 待用户决定 / 下一步闸门
- **视频模型未选**：`model_selection_pending`。选 MiniMax-H3 → `h3-prompt-writing`；选 Seedance-2.0 → `seedance-prompt-zh`。未选前不写正式生产提示词、不付费生成。
- 继续推进需进入阶段 3（公共资产 + 视觉语法 + 分镜 A–G / Unit H1–H4），届时再建 `contracts/`、`shots/` 等完整目录。
