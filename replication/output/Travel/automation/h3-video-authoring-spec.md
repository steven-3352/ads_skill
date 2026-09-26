# Travel H3 视频提示词写作契约（子 agent 必读）

项目：`replication/output/Travel/` —《一个人的环中国自驾·兑现承诺》抖音 9:16 竖屏情感公路片。**旁白独白驱动，但旁白后期用 TTS 单配**，母板与关键帧已锁并 accepted。你只写 **H3 视频提示词 JSON**（不生成视频，不碰付费）。

## 0. 先做两件事
1. **加载 skill：`h3-prompt-writing`**（用 Skill 工具），严格照 `references/base-en.txt` 的最终 prompt 结构写（指令行 + 三核心字段）。
2. 读一个现成范例照抄 JSON 外壳结构：`replication/output/xiaozhu-qichuang-20260914/prompts/fenshou-FS04-U3-video.json`（注意它用 `.images` 传帧、用 `h3_prompt_review` 块）。

## 1. 本片硬规范（每条都要兑现，违反直接废）
1. **绝对无对白**：本片旁白后期 TTS 单配 → prompt **禁止出现任何 `<d>` 对白/说话/唱词/画外音台词**，禁止写 speaker ID。人物不说话（画面本就没有正脸开口镜）。
2. **`non_diegetic_music: N/A`**（配乐后期加，H3 别自造 BGM）。
3. **`overall_soundscape` 只写现场同期音**（环境声+动作声+非语言人声如脚步/布料/风/引擎/水声/驼铃/经幡拍动），1–4 句英文，给后期 TTS 当干净底噪床。
4. **真实质感（死命令）**：`Live-action, cinematic, photorealistic`，iPhone/单反真实照片级，真实肤质/自然噪点/自然光；**绝无塑料感/AI感/CG蜡感/磨皮/蜡像感**。人脸/手部哑光无油光高光。
5. **柔光**：柔和自然漫射光、中性偏暖白、明亮通透不压抑，忌大黄光染脸。
6. **合规（死命令）**：画面**任何位置无文字/字幕/字母/数字/水印/logo/品牌/招牌/店名/路牌/广告牌**；地名靠后期花字，视频里不出字。（On-Screen Text 段：无。）
7. **人物**：东亚中国人五官、自然普通中国人长相，排除欧美/高加索/混血/网红滤镜/整容脸。多为手部/背影/驾驶 POV，无正脸开口镜。
8. **运镜**：按 skill §4.3 写「运动类型+幅度+速度」，作自然英文动作嵌进镜头句，**幅度小、速度慢/正常为主**（情感片，忌大幅快速运镜）；情绪静镜可 `Static Shot`。
9. **时长**：`integrated_multimodal_description` 的时间线必须与该镜请求时长严丝合缝（见 §3 表）；单镜单 Shot（FL2VA/I2VA 都尽量一镜到底，别乱切 Shot）。
10. **驾驶画面**为安全平稳行进/停靠，不暗示危险驾驶。

## 2. 输入模式与帧引用（写进 `.mode` 和 `.images`）
- **I2VA**（16 镜）：`.images = ["<关键帧绝对路径>"]`；prompt 首行用 skill 的 I2VA 指令行：`For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced.` 结构=首帧锚点→动作起→连续发展→结果。
- **FL2VA**（镜 01、04）：`.images = ["<首帧绝对路径>","<尾帧绝对路径>"]`；首行用 FL2VA 指令行（Picture 1→0.00s，Picture 2→S.SS s = 该镜时长）。结构=首帧态→中间可见变化→差异收窄→尾帧态，单 Shot。

关键帧绝对路径（仓库根 `/home/ubuntu/ads_skill`）：
- 单帧镜 NN：`/home/ubuntu/ads_skill/replication/output/Travel/shots/NN/keyframe.png`
- 镜01 首：`.../shots/01/first.png`；镜01 尾：`.../shots/01/last-v2.png`（背景锁定重生版）
- 镜04 首：`.../shots/04/first.png`；镜04 尾：`.../shots/04/last.png`

