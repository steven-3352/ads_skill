# EXECUTION · 03 杏仁七白饮 3A《清晨开场乐》(试点)

项目 `wechat-channel-ads-20260912` · 模型锁 **MiniMax-H3** · 提示词技能 `h3-prompt-writing`
评审页:https://www.tonbird.top/ads-review/wechat-channel-ads-20260912/review/index.html

## 事实源
- 分镜(唯一事实源):`contracts/production-plan.json`(过 `scripts/validate-production-plan.mjs`)
- 剧本节拍/旁白:`contracts/screenplay.json`
- 立项/事实闸门/成本:`contracts/project-intake.json`
- 逐镜 verbatim:`stories/03-3a-shooting-script.md`

## 流程与门禁(逐步,用户全程陪走)

| # | 阶段 | 状态 | 门禁 |
|---|------|------|------|
| 1 | 内容脚本锁定 | ✅ 通过 | 03-六商品详细内容脚本.md「3A」 |
| 2 | 驱动锁定(声音/动作主引擎+轻旁白点睛) | ✅ 通过 | 用户确认 |
| 3 | 可摄影视听脚本 | ✅ 通过 | screenwriting-master 自检 |
| 4 | 9镜分镜 + 契约 | ✅ valid | `validate-production-plan.mjs` (9 shots) |
| 5 | HTML 信息确认页 | ✅ 已上线 | **← 当前:等用户确认 9镜/商品还原/事实闸门** |
| 6 | 关键帧提示词 | ⏳ 未开始 | h3-prompt-writing → `validate-h3-prompt-review.sh image` |
| 7 | 关键帧生成(图片闸门) | ⏳ 未开始 | `generate-image.sh`(exit4 禁 img2img,文生图);商品位留干净给后期贴真图 |
| 8 | 报总价 → 批准 | ⏳ 未开始 | 估 ¥10.45(关键帧¥3.25+视频36s×¥0.2=¥7.2),硬上限 ¥20;先查余额+金丝雀 |
| 9 | H3 视频提示词 + 生成 | ⏳ 未开始 | `validate-h3-prompt-review.sh video` → `run-video-batch.sh`(见拒即停) |
| 10 | 覆盖剪辑成片 | ⏳ 未开始 | 旁白VO1/VO2逐句对画面 + 收尾字幕后期渲染 + loudnorm;无幻灯片五条 |
| 11 | 验收 | ⏳ 未开始 | 商品100%还原核对(S2/S9)、事实闸门核对、烧字检查 |
| 12 | 5张小红书图文 | ⏳ 未开始 | 视频验收后 |

## 关键约束(不可破)
- **商品 100% 还原**:S2 拧盖 / S9 端杯·留桌的商品位=后期贴真图(`assets/product-master.png`),不用模型生成包装字样。
- **事实闸门**:不当代餐;40%杏仁/三个0添加/18.5g/中国人寿关系等未核验前不进成片。
- **付费门禁**:本页零付费;关键帧→报价→批准→才付费生视频;`generation_allowed:false` 未解除前不生视频。
- 状态变化镜(S3落粉/S4注水/S5漩涡/S6搅匀)用 **FL2VA** 锁首尾帧。
- **H3 最短 4s、不足 4s 也按 4s 计费**:9 镜均按 4s 生成/计费,覆盖剪辑里 trim 到内容秒数(余量作 0.3s 叠化 handle)。
- 含人声但**不靠 H3 烧字幕**:旁白配音+收尾字幕走后期,避免 H3 非确定性烧字。

## 待放入素材
- `assets/product-master.png` — 从 `/home/ubuntu/mvstudio-workspace/wechat`(03 索引 55–57)裁切商品真图。
