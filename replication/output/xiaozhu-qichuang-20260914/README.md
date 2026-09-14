# 《小猪起床了》— 项目 README

## 目标
一条约 48 秒（60 秒以内）、横屏 16:9、对白驱动的纯情感短片。男主分手后回忆起和女主一个赖床耍赖的暖色早晨；冷（现在）暖（回忆）双时空并置。无商品植入。

## 当前阶段
`final_cut_v1` —— 成片(对白完整版)已出:`edit/xiaozhu-final-cut.mp4`(52.6s)。S04 正反打对白镜采用 H3 烧字幕版(`shots/S04/S04-U1.burned-subtitle.mp4`,含中文对白+完整"第三个五分钟/假打呼/假的"正反打,已扶正为 `S04-U1.mp4`,旧静音误删版留底 `S04-U1.silent-rejected.mp4`)。字幕策略:采用"接受烧录+就此不补其余镜"(用户 2026-09-14 决定),即 S04 单镜带字幕、其余靠配音;H3 烧字幕处理办法已写入 `references/video-production-sop.md` 13.2.1。对白镜 S02–S08 纯线性增益对齐 -18 LUFS,冷段 S01/S09/S10 保留静默不抬噪。构建脚本 `edit/build-final-cut-v1.sh`。
（前序:声音初剪 `edit/xiaozhu-sound-cut-v1.mp4`(S04 尚为静音版)、画面初剪 `edit/xiaozhu-picture-cut.mp4`。）

### 声音/剪辑待办
- **v2 音效**：`edit/fetch-sfx.sh` 拉取 freesound CC 音效（挂钟滴答/水滴/餐具/清晨房间底噪/掀被布料），落 `assets/sfx/`。冷段三镜敷氛围 + 暖段拟音加厚 + 母线 loudnorm。（freesound 服务不稳，脚本带抗抖动重试。）
- **v3 最终剪辑**：`S01→S02`、`S08→S09` 两处 match cut 转场（现为硬切）+ BGM（暖段温柔、冷段留白）。
- **终审**：逐句听 H3 对白（错字/串味/口型）、逐帧查烧字幕、冷暖调色一致性。

### 前序阶段（keyframes_generated，已完成）
资产母图已通过；15 张逐镜端点关键帧已生成（横屏 16:9，gpt-image-2 文生图锁 1344×768=H3 768P 16:9，全部 references[] 文生图、闸门 pass、sha256==prompt 核验通过）。审阅页：`assets/keyframe-review.html`（母图审阅仍在 `assets/review.html`）。

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
