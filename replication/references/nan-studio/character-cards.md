# NAN-TRIO 人物卡与参考图生成提示词

这三张人物卡是长期固定资产。首次生成时制作正面、左侧面、右侧面、背面和半身表情参考图；后续视频以对应三视图作为 `IMAGE 1`，不得更换脸、年龄、体型或基础发型。服装可以按主题更新，但每次更新都要重新生成该角色的一组三视图并登记版本号。

## NAN-01 林叙｜大哥

### 人物卡

- 年龄：42 岁；成年中国男性；普通城市职业人士
- 气质：沉稳、克制、有阅历、可靠但不居高临下
- 脸部：端正耐看，轻微眼袋、细纹、短胡茬，肤色有自然差异，面部不完全对称
- 体型：健康匀称，肩背自然，不夸张肌肉
- 发型：自然侧分短发，略有纹理，不油亮
- 固定声音：偏低沉、语速中慢、咬字清楚，情绪变化小但有停顿
- 缺点：工作优先，不擅长及时解释，偶尔显得疏离

### 三视图生成提示词

```text
Create a realistic three-view character reference sheet of NAN-01 Lin Xu, a 42-year-old adult Chinese man, ordinary urban professional, front view, left side view, right side view and back view in one clean studio sheet. Calm mature face, subtle eye bags and fine lines, light short stubble, natural pores and slight skin tone variation, mildly asymmetrical features, healthy average build, natural shoulders, short textured side-parted hair. Outfit version LX-BASE-01: charcoal wool overcoat, white oxford shirt, dark straight-leg trousers, worn brown leather shoes, no visible logos, realistic fabric folds. Neutral standing posture, consistent proportions, soft neutral studio light, high facial identity consistency, photorealistic, no glamour retouching, no model-like perfection.
```

```text
Negative prompt: young face, teenager, idol face, heavy makeup, plastic skin, exaggerated muscles, broad superhero shoulders, luxury logos, jewelry, different outfits between views, inconsistent face, extra limbs, deformed hands, anime, illustration, text, watermark.
```

## NAN-02 周恺｜二哥

### 人物卡

- 年龄：34 岁；成年中国男性；有稳定工作的城市白领
- 气质：自然、会沟通、有行动力，强势时仍保持平等和分寸
- 脸部：清爽顺眼，右眉尾有很浅的小疤痕作为记忆点，肤质真实
- 体型：偏瘦但结实，日常体态放松
- 发型：短发，前额有一小缕不完全服帖
- 固定声音：清爽中音，语气直接，认真时会放慢
- 缺点：嘴硬，忙时回避冲突，不擅长示弱

### 三视图生成提示词

```text
Create a realistic three-view character reference sheet of NAN-02 Zhou Kai, a 34-year-old adult Chinese man, ordinary urban white-collar professional, front view, left side view, right side view and back view in one clean studio sheet. Clean approachable face, a very subtle small scar at the outer end of the right eyebrow as the only memorable imperfection, natural pores and skin texture, lean but healthy build, relaxed posture, short hair with one slightly unruly lock on the forehead. Outfit version ZK-BASE-01: light blue cotton shirt with sleeves casually rolled, dark olive chinos, off-white canvas sneakers, simple black watch, no logos, realistic fabric folds. Neutral standing posture, consistent proportions, soft neutral studio light, high facial identity consistency, photorealistic, ordinary and believable rather than celebrity-perfect.
```

```text
Negative prompt: teenager, idol styling, flawless plastic skin, luxury suit, visible brand, exaggerated jaw, bodybuilder physique, different scar position, different outfits between views, inconsistent face, extra fingers, anime, illustration, text, watermark.
```

## NAN-03 许阳｜三弟

### 人物卡

- 年龄：25 岁；成年中国男性；刚工作几年的普通城市青年
- 气质：阳光、直接、热烈，愿意学习边界和承担错误
- 脸部：清爽但不完美，鼻梁旁有轻微痘印，笑起来露出一点不整齐的牙齿
- 体型：健康偏瘦，动作有年轻人的轻快感
- 发型：短碎发，发尾自然翘起，不做练习生造型
- 固定声音：明亮中高音，语速略快，紧张时会停顿重来
- 缺点：冲动、容易吃醋，需要把热烈变成可靠

### 三视图生成提示词

```text
Create a realistic three-view character reference sheet of NAN-03 Xu Yang, a 25-year-old adult Chinese man, ordinary young urban worker, front view, left side view, right side view and back view in one clean studio sheet. Fresh sunny approachable face, subtle acne marks beside the nose, natural pores, slightly uneven teeth visible only when smiling, healthy slim build, relaxed youthful posture, short textured hair with naturally lifted ends, no trainee or idol styling. Outfit version XY-BASE-01: washed sage-green overshirt over a plain white T-shirt, straight dark denim jeans, worn white sneakers, simple canvas tote, no logos, realistic fabric folds. Neutral standing posture, consistent proportions, soft neutral studio light, high facial identity consistency, photorealistic, believable everyday person.
```

```text
Negative prompt: minor, teenager, idol face, heavy retouching, perfect teeth, muscular body, designer clothing, visible logos, different outfits between views, inconsistent face, extra fingers, anime, illustration, text, watermark.
```

## 服装版本管理

- `LX-BASE-01`、`ZK-BASE-01`、`XY-BASE-01` 是首次基础服装。
- 主题需要换衣服时，新建版本号，例如 `LX-RAIN-01`，同时生成该服装的正/侧/背三视图。
- 脚本必须写明 `IMAGE 1` 使用的角色和服装版本；视频提示词只允许继承该版本，不允许模型自由换装。
