# 执行层修正留痕 · 关键帧(shot_image)阶段

> 目的:诚实记录本阶段两处对生产计划的**执行层细化**,以及为什么不改动已锁的 `contracts/production-plan.json`。

## 背景:plan 已在 storyboard_confirmed 锁定,状态机不许回退
- `production-plan.json` 的 sha256 已入总账(stage2 gate-out)。主状态已推进到 `public_assets_accepted`。
- 状态机(`references/state-machine/main-sequence.json`)只允许前进到紧邻后继,或回退到本 stage 的 *_pending;`stage2-storyboard.sh --phase run` 写死要求 `cur==screenplay_confirmed`,**无法从 public_assets_accepted 回退改 plan**。
- 因此本阶段不偷改已锁 plan 的 hash;plan 锁定的**创作意图(节拍/对白 verbatim/秒数守恒/每拍×通道覆盖)保持不变且未动**。

## 修正一:关键帧走文生图锁身份,不做图生图
- `paid-asset-orchestrator.sh` 生图分支只传 `--prompt/--size`,不传 `--reference`;`generate-image.sh` 若从 prompt 的 `.references` 读到参考图会走 images/edits 图生图,导致"肖像磁吸/主体走形"(见记忆 img2img-overpreserves)。
- 故所有关键帧提示词 `.references=[]`,人物身份靠**提示词文本详细描述母板样貌**(五官/发型/服装/年龄/气质)锁定,与母板提示词共享身份描述块。
- plan 内各单元 `references:["assets/master-*.png"]` 是**文档追溯字段**(声明该镜身份锚到哪个母板),**不驱动生成**;实际身份根 = `assets/characters/fenshou-pengyou-M/F-master.png`(已 accept)。

## 修正二:7 个手机状态变化镜按 FL2VA 执行(plan 内 mode 字段为 storyboard 初值)
- 记忆 fl2va-for-state-change-actions:改变物体状态/位置的动作须锁首尾帧+摆落点,单首帧 I2VA 会漏演。
- 以下 7 单元在执行层按 **FL2VA**(first+last 两张关键帧,见 paid-state `shot_image` 资产),stage4 视频提示词以首尾帧驱动:
  - SH01-U1(拇指悬删除键→收回)、SH01-U2(指尖压拉黑键→顿住未按)
  - SH08-U1(手机屏幕朝下扣桌·落点)
  - SH09-U1(摩挲头像三下→停住·证据①)、SH09-U2(手机反扣腿上·落点)
  - SH11-U1(反手锁屏→合照屏保→停·证据③)、SH11-U2(按下拉黑→屏保没换→翻扣·证据②)
- 其余 13 单元(出镜说台词/听 V.O. 反应)保持单首帧 I2VA。
- plan 内这些单元 `mode` 字段仍为 storyboard 锁定时的 `I2VA`;真值以本留痕 + paid-state 资产清单 + 各镜提示词为准。

## 匹配剪辑一致性锁(跨男女线)
- SH11-U1-last 与 SH11-U2-last 的**锁屏屏保必须是同一张两人合照**(男主深色针织衫短发 + 女主米色毛衣长发,室内暖调并肩合影),供拍9匹配剪辑。
- SH01-U1 男主手机头像=女主样貌;SH01-U2 女主手机(拉黑对象)头像=男主样貌。
- 上述统一描述已下发两条线的提示词子 agent,保持合照/头像描述一致。

## 付费与授权
- 本批 27 张关键帧(13 I2VA×1 + 7 FL2VA×2)× ¥0.25 = ¥6.75;paid-state hard_cap 提至 ¥8.0(覆盖母板 ¥0.5 + 本批);生视频阶段再提上限。
