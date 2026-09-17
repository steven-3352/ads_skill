# deprecated/ — 已废弃脚本归档

这些脚本已被 **`run.sh`（项目级统一门禁 / 唯一编排入口）** 取代或本就是一次性工具。
保留在此仅作历史参考，**不得再调用**。正式生产一律走 `run.sh <project-dir> <stage> --sub <sub>`。

| 脚本 | 为何废弃 | 现由谁承担 |
|---|---|---|
| `run-codex.sh` | 平行的无人值守 headless 入口，硬编码 `love-story-level-5`，靠 prompt 自觉遵守 SOP、绕沙箱，与"唯一入口 + 证据台账"冲突。 | `run.sh` 逐 stage 回合制推进；智能内容由主会话派隔离子 agent 产出，gate-out 校验证据链后才入总账。 |
| `run-codex.sh.before-no-sandbox.bak` | 上者的旧备份。 | 同上。 |
| `prepare-shots-video-pending.sh` | 硬编码 `love-story-level-5`，校验各镜 `slots.json` 是否 `prompts_ready`。校验职责已被 **stage4 gate-in（状态门）+ orchestrator run-asset（依赖 accepted / 提示词评审 / 防覆盖）** 取代。 | `run.sh <dir> stage4-videos --sub <sub> --phase run`（gate-in）+ `paid-asset-orchestrator.sh`。 |
| `migrate-shot-slots.mjs` | 一次性数据迁移（把 storyboard/story 拆进 love-story-level-5 的 slots.json），无校验、无退出码。 | 一次性任务已完成，无对应替代；新项目用 storyboard 填空模板 + `validate-production-plan.mjs`（stage2 gate-out）。 |

废弃日期：2026-09-17。取代者：仓库根 `run.sh` + `references/state-machine/main-sequence.json` + `replication/tools/stages/`。
