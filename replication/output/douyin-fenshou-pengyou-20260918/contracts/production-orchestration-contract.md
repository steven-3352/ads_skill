# 生产锁与并行执行契约 ·《分手后要不要做朋友》

> 项目:`douyin-fenshou-pengyou-20260918` ｜ sub:`fenshou-pengyou` ｜ 抖音 16:9 ｜ MiniMax-H3
> 门禁执行者 = `run.sh` + 总账哈希链 + `references/state-machine/main-sequence.json`。本文件是**人读的锁定意图**;机器真值以总账为准(绕过 run.sh 的产物不被承认)。
> 状态推进:每锁一阶段 = 状态机一段迁移;付费三阶段(生图/生视频/成片)必须先报价+查余额+金丝雀。

## 恒定锁(全阶段不变)
- **画幅**:16:9 全屏,锁定。
- **出镜**:仅男主、女主本人;朋友(男声)/闺蜜(女声)=画外音 V.O.,不出镜、不对口型、不建母板。
- **景别**:中景为主;道具特写仅拍1/拍9(手机),近景仅拍5(男主情绪峰微推)。
- **选角**:男女主均 East Asian / 中国人(文生图显式锁,防欧美脸)。
- **灯光**:居家/咖啡馆正常明亮通透、光色自然中性偏暖白,不做单盏暖黄压抑。
- **字幕**:出镜对白 + V.O. 一律**后期统一烧**,H3 不直出(直出非确定);分镜阶段备清单/安全区/样式。
- **事实源**:`story/screenplay.md`(含 `screenplay_confirmed`);`story/source.md` 永久保留不覆盖。
- **命名空间**:owner_globs 见 `automation/fenshou-pengyou.project.json`;独立项目目录,无寄居。

## 阶段1锁 · 剧本(state: screenplay_confirmed ✅ 已达)
- 锁定物:`story/screenplay.md`(逐拍表/内心刻画/金句前置/三处画面证据/潜台词)。
- 已过 stage1 gate-out:文件存在 + `screenplay_confirmed` 标记 + sha256 入账(总账 seq3)。
- 变更纪律:剧本任何改动 → 回退 `screenplay_pending` 重走 gate-out,下游全部作废重来。

## 阶段2锁 · 分镜/对白/音效/提示词(state: production_plan_pending → storyboard_confirmed)
- 锁定物:
  - `contracts/production-plan.json`(逐拍→叙事镜→生成单元→cut 覆盖;过 `validate-production-plan.mjs`:三元组绑定/verbatim 子串/秒数守恒/每 beat×通道恰好认领一次/路径沙箱)。
  - `shots/fenshou-pengyou-*/`(各镜 contract、关键帧提示词位)+ 各镜 H3 提示词过 `validate-h3-prompt-review.sh`。
- 场景切分:男主线 SC_M / 女主线 SC_F 为两个独立场景;每个生成单元只属一个场景;**交叉剪辑是剪辑期拼接,不在生成期跨场景**。
- gate-out:`run.sh … stage2-storyboard --phase gate-out`(收编 validate-production-plan.mjs,plan sha256 入账)。
- 无付费。

## 阶段3锁 · 母板 + 并行生图(state: storyboard_confirmed → public_assets_accepted → shot_images_accepted)【付费】
- **先母板再镜头帧**:先出男主、女主人物母板(身份根),用户认可后各镜 `--reference` 母板;不跳母板直接报镜头帧。
- 关键帧/落幅:文生图为主;产品/道具静物落幅用无参考文生图(带母板会把道具带偏)。
- 极近景/道具特写(拍1/拍9 手机):提示词首句"面部不入画 + 填满画面",框死。
- **付费纪律**:报价(图片¥0.25/张)→ 查余额 → 金丝雀 1 张验通路/扣费 → 剩余并行生成(各独立 audit + request-id;在途别杀)。积分不足会 HTTP200 静默拒绝,见拒即停。
- gate:masters 子阶段 gate-out → shots 子阶段 gate-out;验产品必读 PNG 本身。

## 阶段4锁 · 并行生视频 · 对白一次性(state: shot_images_accepted → shot_videos_accepted)【付费】
- **对白在正片镜内嵌一次性生成**,不事后单独补口播;音画同步、省钱少拼接。
- 关键状态变化动作(拿手机/按拉黑/扣手机/锁屏)用 FL2VA 锁首尾帧 + 摆落点 + 逐动词;单首帧 I2VA 会漏演。
- H3 只出中文配音 + 表演;字幕留到阶段5后期烧。
- V.O.(朋友/闺蜜)不在此生成(无出镜)→ 阶段5用豆包 TTS 单独配。
- **付费纪律**:报价(视频¥0.2/秒,按生成时长;H3 最短 4s 按 4s 计费)→ 查余额 → 金丝雀 → 走 run-video-batch.sh 顺序/并行,见拒即停。
- gate-out:各单元 audit + accept 入账。

## 阶段5锁 · 成片 · TTS 补全 + 后期(state: shot_videos_accepted → final_workflow_pending → final_qc → complete)
- V.O. 配音:朋友(男声)/闺蜜(男→女声)用 `replication/tools/generate-speech.sh`(豆包 seed-audio,需控制台开通),按逐拍累计秒卡进本人反应画面时长内。
- 剪辑:交叉剪辑拼男女双线;拍5男主问句声画交叉压女主按拉黑顿住画面;拍9 同一合照匹配剪辑;硬切为主。
- 字幕后期统一烧(出镜 + V.O.),anti-subtitle + QC 无残留。
- 验收:[C]内容丰满度门(每拍≥1新事件/无停滞窗)+ [R]节奏门(钩子/静默/观感卫生)+ 完整播放听审(非四截图)。
- 交付:公网 HTML 展示页(故事+资产 / 分镜总览 / 分镜详情)。

## 并行/隔离纪律(全程)
- 主 agent 只 intake/编排/派发/监控/验收;每生成单元由**全新隔离子 agent** 执行,最小相关输入,完即毁。
- 后台生成防坑:不嵌套 &/子 shell(会被杀);各单元独立 audit 目录(防 stale-lock);付费并发控量防烧余额。
- 中文文本改动一律 Edit/Write 或 python UTF-8,禁 perl/sed;媒体不进 git(只提交文本)。

## 用户业务确认边界
- 用户只做业务/创意确认(对不对、要不要);工程/门禁/脚本/付费执行全权 Claude。
- "确认即执行下一步"(含付费);付费前必先报价并等确认。
