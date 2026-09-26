# Travel 关键帧提示词写作契约（子 agent 必读）

项目：`replication/output/Travel/` —《一个人的环中国自驾·兑现承诺》抖音 9:16 竖屏情感公路片，旁白独白驱动，母板已锁。你只写**文生图关键帧提示词 JSON**（不生成图，不碰付费）。

## 1. 通用参数（每个文件都一样）
- `"model": "gpt-image-2"`，`"size": "768x1344"`，`"aspect_ratio": "9:16"`，`"authoring_skill": "seedance-prompt-zh"`
- schema **严格照范例**：`replication/output/Travel/prompts/assets/travel-couple-photo-master.json`（先读它照抄结构）
- 输出目录：`replication/output/Travel/prompts/shots/`

## 2. prompt 字段硬规范（写进中文 prompt 文本里，逐条兑现）
1. **画幅**：竖构图 9:16，主体居中、不贴边不出画，防拉伸变形。
2. **真实质感（死命令）**：iPhone/单反真实照片级质感，细腻真实肤质、可见毛孔、自然噪点、轻微不均；**绝无塑料感/AI感/CG蜡感/磨皮假脸/蜡像感**。
3. **柔光无油光**：柔和自然漫射光，光色中性偏暖白、明亮通透不压抑，忌大黄光染脸；人脸哑光、无油光高光反光。
4. **合规（死命令）**：画面**任何位置无文字/字幕/字母/数字/水印/logo/品牌**；**无商业招牌/店名/路牌/广告牌**。打卡地名一律靠后期花字，画面不出字。
5. **人物（有人物时）**：东亚中国人五官，自然普通中国人长相，**排除欧美/高加索/混血/网红滤镜脸/整容脸**。
6. **地标风光镜**：可画**具体自然/文化景观本体**（青海湖、茶卡盐湖天空之镜、稻城亚丁雪山牛奶海经幡、川藏318弯道雪山、拉萨布达拉宫白墙红宫经幡、敦煌鸣沙山月牙泉驼队、额济纳胡杨林、呼伦贝尔草原、洱海白族民居），但**不出任何文字招牌/路牌/品牌**。驾驶画面为安全行进/停靠，不暗示危险驾驶。
7. **极近景镜（手/指特写）**：prompt **首句**必须写"**面部不入画、主体（手/物）填满画面**"，明确**禁止中景/人物半身**，否则会渲成肖像。

## 3. reference（母板锁身份）
在 `"references"` 数组填母板 PNG 路径（相对仓库根）：
- 母板A 合照道具 = `replication/output/Travel/assets/characters/master-couple-photo.png`
- 母板B 女主角 = `replication/output/Travel/assets/characters/master-protagonist.png`
无人物/无合照的纯风光镜 references 留空 `[]`。

## 4. 必填块（照范例填，narrative_alignment 别漏）
- `identity_anchor`（有身份锁时填；纯风光镜可写场景锚点说明）
- `seedance_prompt_review`：`skill`="seedance-prompt-zh"，`authorship`="generated_by_skill"，`result`="pass"，`asset_type`="image"，`reviewed_at` ISO 时间，`checks` 数组（≥4条，逐条对应§2硬规范），`unresolved_blockers`=`[]`，`reviewed_prompt_sha256`=**§5算的哈希**
- `narrative_alignment`：`source_story`="story/travel-screenplay.md"，`related_beats`（非空）、`related_shots`（非空）、`visual_evidence`（非空，摘剧本该镜画面/旁白）、`unresolved_blockers`=`[]`

## 5. 自校验（每个文件写完必须做，不过不交）
```
# 先算哈希填进 reviewed_prompt_sha256（注意 -j 无换行）
jq -jr '.prompt' <file> | sha256sum
# 再校验，必须打印 pass
replication/tools/validate-seedance-prompt-review.sh <file> image
```
顺序：先写好 prompt 文本 → 算 sha 填入 → 跑 validate → 若改了 prompt 必重算 sha。**所有文件都 validate pass 才算完成。**

## 6. 报告
完成后回报：写了哪些文件、每个 validate 结果（pass）、每镜 reference 用了哪个母板。别贴 prompt 全文。
