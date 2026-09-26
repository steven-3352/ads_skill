# 《分手后要不要做朋友》· 抖音情感短剧

- 目录:`douyin-fenshou-pengyou-20260918` ｜ sub:`fenshou-pengyou`
- 平台/画幅:抖音 · 16:9(锁定) ｜ 时长:约 64.5s ｜ 模型:MiniMax-H3
- 形式:男女双线**交叉剪辑**;中景为主(道具特写仅拍1/拍9,近景仅拍5)
- 出镜:仅男主、女主;朋友(男声)/闺蜜(女声)=画外音 V.O.
- 核心撕点:留朋友位=没放下,还是拉黑断联=没放下?哪种才是真放下?

## 门禁与推进
唯一入口 `run.sh`(总账哈希链 + 状态机)。当前状态见:
`./run.sh replication/output/douyin-fenshou-pengyou-20260918 --status --sub fenshou-pengyou`

## 目录索引
- `story/source.md` — 用户原始主题与约束(永久保留,不覆盖)
- `story/screenplay.md` — 确认版剧本(逐拍表/内心刻画/金句/画面证据)✅
- `contracts/production-orchestration-contract.md` — 生产锁与并行执行契约(5阶段锁)
- `contracts/production-plan.json` — 分镜生产计划(过 validate-production-plan.mjs)
- `automation/fenshou-pengyou.project.json` — run.sh 描述符
- `automation/fenshou-pengyou.ledger.ndjson` — 总账(哈希链,run.sh 唯一写者)
- `prompts/` `shots/` `assets/` `review/` `edit/` `final/` `social/` — 各阶段产物位

## 阶段状态
1. 剧本 screenplay_confirmed ✅
2. 分镜 storyboard(进行中,无付费)
3. 母板+生图(付费,待报价)
4. 生视频(付费,待报价)
5. 成片+TTS+后期(付费,待报价)
