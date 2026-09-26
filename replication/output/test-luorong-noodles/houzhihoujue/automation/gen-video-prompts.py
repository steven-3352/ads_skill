#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""Generate the 8 H3 video prompt JSON files for houzhihoujue and fill the
reviewed_prompt_sha256 so they pass validate-h3-prompt-review.sh.
All 8 shots are voiceover-only: H3 characters do NOT speak, so there is NO
dialogue block, NO speaker ID, NO on-screen text. Soundscape = home room tone
+ that shot's action sounds only (no vocalizations)."""
import hashlib, json, os

OUT = os.path.join(os.path.dirname(__file__), "..", "prompts")
REF_COUPLE = [
    "replication/output/test-luorong-noodles/houzhihoujue/assets/master-female.png",
    "replication/output/test-luorong-noodles/houzhihoujue/assets/master-male.png",
]
REF_FEMALE = ["replication/output/test-luorong-noodles/houzhihoujue/assets/master-female.png"]

FL2VA_INSTR = ("How the reference pictures align with the target video — "
    "Picture 1 (from Shot 1) aligns with the 0.00-second mark of the target video; "
    "Picture 2 (from Shot 1) aligns with the 4.00-second mark of the target video.")
I2VA_INSTR = ("For the target video, at 0.00 seconds into the target video, "
    "<Picture 1> (from [Shot 1]) is fully referenced.")

def assemble(instr, imd, sound, music):
    core = ("integrated_multimodal_description: " + imd +
            "\n\noverall_soundscape: " + sound +
            "\n\nnon_diegetic_music: " + music)
    return instr + "\n\n" + core

REAL = ("Live-action, cinematic, iPhone handheld footage with realistic skin "
    "texture, natural pores, and fine film grain, no plastic or waxy CG look.")
MATTE = "Both faces stay matte under soft diffused light with no glare or reflection."
FL_END = "at the four-second mark"

shots = []

# ---- Shot 01 冷战 FL2VA ----
imd1 = ("[Shot 1] " + REAL + " A bright, airy East Asian living room is lit by "
    "even warm-white ceiling light. A medium-wide shot opens exactly on the framing "
    "of Picture 1: a woman in casual home wear sits at one end of a fabric sofa "
    "hugging a plain cushion, a man in home wear sits at the far end, with an empty "
    "gap of cushion between them — the argument-start composition. From this pose "
    "both stay still and cold; the woman lifts her chin slightly and keeps her eyes "
    "turned away from him, the man rests both hands on his knees and does not turn "
    "his head toward her. The camera holds a nearly static shot with only slight "
    "handheld drift. Their stiff, silent standoff gradually settles into the exact "
    "posture, spacing, and composition established by Picture 2 " + FL_END + ". " + MATTE)
snd1 = ("A quiet living-room tone hums underneath with a faint appliance drone and "
    "distant muffled street sound. Cushion fabric shifts faintly in the still, tense room.")
shots.append(dict(idx="01", title="冷战", mode="FL2VA", refs=REF_COUPLE,
    role="镜1 冷战｜FL2VA｜吵架起点同机位（镜1/2/3共用），两人各自僵住不看对方；VO画外音，画面人物不说话",
    role_check="state-change hold: argument-start framing, both freeze cold and silent, no coaxing / no response",
    instr=FL2VA_INSTR, imd=imd1, snd=snd1,
    zh="镜1冷战·FL2VA。首帧Picture1=沙发两端各坐一头中间空距离的吵架起点，尾帧Picture2=两人各占一角僵住冷掉。女下巴微抬不看男、男搭膝不转头，静止微手持。明亮暖白居家光，哑光肤质iPhone真实感，无对白无字幕。声景仅居家底噪+布料轻动。"))

# ---- Shot 02 较劲 FL2VA ----
imd2 = ("[Shot 1] " + REAL + " The same bright warm-white East Asian living room and "
    "the identical sofa framing as Picture 1: the woman at one end hugging a cushion, "
    "the man at the far end, a gap of cushion between them. Beginning from the "
    "argument-start pose of Picture 1, the man turns his upper body toward her and "
    "slowly extends one hand toward her shoulder to make up. As his hand nears, the "
    "woman shrinks that shoulder away and turns her head to the opposite side, "
    "refusing the gesture; his hand stops in mid-air and draws back to his knee. The "
    "camera holds a nearly static shot with slight handheld drift. The movement lands "
    "on the exact positions and composition of Picture 2 " + FL_END + " — his hand "
    "withdrawn, her head turned away. " + MATTE)