## 3. 逐镜表（旁白仅供你理解情绪/动作，**绝不写进 prompt**）
| 镜 | 模式 | 时长 | 画面 | 情绪 | 运镜建议 | 现场音景要点 | 旁白(仅参考) |
|--|--|--|--|--|--|--|--|
|01|FL2VA|4s|极近景俯拍：一双东亚手把叠好的正红冲锋衣放进行李箱，首帧举衣悬于箱上→尾帧衣已平整入箱、手正离开；旁另一空箱|怅惘·克制|Static 或极小幅慢 push|布料翻叠窸窣、拉链/箱扣轻响、安静室内底噪|出发前一晚我把你那件红外套叠好放进去|
|02|I2VA|4s|特写：桌面手绘环中国路线图，一根手指划过标着青海湖的圈点|怅惘·追忆|极小幅慢 push in 向指尖|纸面摩挲、指腹划纸、安静室内|这张图是咱俩画的你圈的地方我都记着|
|03|I2VA|4s|中景：车内空副驾座上放着两人合照相框，缓推|怅惘·孤身|Push In 小幅慢速 向合照|车内静谧底噪、极轻布料/皮座声|说好两个人一起去现在就剩我自己|
|04|FL2VA|4s|全景：一辆无标越野车停在小区门口→点火驶离出画（首帧停、尾帧车已驶出/远去）|转坚定·启程|Static 机位，车驶离；或极小幅|关车门、点火、引擎启动、轮胎压地、驶离|走吧第一站去你圈了最久的地方|
|05|I2VA|4s|驾驶舱 POV：主驾视角看前方公路，副驾摆着两人合照|坚定·陪伴|Static POV，路面向前流动，极轻晃|引擎平稳嗡鸣、路噪、风声、偶尔转向灯|副驾摆着咱俩合照这一路你陪着我|
|06|I2VA|4s|远景航拍：青海湖畔笔直公路直通天际、湖蓝壮阔|坚定·开阔|Push In / 向前推 小幅慢速|高原风、远处水声、偶尔过车|青海湖到了这蓝照片拍不出来|
|07|I2VA|4s|全景航拍低仰：茶卡盐湖天空之镜、倒影天地相接|惊叹·澄澈|极小幅慢 tilt 或缓推|浅水微响、风、远处脚步踩盐壳|走到茶卡脚下全是天|
|08|I2VA|4s|全景低仰：稻城亚丁雪山下牛奶海、经幡随风|肃穆·思念|Static，经幡与风动|强风、经幡布拍动、空旷高原|亚丁雪山下头风好大我替你多站会儿|
|09|I2VA|4s|车内 POV：川藏318 盘山弯道、雪山在望，随路起伏|坚定·前行|Tracking 向前 小幅|引擎、轮胎过弯、风、路面颠簸轻响|318弯得吓人开着开着就到了|
|10|I2VA|4s|全景：拉萨布达拉宫白墙红宫前经幡朝圣氛围|眷恋·虔敬|Truck/Pan 小幅慢速|风、经幡拍动、远处人群低语|到了拉萨我替咱俩许了个愿|
|11|I2VA|4s|全景航拍逆光：敦煌鸣沙山月牙泉、驼队剪影缓行|眷恋·苍茫|Arc/Push 小幅慢速|沙漠风、驼铃、沙上脚步|敦煌的风裹着沙子打在脸上|
|12|I2VA|4s|全景逆光剪影：额济纳金黄胡杨林中女主背影伫立|眷恋·独立|Static 或极小幅慢 push 背影|风穿叶、落叶窸窣、空旷|胡杨林黄了黄了才好看|
|13|I2VA|4s|远景航拍广角：呼伦贝尔草原风掀起层层草浪|舒展·释怀|向前 Push / Pan 大幅慢速|草原风、草浪沙沙|草原上风一刮人是真舒坦|
|14|I2VA|4s|中景背影跟拍：洱海边女主背影临湖而立、风吹发丝衣角|眷恋·恍惚|Tracking/Truck 极小幅慢速|湖水拍岸、风、衣角发丝动|洱海边站着我总觉得你就在旁边|
|15|I2VA|4s|近景手持：一双手捧着两人合照，指腹缓缓摩挲照片|释然·郑重|极小幅慢 push in|极轻布料/纸面摩挲、户外风轻拂|每个地方我一个一个都替你走到了|
|16|I2VA|5s|中景车内后座视角：回望后视镜里延伸的公路与夕阳|释然·绵长|Static 或极小幅，路面后退|引擎平稳、路噪、风|剩下的路还很长我会慢慢替你走完|
|17|I2VA|4s|全景航拍黄昏：车驶向落日、逆光公路铺满金光|释然·辽阔|Push 向前/跟车 小幅慢速|引擎、风、黄昏旷野|你在那边这些好看的应该都看到了吧|
|18|I2VA|5s|特写慢推：副驾两人合照相框，缓慢推近至定格|释然·收束|Push In 小幅慢速→末端 hold|车内静谧、极轻底噪|答应过你的我都做到了|

## 4. JSON schema（每镜一个文件，路径 `prompts/shots/travel-NN-video.json`）
```json
{
  "id": "travel-NN-video",
  "mode": "I2VA",                     // 或 FL2VA
  "model": "MiniMax-H3",
  "prompt": "<H3 英文 prompt：指令行 + 空行 + integrated_multimodal_description / overall_soundscape / non_diegetic_music>",
  "images": ["<绝对路径>"],          // I2VA 1 张 / FL2VA 首,尾 2 张
  "duration": 4,                      // 见 §3 表；镜16/18=5
  "ratio": "9:16",
  "generate_audio": true,
  "watermark": false,
  "h3_prompt_review": {
    "skill": "h3-prompt-writing",
    "authorship": "generated_by_skill",
    "result": "pass",
    "asset_type": "video",
    "mode": "I2VA",                   // 与顶层一致
    "checks": [ ... ≥5 条，逐条对应 §1 硬规范（无对白/N/A配乐/同期音景/真实质感/柔光/合规无字/运镜/时长对齐/模式帧引用） ... ],
    "unresolved_blockers": [],
    "reviewed_prompt_sha256": "<§5 算的哈希>"
  },
  "narrative_alignment": {
    "source_story": "story/travel-screenplay.md",
    "related_beats": ["..."],
    "related_shots": ["镜NN ..."],
    "visual_evidence": ["剧本该镜画面/旁白摘录（记录用，非写进prompt）"],
    "unresolved_blockers": []
  }
}
```

## 5. 自校验（每个文件写完必须做，不过不交）
```
# 先算哈希填进 reviewed_prompt_sha256（-j 无换行，只对 .prompt 字符串）
jq -jr '.prompt' <file> | sha256sum
# 再校验，必须打印 pass
replication/tools/validate-h3-prompt-review.sh <file> video
```
顺序：写好 prompt → 算 sha 填入 → 跑 validate → 改了 prompt 必重算 sha。**所有文件都 validate pass 才算完成。**

## 6. 报告
完成后回报：写了哪些文件、每个 validate 结果（pass）、每镜 mode 与 images 张数。别贴 prompt 全文。
