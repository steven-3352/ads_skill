# NAN-TRIO 固定脚本与角色系统

## 1. 系统名称

三位男主统一归档为：**NAN-TRIO（南三号角色系统）**。

固定角色 ID、中文名和年龄如下。ID 一经启用不再更换，所有脚本、参考图、声音、视频和数据表都使用 ID。

| ID | 固定称呼 | 年龄 | 关系入口 | 固定视觉关键词 |
| --- | --- | --- | --- | --- |
| NAN-01 | 林叙（大哥） | 38–45 | 可靠、克制、有经历 | 轻微眼袋、短胡茬、深色大衣/西装、低饱和 |
| NAN-02 | 周恺（二哥） | 30–38 | 平等沟通、日常暧昧 | 清爽、不完美记忆点、通勤/居家服、自然光 |
| NAN-03 | 许阳（三弟） | 23–28 | 热烈主动、共同成长 | 清爽阳光、轻微痘印、休闲服、明亮生活光 |

“大哥 / 二哥 / 三弟”只是用户侧昵称；生产文件必须写完整 ID 和姓名，例如 `NAN-01_林叙`。

## 2. 脚本文件规范

目录：`scripts/100-moments/`

文件名：`主题-YYYY-MM-DD.md`

示例：`被记住的咖啡-2026-09-03.md`

每个文件只写一个短视频脚本。主题可使用中文，日期统一使用拍摄/定稿日期，不使用含糊的“第几集”代替日期。若同日同主题有多个版本，追加 `-A`、`-B`。

## 3. 不可变制作规则

- **IMAGE 1 永远是男主参考图**，必须明确写出 `IMAGE 1 = NAN-0X 男主全身三视图参考图`，不得把女主或场景放在 IMAGE 1。
- 男主服装来自已制作好的三视图参考图；视频提示词必须写“严格参考 IMAGE 1 的服装、发型、体型和面部特征”，不重新发明衣服。
- 女主不使用固定脸、不建立连续真人身份；由生成模型自动生成成年女性角色。只固定本条所需的年龄段、动作、服装和情绪，不指定现实人物。
- 每句台词都标注说话人，格式固定为 `【林叙（NAN-01）】`、`【女主（自动生成）】` 等。
- 画面提示词和声音/对白提示词分开，方便直接复制到图生视频和配音工具。
- Seedance 2.0 提示词统一使用 `@Image1`、`@Image2` 等素材引用语法，并在提示词中说明每个素材的职责；不得只写“参考图”。
- Seedance 2.0 单次最多 9 张图片、3 个视频、3 个音频，总文件数不超过 12 个；输出时长为 4–15 秒。超过 10 秒的剧情用明确时间段拆写，必要时分段生成后剪辑。
- Seedance 2.0 对上传的写实真人脸有平台合规限制。使用真人型角色前，先确认当前账号/版本是否允许；被拦截时改用非写实角色参考或不上传人脸，仅用文字描述成年虚拟角色。
- 明确标注“虚拟角色 / AI 生成”；不冒充真实人物，不使用未授权真人照片。
- 9:16 竖屏，15–30 秒，前 2 秒必须有动作、异常或关系悬念。

## 4. 可复制脚本模板

将以下模板复制为 `scripts/100-moments/主题-YYYY-MM-DD.md`，再替换方括号内容。

````markdown
# [主题]｜[YYYY-MM-DD]

## 固定信息

- 栏目：100个打动你的瞬间
- 副标题：只因为是你，你值得被看见
- 角色系统：NAN-TRIO
- 男主：NAN-0X [姓名]，[年龄]
- 瞬间方向：[被记住 / 被尊重 / 克制暧昧 / ...]
- 成片时长：[15–30] 秒；Seedance 单次生成段落：[4–15] 秒，长内容分段生成后剪辑
- 画幅：9:16 竖屏
- 透明标注：虚拟角色 / AI 生成

## 素材锁定