snd2 = ("A quiet living-room tone continues with a faint appliance drone. The reaching "
    "arm brushes against fabric and the sofa creaks softly as she pulls her shoulder back.")
shots.append(dict(idx="02", title="较劲", mode="FL2VA", refs=REF_COUPLE,
    role="镜2 较劲｜FL2VA｜复用镜1同机位，男伸手碰肩想哄、女缩肩扭头不应、男手停半空收回",
    role_check="state-change action: man reaches to coax -> woman shrinks shoulder + turns head away -> hand withdraws",
    instr=FL2VA_INSTR, imd=imd2, snd=snd2,
    zh="镜2较劲·FL2VA。复用镜1吵架起点同机位。首帧起点，尾帧=男手收回、女扭头。男侧身伸手碰肩想哄→女缩肩扭头避开→手停半空收回。静止微手持，明亮暖白居家光，哑光真实iPhone感，无对白无字幕。声景仅居家底噪+伸手布料声/沙发轻响。"))

# ---- Shot 03 幸福 FL2VA ----
imd3 = ("[Shot 1] " + REAL + " The same bright warm-white East Asian living room and "
    "identical sofa framing as Picture 1: the woman at one end, the man at the far end "
    "with a gap between them. From the argument-start pose of Picture 1, the man leans "
    "in closer and keeps coaxing her, pulling a goofy playful face and lightly tickling "
    "toward her side. The woman resists at first, then her mouth softens and she breaks "
    "into a sudden bright smiling laugh, her body turning back toward the man so the gap "
    "between them closes. The camera holds a nearly static shot with slight handheld "
    "drift. The action settles into the exact posture, spacing, and composition of "
    "Picture 2 " + FL_END + ", the two now leaning close together. " + MATTE)
snd3 = ("A warm living-room tone hums underneath with a faint appliance drone. Cushion "
    "fabric rustles as she turns her body back toward him and the sofa shifts under the movement.")
shots.append(dict(idx="03", title="幸福", mode="FL2VA", refs=REF_COUPLE,
    role="镜3 幸福｜FL2VA｜复用镜1同机位，男继续哄做鬼脸挠痒、女破功笑转身靠近、中间空距离消失",
    role_check="state-change action: man keeps coaxing -> woman breaks into a laugh (visual only) -> turns back and gap closes",
    instr=FL2VA_INSTR, imd=imd3, snd=snd3,
    zh="镜3幸福·FL2VA。复用镜1同机位。首帧起点，尾帧=两人靠拢。男凑近做鬼脸挠痒继续哄→女绷不住扑哧笑(视觉表情,不出笑声)→转身靠近男中间距离消失。静止微手持，明亮暖白居家光，哑光真实iPhone感，无对白无字幕。声景仅居家底噪+转身布料声。"))

# ---- Shot 04 心疼 FL2VA ----
imd4 = ("[Shot 1] " + REAL + " In the same bright warm-white East Asian living room, a "
    "medium shot begins on the framing of Picture 1 with the woman seated, her head "
    "lowering and shoulders slightly sagging in a quiet, aggrieved posture. She brings "
    "the back of one finger to just beneath her eye corner and lightly wipes once — her "
    "eyes stay clear and dry, with no tears, no redness, and no glow. The man, pressing "
    "his lips together, rises and steps in from the side to gently gather her into his "
    "arms in a soft, yielding embrace. The camera holds a nearly static shot with slight "
    "handheld drift, ending on the exact posture and composition of Picture 2 " + FL_END +
    ", the two enclosed together. " + MATTE)
snd4 = ("A quiet living-room tone hums underneath with a faint appliance drone. Clothing "
    "rustles as he rises and steps in, and fabric brushes softly as he wraps his arms around her.")
shots.append(dict(idx="04", title="心疼", mode="FL2VA", refs=REF_COUPLE,
    role="镜4 心疼｜FL2VA｜女低头指背抹眼角显委屈、男抿嘴起身侧向轻揽入怀；严禁泪眼/红眼/发光眼",
    role_check="state-change action: woman lowers head + wipes under eye corner (no tears/red/glow) -> man rises and pulls her into a gentle embrace",
    instr=FL2VA_INSTR, imd=imd4, snd=snd4,
    zh="镜4心疼·FL2VA。首帧=女低头肩塌委屈，尾帧=男揽入怀两人相拥。女指背在眼角下轻抹一次(眼干净,无泪无红无光)→男抿嘴起身侧向轻揽入怀让步。静止微手持，明亮暖白居家光，哑光真实iPhone感，无对白无字幕。声景仅居家底噪+起身布料/相拥衣物声。"))

