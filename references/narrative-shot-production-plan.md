# 叙事分镜生产计划

本规范负责把已经确认的广告故事或剧本转成可生成、可剪辑、可追溯的生产单元。它吸收 `shuohao-skills/novel-storyboard` 的“节拍认领、生成段、段内切镜、确定性校验”方法，但不引入其 H3 提示词格式，也不改变本项目三个 Skill 的职责。

## 职责边界

```text
screenwriting-master
  原始故事、人物关系、场景、戏剧动作、逐场节拍
        ↓ 不得删改语义
ad-creative-expert
  叙事分镜、生成单元、段内切镜、资产与后期任务、覆盖校验
        ↓ 交付结构化镜头任务，不交付生产提示词
seedance-prompt-zh
  图片/视频最终生产提示词、可实现性优化、引用语法和生成前校验
        ↓ 提示词 hash 锁定
ad-creative-expert
  成本、生成编排、逐文件验收、剪辑、页面和交付
```

任何下游 Skill 都不得静默删除上游故事节拍。无法在当前时长或单次生成中稳定完成时，必须增加生成单元、转为后期任务，或把阻塞项交回用户；“精简提示词”不是删减故事的授权。

## 四层结构

1. `narrativeShots`：用户看到并确认的完整叙事分镜。它可以长于一次模型调用。
2. `generationUnits`：一次图片/视频生成调用的工作范围。默认上限由项目和 provider 决定，本项目通用默认值为 15 秒，不固定为 8 秒。
3. `cuts`：生成单元内部的构图或剪切节奏。它不等于新的付费生成调用。
4. `postTasks`：对白、旁白、拟音、声音桥、字幕、转场、确定性商品落版等后期任务。

例如：

```text
叙事分镜 01
  ├── 生成单元 01A
  │   ├── cut 1：小周夹虾
  │   └── cut 2：林晚夹回
  └── 后期：对白、虾壳脆响、抬眼后的声音桥
```

## 节拍覆盖模型

每个 `requiredBeats` 条目必须列出它要求的交付通道：

- `picture`：画面中必须看见的状态、动作或反应。
- `dialogue`：对白或旁白。
- `action_sound`：与动作同步的拟音。
- `ambience`：环境声。
- `transition`：画面或声音承担的段落衔接。
- `onscreen_text`：字幕、品牌、价格、CTA 等确定性文字。

`cuts[].coverage` 和 `postTasks[].coverage` 逐项认领 `beatId + channels`。每个必需通道必须被恰好认领一次；遗漏和重复都失败。一个节拍可以由画面与后期共同完成，例如画面认领 `picture`，拟音任务认领 `action_sound`。

覆盖关系只证明“安排了谁来做”，不证明素材质量已经通过。图片与视频仍需当前项目模型对应的提示词技能门禁、付费编排器状态和语义验收。项目必须先锁定 MiniMax-H3 或 Seedance-2.0；模型切换时冻结生成并重写受影响提示词。

## JSON 最小结构

```json
{
  "schemaVersion": 1,
  "projectId": "project-slug",
  "promptPolicy": {
    "model": "Seedance-2.0",
    "authoringSkill": "seedance-prompt-zh",
    "reviewGate": "replication/tools/validate-seedance-prompt-review.sh"
  },
  "constraints": {
    "maxGenerationSeconds": 15
  },
  "narrativeShots": [
    {
      "id": "01",
      "title": "完整叙事分镜",
      "source": {
        "storyFile": "01-story.md",
        "locator": "场景 1",
        "verbatim": "原始故事原文"
      },
      "requiredBeats": [
        {
          "id": "01-b01",
          "sceneId": "scene-01",
          "text": "人物完成关键动作",
          "channels": ["picture", "action_sound"]
        }
      ],
      "generationUnits": [
        {
          "id": "01A",
          "sceneId": "scene-01",
          "durationSeconds": 8,
          "cuts": [
            {
              "id": "01A-c01",
              "seconds": 8,
              "coverage": [
                { "beatId": "01-b01", "channels": ["picture"] }
              ]
            }
          ],
          "prompts": {
            "images": ["prompts/01-shot-01a-first-frame.json"],
            "video": "prompts/01-shot-01a-video.json"
          },
          "media": {
            "firstFrame": "shots/shot-01/images/01a-first-frame.png",
            "lastFrame": null,
            "video": "shots/shot-01/video/01a.mp4"
          },
          "references": ["assets/character-master.png"]
        }
      ],
      "postTasks": [
        {
          "id": "01-post-sfx",
          "type": "sound_effect",
          "description": "同步关键动作拟音",
          "coverage": [
            { "beatId": "01-b01", "channels": ["action_sound"] }
          ]
        }
      ]
    }
  ]
}
```

`source.verbatim` 是审阅页面展示的原始故事，不允许用生成提示词反推。若同时提供 `storyFile`，校验器会检查原文是否能在源文件中找到。

## 路径与提示词约束

- 所有生产提示词只能放在项目的 `prompts/` 下。
- 分镜图片只能放在 `shots/shot-XX/images/` 下。
- 分镜视频只能放在 `shots/shot-XX/video/` 下。
- 跨分镜复用的基础公共资产放在 `assets/` 下。
- `references` 可以引用 `assets/` 或当前分镜目录，但不能引用其他分镜的生成产物来冒充公共资产。
- 生产计划只保存提示词文件路径，不复制提示词正文，也不产生提示词。

## 状态与确认

拆镜计划、提示词确认、付费生成和素材验收是不同状态：

```text
draft → storyboard_confirmed → prompts_ready → prompt_confirmed
      → generated_pending_qc → accepted
```

- `storyboard_confirmed` 只表示叙事结构通过。
- `prompts_ready` 必须已经由项目锁定模型对应的提示词 skill 产出并通过机器门禁：MiniMax-H3 使用 `h3-prompt-writing`，Seedance-2.0 使用 `seedance-prompt-zh`。
- 用户在页面上要求生成，表示页面当前 prompt hash 已确认；不得在提交前重写。
- `accepted` 必须有实际文件和视觉/技术验收证据，不能由计划文件自行声明。

## 使用校验器

```bash
node scripts/validate-production-plan.mjs <project-production-plan.json> [--project-root <项目目录>]
```

校验器检查结构、ID、生成时长、段内时长、同场约束、节拍通道不重不漏，以及提示词和媒体目录。它不替代 `validate-seedance-prompt-review.sh`，也不读取或改写生产提示词。

## 来源与许可

节拍认领、生成段和确定性校验思路改编自 `eternityspring/shuohao-skills` 的 `novel-storyboard`，Apache License 2.0。原项目的 H3 提示词骨架、语言规则和模型专用字段未被引入。

用户明确说“开始生成首尾帧/开始生成图片/开始生图”时，表示生图前待确认项已确认；明确说“开始生成视频/开始生视频”时，表示视频前待确认项已确认。不得重复要求同一层级确认，但仍执行生成前门禁、预算/依赖检查和生成后验收。

视频输入模式必须依据原始故事、分镜动作链、转场需求和模型稳定性逐镜判断，不得盲目统一使用首尾帧。可选模式包括：I2VA（只有首帧）、FL2VA（首尾帧）、参考图生视频（人物/场景/风格参考）。判断结果必须写入槽位契约并在HTML显示；只有确实需要控制终点状态时才生成尾帧。

分镜状态规则：视频生成完成并通过技术检查即视为当前分镜通过；后续仅在用户提出修改/重做/验收问题时回退状态。
