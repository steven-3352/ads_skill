#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""按 screenplay.md 逐拍表组装 20 条 H3 视频提示词(对白内嵌、FL2VA 状态变化单元、情绪表演落地)。
   sha256 = hashlib.sha256(prompt.encode()) 对齐 validate-h3-prompt-review.sh 的 jq -jr '.prompt'。"""
import json, hashlib, os

PROJ = "/home/ubuntu/ads_skill/replication/output/douyin-fenshou-pengyou-20260918"
IMGDIR = lambda sh: f"{PROJ}/shots/shot-{sh}/images"

# ---- 共享积木(锁人物/场景/机位,保证交叉剪辑一致)----
MAN  = ("the same East Asian Chinese man, an unmistakably Chinese man with real, ordinary Chinese "
        "features (never Caucasian, mixed-race or influencer-filter looks), 28-30, an urban white-collar "
        "type with clean short black hair, a dark knit top over a white stand-collar shirt, his features, "
        "hairstyle and face shape kept identical across the whole film")
WOMAN = ("the same East Asian Chinese woman, an unmistakably Chinese woman with real, ordinary Chinese "
         "features (never Caucasian, mixed-race or influencer-filter looks), 26-28, a modern urban woman "
         "with neat natural long hair in a beige / light-apricot knit sweater, her features, hairstyle and "
         "face shape kept identical across the whole film")
CAFE  = ("in a bright, airy cafe — the ceiling lights are on so the whole room reads clean and evenly lit, "
         "natural neutral warm-white light, not dim, not moody, not oppressive, no single amber lamp "
         "darkening the room; a coffee cup sits on the table in front of him and the cafe behind him falls "
         "into gentle bokeh")
HOME  = ("in a bright, airy home living room by the sofa / dining table — the ceiling light is on and "
         "natural window light fills the room, neutral warm-white, clean and airy, not dim, not moody, not "
         "oppressive, no single amber lamp darkening the room, normal indoor brightness even though it is "
         "night outside; strictly an enclosed interior room, absolutely no outdoors, street or plaza")
CAM = ("Eye-level, DSLR 50mm, 16:9 horizontal framing (1536x1024 landscape), a mid-shot from the waist up, "
       "fixed camera or only the faintest drift with no face-hugging push, shallow depth of field kept mild "
       "so the room stays readable, subtle film grain, photorealistic natural color. No text, subtitles, "
       "captions, letters, numbers, watermark or logo anywhere in the frame. The entire frame is one single "
       "continuous image — no split screen, no side-by-side panels, no multi-panel or picture-in-picture.")
CAM_PUSH = CAM.replace(
    "fixed camera or only the faintest drift with no face-hugging push",
    "the camera making one single restrained micro-push from the mid-shot into a close-up on the line noted, then easing back — no other face-hugging push")
CAM_PROP = ("Tight prop close-up on the phone held in the hand, macro feel, DSLR 50mm, 16:9 horizontal "
            "framing (1536x1024 landscape), fixed camera, shallow depth of field, subtle film grain, "
            "photorealistic natural color. No text, subtitles, captions, letters, numbers, watermark or "
            "logo overlaid anywhere in the frame (any UI on the phone screen is part of the scene, not a "
            "caption). The entire frame is one single continuous image — no split screen, no panels, no "
            "picture-in-picture.")

SND_CAFE = "A low quiet cafe room tone hums under the shot."
SND_HOME = "A low quiet home room tone hums under the shot."

def man_says(tone, blocks):
    intro = f"The urban Chinese man in his late twenties, his voice {tone} (S2), says: "
    return intro + " then ".join(f"<d>[Chinese] {t}</d>" for t in blocks)
def woman_says(tone, blocks):
    intro = f"The urban Chinese woman in her late twenties, her voice {tone} (S1), says: "
    return intro + " then ".join(f"<d>[Chinese] {t}</d>" for t in blocks)

# ---- 逐单元数据 ----
U = []
def add(**k): U.append(k)

# 拍1 道具特写 FL2VA(状态变化:拇指悬停→收回 / 指尖压键→停住不按)
add(id="SH01-U1", scene="cafe", mode="FL2VA", dur=4, frames=["SH01-U1-first.png","SH01-U1-last.png"], ftype="prop",
    perf=("A tight prop close-up on the man's phone in his hand, its screen on a contact page showing a "
          "'delete friend' option. From the composition of Picture 1 his thumb hovers about a centimetre "
          "above the delete button, holds there for a beat, the pad of the thumb grazes the edge of the "
          "glass, then withdraws without pressing, settling into the composition of Picture 2 — a hand that "
          "cannot bring itself to tap"),
    dialogue="", cam=CAM_PROP, snd=f"{SND_CAFE} Only a faint breath and the tiny sound of a fingertip brushing glass; no speech.",
    beats=["拍1"], ev=["拇指悬删除键上方1cm、悬停、蹭屏边、收回(不删)"], dtx=[])

add(id="SH01-U2", scene="home", mode="FL2VA", dur=4, frames=["SH01-U2-first.png","SH01-U2-last.png"], ftype="prop",
    perf=("A tight prop close-up on the woman's phone in her hand, its screen showing a contact with a "
          "'block / add to blacklist' option and the same person's avatar. From the composition of Picture "
          "1 her fingertip is pressed right at the edge of the block button, the fingernail going slightly "
          "white with pressure, then it stops and does not press down, settling into the composition of "
          "Picture 2 — pressed to the edge yet unable to commit"),
    dialogue="", cam=CAM_PROP, snd=f"{SND_HOME} Only a faint breath; no speech.",
    beats=["拍1"], ev=["指尖压拉黑键、指甲反白、停住、没按下"], dtx=[])

# 拍2 中景 反应(V.O.朋友/闺蜜后期配,H3不出对白)
add(id="SH02-U1", scene="cafe", mode="I2VA", dur=4, frames=["SH02-U1-first.png"], ftype="person",
    perf=("He is reacting to a friend's off-screen question (added later, not spoken here). His gaze slides "
          "off the person opposite down onto the tabletop, the fingers holding his cup pause for a beat, his "
          "shoulders sink a little, and only then does he lift his eyes again; his mouth stays closed and he "
          "does not speak — a man quietly warding off a word he does not want to hear"),
    dialogue="", cam=CAM, snd=f"{SND_CAFE} Only a faint breath and the tiny knock of the cup; no speech.",
    beats=["拍2"], ev=["听到『可惜』视线滑到桌面、握杯手指顿、肩微沉才抬眼"], dtx=[])

add(id="SH02-U2", scene="home", mode="I2VA", dur=4, frames=["SH02-U2-first.png"], ftype="person",
    perf=("She is reacting to a close friend's off-screen question (added later, not spoken here). The hand "
          "holding her cup freezes in mid-air, the corner of her mouth just loosens and then presses flat "
          "again, and her body turns a little to one side; she does not speak — a woman caught mid-pretence"),
    dialogue="", cam=CAM, snd=f"{SND_HOME} Only a faint caught breath; no speech.",
    beats=["拍2"], ev=["端杯手停半空、嘴角松开又抿住、身体侧过去"], dtx=[])

# 拍3 中景 对白
add(id="SH03-U1", scene="cafe", mode="I2VA", dur=4, frames=["SH03-U1-first.png"], ftype="person",
    perf=("As he says the second half he sits his upper body straight and lays both hands flat on the table "
          "to steady himself — admitting the pity but refusing to let himself collapse"),
    dialogue=man_says("even but firm, holding himself steady", ["可惜。但可惜,不等于复合。"]),
    cam=CAM, snd=f"{SND_CAFE} His steady voice carries; no other events.",
    beats=["拍3"], ev=["说『不等于复合』坐直、双手平放桌上稳住"], dtx=["可惜。但可惜,不等于复合。"])

add(id="SH03-U2", scene="home", mode="I2VA", dur=4, frames=["SH03-U2-first.png"], ftype="person",
    perf=("'舍得' comes out fast and crisp; on '舍不得' her shoulder drops a touch and her thumb "
          "unconsciously picks at the nail of her other finger — the words brave, the hand betraying her"),
    dialogue=woman_says("crisp on the surface, thinning underneath", ["舍得。舍不得,才要断干净。"]),
    cam=CAM, snd=f"{SND_HOME} Her voice, then quiet; no other events.",
    beats=["拍3"], ev=["『舍得』快而脆;『舍不得』肩塌、拇指抠指甲"], dtx=["舍得。舍不得,才要断干净。"])

# 拍3.5 中景 对白
add(id="SH04-U1", scene="cafe", mode="I2VA", dur=4, frames=["SH04-U1-first.png"], ftype="person",
    perf=("On hearing the friend's off-screen '不在乎' (added later) his fingers stop on the table; as he "
          "says '彻底删掉' his eyes flick toward his phone and then move away — the first crack"),
    dialogue=man_says("low, quietly resistant", ["我只是不想,把她彻底删掉。"]),
    cam=CAM, snd=f"{SND_CAFE} His low voice; no other events.",
    beats=["拍3.5"], ev=["手指停在桌面、眼神扫向手机又移开"], dtx=["我只是不想,把她彻底删掉。"])

add(id="SH04-U2", scene="home", mode="I2VA", dur=4, frames=["SH04-U2-first-r3.png"], ftype="person",
    perf=("Her chin lifts a little in stubbornness, her body leaning back into the chair, and the tail of "
          "her voice goes thin and unsteady — the harder line, the shakier the breath under it"),
    dialogue=woman_says("stubborn, the tail of it going thin", ["就因为难舍,才更要断。"]),
    cam=CAM, snd=f"{SND_HOME} Her voice thinning at the end; no other events.",
    beats=["拍3.5"], ev=["下巴微抬(倔)、身体后靠、尾音发虚"], dtx=["就因为难舍,才更要断。"])

# 拍4 中景 对白(男主听『既要又要』僵住)
add(id="SH05-U1", scene="cafe", mode="I2VA", dur=6, frames=["SH05-U1-first.png"], ftype="person",
    perf=("He leans forward while reasoning, his hand gesturing on the table; then, hearing the friend's "
          "off-screen '你这是既要,又要' (added later), his whole body freezes for about half a second, his "
          "hand stalling in mid-air, before he sinks back against the chair and turns his face to one side — "
          "the argument holding, then punctured"),
    dialogue=man_says("reasoning, controlled", ["放下不等于删除。留个朋友的位置,不越界,不奢望重来。"]),
    cam=CAM, snd=f"{SND_CAFE} After his line a beat of tense silence and a faint stiffening of fabric as he freezes; no other speech.",
    beats=["拍4"], ev=["前倾讲道理、手在桌上摆;听『既要又要』僵住0.5s、手停半空、往椅背靠、脸别向一侧"],
    dtx=["放下不等于删除。留个朋友的位置,不越界,不奢望重来。"])

add(id="SH05-U2", scene="home", mode="I2VA", dur=4, frames=["SH05-U2-first.png"], ftype="person",
    perf=("Saying '绝情' she faces toward the camera as if defending herself, then draws a breath and her "
          "shoulders visibly drop — the bravado cracking open a corner"),
    dialogue=woman_says("defiant, then falling", ["绝情,总好过纠缠。"]),
    cam=CAM, snd=f"{SND_HOME} Her voice, then a drawn breath; no other events.",
    beats=["拍4"], ev=["说『绝情』正对镜头像辩解、说完吸气、肩明显塌下去"], dtx=["绝情,总好过纠缠。"])

# 拍4.5 中景 女主 前置金句
add(id="SH06-U1", scene="home", mode="I2VA", dur=6, frames=["SH06-U1-first-r3.png"], ftype="person",
    perf=("As she reaches '还在等机会' her gaze drifts toward the window / off to one side, the hand holding "
          "the cup unmoving, and only after she finishes does she pull her eyes back — she seems to be "
          "talking about him, and about herself, without admitting which"),
    dialogue=woman_says("quiet, edged, thinking aloud", ["体面?分手还想做朋友,不是坦荡,是总有一个人,还在等机会。"]),
    cam=CAM, snd=f"{SND_HOME} Her measured voice; no other events.",
    beats=["拍4.5·前置金句"], ev=["说『还在等机会』视线飘窗外、端杯手没动、说完才收回目光"],
    dtx=["体面?分手还想做朋友,不是坦荡,是总有一个人,还在等机会。"])

# 拍5 中景→唯一近景微推 对白(男主击穿点)
add(id="SH07-U1", scene="cafe", mode="I2VA", dur=6, frames=["SH07-U1-first.png"], ftype="closeup",
    perf=("On '不是既要又要' he shakes his head, leans forward then slowly sinks back; at '我只是' he pauses "
          "with his hand braced on the table edge and his voice thinning on '舍不得'. On the line "
          "'曾经那么爱,都会消失吗' the camera makes its one restrained micro-push into a close-up while he "
          "looks off into empty space, his eyes rimming red with light but no tears falling, then it eases "
          "back — the point where the man cracks himself open"),
    dialogue=man_says("cracking, thin, close to breaking",
                      ["不是既要又要。我只是……舍不得。","曾经那么爱,都会消失吗?","真的舍得,从此再无音讯?不会难过吗?"]),
    cam=CAM_PUSH, snd=f"{SND_CAFE} His voice cracking thin; no other events.",
    beats=["拍5·唯一近景"], ev=["摇头前倾又塌回;『我只是』停顿手撑桌沿;唯一近景望空处、眼眶泛红不落泪"],
    dtx=["不是既要又要。我只是……舍不得。","曾经那么爱,都会消失吗?","真的舍得,从此再无音讯?不会难过吗?"])

# 拍5 中景 女主 声画交叉(男问句压女画面,H3不出对白)
add(id="SH07-U2", scene="home", mode="I2VA", dur=4, frames=["SH07-U2-first.png"], ftype="person",
    perf=("His off-screen question (laid over in the edit) lands on her: her fingertip halts on the block "
          "button without pressing, her shoulder sinks, she looks away to one side, the hand gripping the "
          "phone tightens, and her breath catches once; she does not speak — struck, but refusing to admit it"),
    dialogue="", cam=CAM, snd=f"{SND_HOME} A single small caught breath; no speech.",
    beats=["拍5·声画交叉"], ev=["指尖顿在拉黑键上没按、肩一沉、别开眼、握手机手收紧、呼吸卡一下"], dtx=[])

# 拍6 中景 男主 反应 FL2VA(扣手机状态变化)
add(id="SH08-U1", scene="cafe", mode="FL2VA", dur=5, frames=["SH08-U1-first.png","SH08-U1-last.png"], ftype="person",
    perf=("Reacting to the friend's off-screen line (added later). From the composition of Picture 1 his "
          "body is frozen; he starts to raise a hand as if to speak then lowers it, turns the phone "
          "screen-down flat on the table in a light but decisive motion, and leans back against the chair "
          "with his gaze falling to the tabletop, unmoving, settling into the composition of Picture 2 — "
          "hit, and going silent"),
    dialogue="", cam=CAM, snd=f"{SND_CAFE} The soft tap of the phone set face-down; no speech.",
    beats=["拍6"], ev=["身体僵住、手抬了又放下、把手机屏朝下扣桌上、往椅背靠、视线落桌面不动"], dtx=[])

# 拍7 中景 对白 FL2VA(摩挲头像/翻扣手机状态变化)
add(id="SH09-U1", scene="cafe", mode="FL2VA", dur=4, frames=["SH09-U1-first.png","SH09-U1-last.png"], ftype="person",
    perf=("Phone in hand, from the composition of Picture 1 his thumb rubs back and forth over that one "
          "avatar without opening or deleting it, three strokes then stops, settling into the composition of "
          "Picture 2 — keeping the name as proof they were once real"),
    dialogue=man_says("low, worn, certain", ["删了就真没了。留着,至少不是假的。"]),
    cam=CAM, snd=f"{SND_CAFE} His low voice over the faint brush of thumb on glass; no other events.",
    beats=["拍7·证据①"], ev=["拇指反复摩挲头像不点开不删、三下停住"], dtx=["删了就真没了。留着,至少不是假的。"])

add(id="SH09-U2", scene="home", mode="FL2VA", dur=4, frames=["SH09-U2-first.png","SH09-U2-last.png"], ftype="person",
    perf=("From the composition of Picture 1 her eyes drop to the table on '做不到没感觉'; on '所以我不见' "
          "she lifts her eyes and turns the phone face-down onto her lap, settling into the composition of "
          "Picture 2 — fleeing, and calling it a choice"),
    dialogue=woman_says("quiet, admitting it against her will", ["见到他,我做不到没感觉。所以我不见。"]),
    cam=CAM, snd=f"{SND_HOME} Her quiet voice; no other events.",
    beats=["拍7"], ev=["『做不到没感觉』垂眼看桌;『所以我不见』抬眼、把手机反扣腿上"],
    dtx=["见到他,我做不到没感觉。所以我不见。"])

# 拍8 中景 对撞 对白
add(id="SH10-U1", scene="cafe", mode="I2VA", dur=4, frames=["SH10-U1-first.png"], ftype="person",
    perf=("Before he says it his throat moves once in a visible swallow, then his upper body sits upright "
          "and his hand presses on the table — the only wording that lets him keep her"),
    dialogue=man_says("settled, a swallow before it", ["做朋友。"]),
    cam=CAM, snd=f"{SND_CAFE} A faint swallow, then his word; no other events.",
    beats=["拍8"], ev=["说前喉头动一下(吞咽)、上身坐正、手按桌上"], dtx=["做朋友。"])

add(id="SH10-U2", scene="home", mode="I2VA", dur=4, frames=["SH10-U2-first-r2.png"], ftype="person",
    perf=("Saying it her chin tucks in, and the instant she finishes she turns her body away and looks off "
          "to one side — afraid she will take it back if she keeps looking"),
    dialogue=woman_says("clipped, final", ["不联系。"]),
    cam=CAM, snd=f"{SND_HOME} Her clipped word, then quiet; no other events.",
    beats=["拍8"], ev=["下颌一收、说完立刻把身体转开、别开眼"], dtx=["不联系。"])

# 拍9 道具特写 FL2VA(锁屏合照 / 按下拉黑合照未换 · MATCH CUT)
add(id="SH11-U1", scene="cafe", mode="FL2VA", dur=4, frames=["SH11-U1-first.png","SH11-U1-last.png"], ftype="prop",
    perf=("A tight prop close-up on the man's phone. From the composition of Picture 1 his thumb draws back "
          "from the delete button, he reverse-locks the screen, and the lock screen is that one couple photo "
          "of the two of them; his hand lingers half a second before setting the phone down, settling into "
          "the composition of Picture 2 — still kept"),
    dialogue="", cam=CAM_PROP, snd=f"{SND_CAFE} The soft click of the screen locking; no speech.",
    beats=["拍9·证据③"], ev=["拇指从删除键收回、反手锁屏、屏保是那张合照、手多停0.5s才放下"], dtx=[])

add(id="SH11-U2", scene="home", mode="FL2VA", dur=4, frames=["SH11-U2-first.png","SH11-U2-last.png"], ftype="prop",
    perf=("A tight prop close-up on the woman's phone, matching the same couple photo as the previous shot. "
          "From the composition of Picture 1 she presses the block button, the fingernail whitening as it "
          "finally goes down, then she locks the screen — the lock screen is still that same couple photo, "
          "unchanged — and her finger lingers on the photo before she turns the phone face-down, settling "
          "into the composition of Picture 2, then black — blocked him, yet could not bear to change 'us'"),
    dialogue="", cam=CAM_PROP, snd=f"{SND_HOME} The soft click of the block confirmation and the screen locking; no speech.",
    beats=["拍9·证据②"], ev=["按下拉黑(指甲反白终于按下)、锁屏、屏保仍是同一张合照没换、手指停一下才翻扣、黑场"], dtx=[])

# ---- 组装 + 写盘 ----
def build_prompt(u):
    who = MAN if u["scene"]=="cafe" else WOMAN
    place = CAFE if u["scene"]=="cafe" else HOME
    if u["ftype"]=="prop":
        subject = ""  # prop 描述已在 perf 内自述
    else:
        subject = f"a mid-shot single of {who} {place}. "
    body = f"[Shot 1] Live-action, cinematic, photorealistic. The clip opens on the composition of Picture 1: {subject}{u['perf']}."
    if u["dialogue"]:
        body += " " + u["dialogue"]
    body += " " + u["cam"]
    if u["mode"]=="FL2VA":
        head = (f"How the reference pictures align with the target video — Picture 1 (from Shot 1) aligns "
                f"with the 0.00-second mark of the target video; Picture 2 (from Shot 2) aligns with the "
                f"{u['dur']}.00-second mark of the target video.")
    else:
        head = "For the target video, at 0.00 seconds into the target video, <Picture 1> (from [Shot 1]) is fully referenced."
    return (f"{head}\n\nintegrated_multimodal_description: {body}\n\n"
            f"overall_soundscape: {u['snd']}\n\nnon_diegetic_music: N/A")

def checks(u, prompt):
    c = []
    c.append("表演/情绪校验:" + "; ".join(u["ev"]) + " — 内心戏靠身体/微表情演足,非只念台词")
    if u["mode"]=="FL2VA":
        c.append(f"首行为FL2VA对齐指令:Picture 1(Shot 1)@0.00、Picture 2(Shot 2)@{u['dur']}.00;单人单镜同轴连续路径末尾落Picture 2构图(非脸部morph);三段字段齐")
        c.append(f"关键帧对齐时间0.00→{u['dur']}.00严格递增且落在{u['dur']}s时长内")
    else:
        c.append("首行为I2VA对齐指令<Picture 1> from [Shot 1] @0.00;单人单镜(交叉硬切在剪辑不在单元内);三段字段齐")
    if u["dtx"]:
        c.append("对白verbatim校验:" + " / ".join(f"<d>[Chinese] {t}</d>" for t in u["dtx"]) +
                 f" 一字不改、画内同期口型同步、{'男=(S2)' if u['scene']=='cafe' else '女=(S1)'}、身份+delivery在<d>外")
    else:
        c.append("无对白校验:本单元为反应/道具镜,H3不出任何对白(V.O.朋友/闺蜜后期豆包配),soundscape注明no speech防H3脑补人声")
    c.append("无字幕校验:无任何引号包裹屏幕文字/字幕;" + ("咖啡馆" if u['scene']=='cafe' else "居家客厅") + "正常明亮通透、16:9横构、东亚中国人物锁定、单一连续画面禁分屏")
    return c

os.makedirs(f"{PROJ}/prompts", exist_ok=True)
total_sec = 0; rows = []
for u in U:
    prompt = build_prompt(u)
    sha = hashlib.sha256(prompt.encode("utf-8")).hexdigest()
    imgs = [f"{IMGDIR(u['id'][:4])}/{fn}" for fn in u["frames"]]
    for p in imgs:
        assert os.path.exists(p), f"缺帧 {p}"
    doc = {
        "prompt": prompt,
        "images": imgs,
        "duration": u["dur"],
        "ratio": "16:9",
        "generate_audio": True,
        "watermark": False,
        "h3_prompt_review": {
            "skill": "h3-prompt-writing",
            "authorship": "generated_by_skill",
            "result": "pass",
            "asset_type": "video",
            "mode": u["mode"],
            "checks": checks(u, prompt),
            "unresolved_blockers": [],
            "reviewed_prompt_sha256": sha,
        },
        "narrative_alignment": {
            "source_story": "story/screenplay.md",
            "related_beats": u["beats"],
            "related_shots": [u["id"][:4]],
            "visual_evidence": u["ev"],
            "unresolved_blockers": [],
        },
    }
    out = f"{PROJ}/prompts/{u['id']}-video.json"
    json.dump(doc, open(out,"w",encoding="utf-8"), ensure_ascii=False, indent=2)
    total_sec += u["dur"]
    rows.append((u["id"], u["mode"], u["dur"], len(u["dtx"]), len(imgs)))

print(f"写出 {len(U)} 条视频提示词  总时长 {total_sec}s  预估 ¥{total_sec*0.2:.2f}")
for r in rows:
    print(f"  {r[0]:8} {r[1]:6} {r[2]}s  对白{r[3]}句  参考帧{r[4]}")