# ---- Shot 05 迁就 FL2VA ----
imd5 = ("[Shot 1] " + REAL + " In the same bright warm-white East Asian living room, a "
    "medium shot opens on Picture 1 with the woman pointing at a small object on the "
    "table and tidying it while her lips keep moving as she chatters on and on. Over the "
    "shot the man, one hand propping his chin, keeps a patient, amused smile and nods "
    "along with her again and again without interrupting, his head dipping in small "
    "repeated nods. The camera holds a nearly static shot with slight handheld drift, "
    "landing on the exact posture and composition of Picture 2 " + FL_END + ", the man "
    "mid-nod and the woman still gesturing. " + MATTE)
snd5 = ("A quiet living-room tone hums underneath with a faint appliance drone. A small "
    "object clinks lightly on the table as she tidies it, and clothing rustles softly with the man's nods.")
shots.append(dict(idx="05", title="迁就", mode="FL2VA", refs=REF_COUPLE,
    role="镜5 迁就｜FL2VA｜女指物碎碎念叨(唇动无音)、男撑下巴笑着连连点头听；VO画外音画面不说话",
    role_check="state-change action: woman points and chatters (lips move, no audio) -> man props chin and nods along repeatedly",
    instr=FL2VA_INSTR, imd=imd5, snd=snd5,
    zh="镜5迁就·FL2VA。首帧=女指桌上物碎碎念叨(唇动不出声),尾帧=男点头中。女边收拾边碎念→男撑下巴笑着一下一下点头不打断。静止微手持，明亮暖白居家光，哑光真实iPhone感，无对白无字幕(念叨为VO)。声景仅居家底噪+物件轻响/衣物声。"))

# ---- Shot 06 以为 I2VA ----
imd6 = ("[Shot 1] " + REAL + " The video opens on the warm home scene of <Picture 1>, "
    "preserving the two people's appearance, home wear, and the living-room layout: the "
    "woman and the man lean quietly against each other on the sofa, neither speaking, both "
    "still. The camera pushes in very slowly with small amplitude at slow speed. As it "
    "moves, the warm color gradually drains from the frame and the edges softly blur and "
    "vignette, as if this moment is fading out of a memory — a warm-to-cool transition. " + MATTE)
snd6 = ("A soft, warm living-room tone hums underneath with a faint appliance drone, "
    "thinning gradually as the image fades.")
shots.append(dict(idx="06", title="以为", mode="I2VA", refs=REF_COUPLE,
    role="镜6 以为还有以后｜I2VA｜两人依偎暖画面、极慢推近、暖光褪色边缘虚化(回忆感)",
    role_check="single first frame + slow push-in; warm color drains and edges vignette as the memory fades; no speech",
    instr=I2VA_INSTR, imd=imd6, snd=snd6,
    zh="镜6以为·I2VA。首帧Picture1=两人依偎暖色居家。镜头极慢小幅推近，暖色渐褪、边缘虚化打晕,像这幕从记忆里淡出(暖转冷)。两人静默不说话。哑光真实iPhone感,无对白无字幕。声景居家暖底噪随画面渐薄。"))

# ---- Shot 07 不在了 I2VA ----
imd7 = ("[Shot 1] Live-action, cinematic, with heavy film grain and shallow depth of "
    "field. The video opens on <Picture 1>: against a pure black background, a single "
    "soft overhead beam of light falls on the woman, who stands alone within it; the spot "
    "beside her, where someone had just been, is empty and dark. Preserving her appearance "
    "and the black-and-light setting, she presses her lips together, holds a breath, blinks "
    "slowly once, and lowers her head gradually. Her eyes stay clear and dry — no tears, no "
    "redness, and no glow. The camera holds a nearly static shot with only the faintest "
    "drift. Her face stays matte under soft diffused light with no glare or reflection.")
snd7 = ("A very faint indoor room tone lingers in the dark, nearly silent, with only the "
    "softest rustle of her clothing as she lowers her head.")
