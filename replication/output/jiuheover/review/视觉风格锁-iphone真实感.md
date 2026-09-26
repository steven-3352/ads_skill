# 《酒喝完了，我们散了》视觉风格锁 · iPhone 17 真实拍摄质感（去塑料感/AI感）

> 2026-09-21 用户视觉硬要求。**所有关键帧文生图（GPT Image）与视频提示词（H3）统一引用本锁**，逐镜不重复描述，只写差异。
> 目标：一眼像真人用 iPhone 17 拍下来的生活片段——有噪点、有真实肤质、有自然光；**绝不是**磨皮塑料脸、过曝 HDR、CG 渲染那种"一眼假"。

---

## 一、总基调（每镜都成立）

- **器材/画质**：shot on iPhone 17 Pro，computational photography look，竖屏 9:16，手持轻晃真实质感。
- **写实定性**：photorealistic，candid documentary realism，像抓拍/生活流水，不是摆拍大片。
- **场景/光**：小酒馆靠窗老位置；顶灯开+桌面吊灯，**明亮暖白看得清脸、不压暗不压抑**（承 `scene-lighting-normal-not-moody`）；窗外雨、夜；自然混合色温、柔和光衰减、高光自然滚降（不过曝死白）。
- **人物**：East Asian 中国人，随母板（苏晚 master-A / 陈叙 master-B）；30 岁上下情侣。
- **调色**：muted true-to-life，自然不过饱和；轻微镜头暗角。

## 二、去塑料感的关键（正向锚 · 英文修饰词进提示词）

```
shot on iPhone 17 Pro, computational photography, photorealistic, candid documentary,
natural skin texture with visible pores, fine lines, subtle blemishes and natural oil sheen,
realistic subsurface skin, true-to-life uneven skin tone,
subtle sensor noise / fine film grain in shadows and midtones, low-light ISO grain,
natural mixed-temperature ambient light, soft real-world light falloff, gentle highlight roll-off,
slight handheld micro-shake, natural shallow depth of field, mild lens vignetting,
muted natural color, true-to-life white balance
```

## 三、禁止项（去 AI 感 · 负向词进提示词）

```
no plastic skin, no waxy over-smoothed face, no poreless skin, no airbrushed beauty-filter,
no CGI, no 3D render look, no video-game look, no over-sharpening, no over-HDR,
no glossy plastic highlights, no blown-out overexposure, no oversaturated color,
no sterile clean digital look, no artificial perfection
```

## 四、落地约束（与既有经验对齐）

- **画幅**：关键帧用 GPT Image 直接出 **768×1344 锁 9:16**，禁 2:3 后拉伸（`gpt-image-h3-aspect-mismatch-distortion`）。
- **H3 极简**：视频提示词保持极简（`h3-lipsync-anchor-recipe`）；真实感主要靠**关键帧质感带**，H3 侧只轻量加 `realistic handheld, subtle grain`，别把整段正/负向词堆进 H3（会抢戏、丢对口型/参考）。
- **极近景**：手部/极近景关键帧首句"面部不入画+填满画面"（`extreme-closeup-framing-gpt-image`）。
- **合规不变**：素白无标白瓷瓶无酒名、无品牌/logo；手机去标；成片零字幕（唯一例外片尾金句②黑场）。
- **母板先行**：先出人物母板身份根，认可后各镜 --reference 母板（`masters-before-shot-keyframes`）。

## 五、验收（人眼判 · 不用程序）

- 脸有毛孔/细纹、暗部有轻微颗粒 → 像真拍；若脸光滑如蜡、画面干净无噪 → 打回。
- 光自然、不过曝、不 HDR 味；色不过饱和。
- 手持轻微晃动/浅景深真实，不是三脚架完美大片感。
- East Asian 随母板、明亮暖白看得清脸、白瓷瓶合规。