- @Image1 = NAN-0X [姓名] 男主全身三视图参考图（正面、侧面、背面）
- @Image2 = 本集生活场景参考图：[办公室/地铁/便利店/住宅/街道]
- @Image3 = 女主参考图（自动生成成年女性；不固定真人身份）
- 男主服装锁定：[直接沿用 IMAGE 1，不新增服装]

## 前 2 秒 Hook

- 首帧动作：[具体到手、眼神、转身、放下物品等]
- 屏幕字幕：[不超过 16 个汉字]
- Hook 目的：[关系悬念 / 反常行为 / 结果先行]

## 分镜与台词

### 镜头 1｜0.0–2.0 秒

- 画面：严格参考 IMAGE 1 的 NAN-0X [姓名]，保持服装、发型、体型、脸部特征一致；[动作]。
- 台词：无。
- 字幕：[Hook 字幕]

### 镜头 2｜2.0–[X] 秒

- 画面：NAN-0X [姓名] 与女主（自动生成成年女性）在[场景]；[动作和情绪]。
- 台词：
  - 【女主（自动生成）】：“[台词]”
  - 【NAN-0X [姓名]】：“[台词]”

### 镜头 3｜[X]–[Y] 秒

- 画面：[关系变化或反差动作]。
- 台词：
  - 【NAN-0X [姓名]】：“[台词]”
  - 【女主（自动生成）】：“[台词]”

### 镜头 4｜[Y]–[总时长] 秒

- 画面：停在未完成的情绪节点，[眼神/转身/物件]。
- 台词：无，或明确标注说话人。
- 结尾互动字幕：[二选一问题]

## Seedance 2.0 图生视频提示词（可直接复制）

```text
@Image1 as the male character appearance and first-frame reference, @Image2 as the scene/background reference, @Image3 as the automatically generated adult female protagonist reference. 9:16 vertical short video, [4–15] seconds. Preserve @Image1's face, hairstyle, body proportions and clothing; do not redesign or change the outfit. [0–2s: opening action and hook]. [2–8s: character action, eye line, distance and dialogue timing]. [8–15s: emotional turn and ending shot]. Camera movement: [push in / track / static close-up / one-take]. Natural human motion, realistic hands, natural skin texture, subtle micro-expressions, cinematic everyday lighting, restrained and believable adult intimacy. Audio: [dialogue speaker and tone], [environment sound], [optional BGM]. No logos, text artifacts, extra fingers, face drift, outfit change, anime style, luxury fantasy setting. Mark as fictional character / AI generated.
```

## 配音与剪辑提示词（可直接复制）

```text
普通话，生活化、克制、近距离收音。NAN-0X [姓名] 使用[低沉/清爽/明亮]成年男性声线；女主使用成年女性自然声线。严格按台词说话人配音，不交换角色，不增加台词。保留[停顿]秒呼吸和环境声；前2秒先出动作和字幕，字幕只保留关键信息。结尾保留[1–2]秒停顿，接互动问题。
```

## 发布与复盘

- 评论问题：[你希望他怎么做？/你会怎么选？]
- 本条只测试的变量：[Hook 或行为证明]
- 记录：2 秒/3 秒停留、完播、平均观看时长、重复观看、收藏、评论后续需求、主页访问、关注。
- 复盘结论：发布后 10 条汇总，不以单条播放量直接判断角色成败。
````

## 5. 文件验收清单

发布前逐项确认：

- [ ] 文件名符合“主题-日期.md”；
- [ ] 写明 IMAGE 1 的固定人物和三视图；
- [ ] 男主服装明确为 IMAGE 1 参考，不被提示词改写；
- [ ] 女主写明“自动生成成年女性”；
- [ ] 每句台词有明确说话人；
- [ ] 前 2 秒有可见动作或关系悬念；
- [ ] 图生视频提示词可整段复制；
- [ ] 配音提示词可整段复制；
- [ ] 结尾有互动问题，且没有越界或露骨性暗示；
- [ ] 标注“虚拟角色 / AI 生成”。