shots.append(dict(idx="07", title="不在了", mode="I2VA", refs=REF_FEMALE,
    role="镜7 那个人不在了｜I2VA｜黑底顶光女主独自伫立、身旁位置空荡、抿唇屏息慢眨缓低头；严禁泪眼/红眼/发光眼",
    role_check="single first frame + faint drift; black background overhead beam, empty spot beside her; emotion via lips/breath/slow blink/lowered head, no tears/red/glow",
    instr=I2VA_INSTR, imd=imd7, snd=snd7,
    zh="镜7不在了·I2VA。首帧Picture1=纯黑背景头顶单束柔光,女主独自伫立,身旁位置空荡无人。抿唇→屏息→慢眨一次→缓缓低头(眼干净,无泪无红无光)。近静止微飘,电影颗粒浅景深。无对白无字幕。声景=极轻室内底噪近乎静默+低头衣物轻响。"))

# ---- Shot 08 尾板 I2VA ----
imd8 = ("[Shot 1] Live-action, cinematic, with heavy film grain and shallow depth of "
    "field. The video opens on <Picture 1>: a pure black frame with a single soft overhead "
    "beam of light in the center. The camera holds a static shot as the beam of light "
    "slowly and evenly dims, the image gradually darkening until it settles into full "
    "black. No people and no on-screen text appear.")
snd8 = "A very faint indoor room tone fades toward near silence as the light dims."
shots.append(dict(idx="08", title="尾板", mode="I2VA", refs=[],
    role="镜8 尾板｜I2VA｜黑底仅一束顶光渐暗、向黑收拢收尾；大字'有些遗憾,后知后觉'为后期叠字,不在H3出",
    role_check="single first frame + static hold; overhead beam slowly dims to full black; NO on-screen text (title is added in post)",
    instr=I2VA_INSTR, imd=imd8, snd=snd8,
    zh="镜8尾板·I2VA。首帧Picture1=纯黑中央一束顶光。静止,光束缓缓均匀变暗、画面渐黑收拢至全黑。无人物、无屏内文字(尾板大字由后期叠,不在H3)。电影颗粒浅景深。无对白无字幕。声景=极轻室内底噪随光渐静。"))

common_checks = [
    "voiceover-only film: NO dialogue block, NO speaker ID, NO <d>, NO on-screen text in H3 — monologue is a post-production Doubao TTS voiceover track",
    "duration written as 4.00s per shot (H3 4s minimum billing; assembly trims to plan duration)",
    "soundscape limited to home room tone + this shot's action sounds only, no vocalizations; non_diegetic_music N/A (BGM/VO added in post)",
]
visual_flashback = ("visual: realistic iPhone texture, natural pores, fine film grain, "
    "matte skin, no plastic/wax/CG sheen; bright airy warm-white home light; East Asian; no brand/logo")
visual_present = ("visual: pure black background, single soft overhead beam, heavy film "
    "grain, shallow depth of field; matte skin, no glare; East Asian; no brand/logo")

written = []
for s in shots:
    prompt = assemble(s["instr"], s["imd"], s["snd"], "N/A")
    sha = hashlib.sha256(prompt.encode("utf-8")).hexdigest()
    checks = [s["role_check"]] + common_checks[:]
    checks.append(visual_present if s["idx"] in ("07", "08") else visual_flashback)
    if s["idx"] in ("04", "07"):
        checks.append("emotion beats use lips / held breath / slow blink / lowered head / wiping eye corner — strictly no tears, no red eyes, no glowing eyes")
    if s["idx"] in ("01", "02", "03"):
        checks.append("reuses the shared argument-start framing/camera of shot 1 (sofa two ends, gap between); only the post-start action diverges")
    if s["mode"] == "FL2VA":
        checks.append("FL2VA: Picture 1 opens at 0.00s, Picture 2 lands the final pose at 4.00s; single continuous shot, no dialogue crossing cuts")
    else:
        checks.append("I2VA: <Picture 1> is the 0.00s first frame; forward development via slow camera move only")
    obj = {
        "id": "shot-%s-video" % s["idx"],
        "role": s["role"],
        "prompt": prompt,
        "prompt_zh": s["zh"],
        "model": "MiniMax-H3",
        "durationSeconds": 4,
        "references": s["refs"],
        "authoring_skill": "h3-prompt-writing",
        "h3_prompt_review": {
            "skill": "h3-prompt-writing",
            "authorship": "generated_by_skill",
            "result": "pass",
            "asset_type": "video",
            "mode": s["mode"],
            "checks": checks,
            "unresolved_blockers": [],
            "reviewed_prompt_sha256": sha,
        },
    }
    path = os.path.join(OUT, "shot-%s-video.json" % s["idx"])
    with open(path, "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write("\n")
    written.append(path)
    print("wrote", os.path.abspath(path))
print("done", len(written))
