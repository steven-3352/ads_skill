# 《后来》独唱锚镜 · H3 对口型配方(已由用户看片通过)

> 通过样本:task `01a0bde6-5c0a-7ee1-ad9a-76da988a0831` = `houlai-mv/videos/VID-S01.mp4`(16:9 1344×768 / 4.46s)。
> **判定以人眼看片为准**;音频 corr 互相关**不作为通过标准**(此片 corr 很低仍被判对,corr 会误导,已弃用为门禁)。
>
> **重要:H3 不会真的保留《后来》原声。** 实测它总是把《后来》段当参考、自己合成一条哼唱音轨(corr≈0.02)。参考音频的作用只是**驱动嘴型时值**,不是把原声带进成片。所以:成片里 **H3 每条片段的音轨一律丢弃**,全片**后期统一铺真《后来》原曲**;锚镜只取"会唱的嘴型画面"。审阅时给用户看的应是"画面 + 后期铺原声"的 muxed 版(见 `houlai-mv/videos/withsong/`)。

## 一句话
极简、直给的 prompt + `reference_image`(锁身份/黑场/顶光)+ `reference_audio`(《后来》人声段)喂 H3,让口型跟参考音频走;**不要**用六段式 Ref2VA 里的 `overall_soundscape`/`non_diegetic_music` 声景创作段——那会让 H3 自己合成一条音轨、无视参考音频(上一版失败根因:人声不是《后来》、口型不对)。

## 请求形态(generate-video.sh --provider minimax,H3 v2,REF_MODE)
- model: `MiniMax-H3`
- content(顺序): `[{type:text,text:PROMPT}, {reference_image}, {reference_audio}]`
  - reference_image = 该锚镜关键帧(1344×768,黑场顶光女主;S05/S11 复用 S01 同帧)
  - reference_audio = 《后来》对应人声段,mp3(**stereo 也可**),时长 ≈ duration
- duration: 整数秒,≈ 参考音频长度(S01=4)
- resolution: `768P`
- **不设 ratio**(REF_MODE 省略 ratio,adaptive 跟随 1344×768 关键帧 → 输出 16:9)
- 不带 generate_audio 标志(此路径本就忽略它;跟它无关)

## PROMPT 写法(极简 · 无声景创作 · 无歌词)
要点顺序:
1. 主体用"the same … woman from the reference image"引用,锁身份;
2. 场景:纯黑场 + 一束顶光,"exactly matching the reference image";
3. 动作:她克制含泪地唱;
4. **对口型句(关键)**:"Her lips, teeth and jaw move in precise synchronization with the provided reference audio.";
5. **压杂音句(关键)**:"Keep the provided reference audio as the actual sound of the shot; do NOT add, replace or generate any other voice, singing, music, room tone or ambience."(**注**:这句作用是压掉 H3 自加的杂音、约束它只跟参考走;它**并不能**真让 H3 保住《后来》原声——H3 照样自造哼唱,原声后期铺);
6. 情绪小节拍(一滴泪)+ 镜头近乎不动;
7. 负面:no other person / no on-screen text / no subtitles / **no lyrics**。

S01 通过版 PROMPT 见 `houlai-mv/prompts/VID-S01.json`(sha256 已入审阅块)。

## 复刻 S05 / S11
- reference_image:复用 `KF-S01-first.png`。
- reference_audio:分别精切《后来》对应句(S05≈6s、S11≈11s),trim 到 ≈ duration。
- duration:按各锚镜时长(S05=6、S11=11;注意 H3 上限,见下)。
- PROMPT:照 S01 模板,仅改情绪描述(S05 眼神由暖转凉;S11 泪落释然中的痛),其余(黑场顶光 + 对口型句 + 保音轨句 + 无歌词)不动。

## 血泪教训
- **别用 corr 做门禁**:媒体好坏人眼判(项目铁律),corr 与"用户满意"不一致。
- **别写声景创作段**:任何"应该有什么声音/音乐/底噪"的描述都会诱发 H3 自造音轨、丢弃参考音频。
- 失败对照:上一版六段式(带 `overall_soundscape`)→ 人声不是《后来》、口型错;本极简版 → 通过。
- **情绪词要直给、别含蓄**(S05 v1 打回教训):写 "warm remembrance / gaze cools" 这类含蓄词,H3 会渲成**带笑的柔和脸**。要什么情绪就明写"sorrowful/withdrawn/distant/**does NOT smile**",并明确"singing, mouth clearly opening and moving"逼出唱的嘴型。
- **人声段响度要够**(S05 v1 打回教训):参考音频偏轻(均响 −22dB、开头近静音)→ H3 嘴型很弱、几乎不张。生成前把人声段增益到 ≈ −16dB(`volume=6dB,alimiter=limit=0.95`),嘴型才张得开。S01 −16.9 / S11 −13.3 都够;S05 原始 −22.9 需补。
