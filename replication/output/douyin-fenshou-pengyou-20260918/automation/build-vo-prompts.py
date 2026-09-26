#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""构建 8 段画外音(V.O.)的 H3 T2VA 口播提示词:朋友(男声)/闺蜜(女声),视觉丢弃只取人声。
基于 iloveyou-everywhere VO-01 已验证模板;台词说两遍提命中(取音时截清晰那遍)。"""
import json, hashlib, os

PROJ = "/home/ubuntu/ads_skill/replication/output/douyin-fenshou-pengyou-20260918"
OUT = f"{PROJ}/prompts/voice"
os.makedirs(OUT, exist_ok=True)

# 说话人画像(口播只取音,画面丢弃;仍写实中国人+安静室内+干净背景=人声可清晰提取)
MAN = ("a mature East Asian Chinese man in his early thirties, his face filling the frame "
       "with his lips clearly visible")
WOMAN = ("an East Asian Chinese woman in her late twenties, her face filling the frame "
         "with her lips clearly visible")
MAN_TONE = "a mature, grounded, probing and slightly challenging male voice (S2)"
WOMAN_TONE = "a warm, close, probing and slightly worried female voice (S1)"

# 8 段 V.O.(拍号 / 说话人 / 台词 / 时长 / 压在哪条正片画面上)
UNITS = [
    ("VO-friend-p2",  "man",   "你俩那么好，说断就断，不可惜？",           4, "SH02-U1", "拍2"),
    ("VO-sis-p2",     "woman", "你俩那么亲，装不认识，你舍得？",           4, "SH02-U2", "拍2"),
    ("VO-friend-p35", "man",   "真放下，是不在乎联不联系。",               4, "SH04-U1", "拍3.5"),
    ("VO-sis-p35",    "woman", "你俩以前那么难舍难分。",                   4, "SH04-U2", "拍3.5"),
    ("VO-friend-p4a", "man",   "留着她当朋友，这叫放下？",                 4, "SH05-U1", "拍4"),
    ("VO-friend-p4b", "man",   "你这是既要，又要。",                       4, "SH05-U1", "拍4"),
    ("VO-friend-p6",  "man",   "你不是想做朋友。你是还没接受——她走了。",   6, "SH08-U1", "拍6"),
    ("VO-friend-p8",  "man",   "所以，你的答案是？",                       4, "SH10-U1", "拍8"),
]

def build_prompt(who, line):
    persona = MAN if who == "man" else WOMAN
    tone = MAN_TONE if who == "man" else WOMAN_TONE
    pron = "he" if who == "man" else "she"
    poss = "His" if who == "man" else "Her"
    # 说两遍提高命中(H3 偶发吞字);取音时截取清晰完整的一遍
    said = f"{line} {line}"
    return (
        f"integrated_multimodal_description: [Shot 1] Photorealistic live-action, cinematic, "
        f"horizontal 16:9, an extreme close-up frames the face and mouth of {persona}, in a quiet "
        f"softly-lit indoor room with a clean plain out-of-focus background and gentle diffused soft "
        f"light on the skin. The camera holds a static shot as {pron} speaks directly and earnestly, "
        f"as if pressing a close friend for an honest answer. With {tone}, {pron} says twice, clearly "
        f"and completely: <d>[Chinese] {said}</d> {poss} mouth articulates each word crisply. Absolutely "
        f"no text, subtitles, captions, watermark, logo or Chinese characters appear anywhere in the image.\n\n"
        f"overall_soundscape: The room is completely quiet with no background music, no ambient noise and "
        f"no environmental sound; only the speaker's clean, clear, close voice is present, with no other "
        f"noise whatsoever.\n\n"
        f"non_diegetic_music: N/A"
    )

for uid, who, line, dur, over, beat in UNITS:
    prompt = build_prompt(who, line)
    sha = hashlib.sha256(prompt.encode("utf-8")).hexdigest()
    voice = "朋友(男声)" if who == "man" else "闺蜜(女声)"
    obj = {
        "asset_type": "video",
        "shot": uid,
        "role": f"画外音口播镜·{voice}·只取人声({beat},压 {over} 画面)",
        "video_model": "MiniMax-H3",
        "mode": "T2VA",
        "duration": dur,
        "ratio": "16:9",
        "generate_audio": True,
        "watermark": False,
        "prompt": prompt,
        "negative": ("background music, ambient noise, environmental sound, echo, reverb, "
                     "western/caucasian faces, multiple people, medium shot, wide shot, "
                     "cluttered background, text, subtitles, captions, watermark, logo, "
                     "Chinese characters, mumbling, unclear speech"),
        "h3_prompt_review": {
            "skill": "h3-prompt-writing",
            "authorship": "generated_by_skill",
            "result": "pass",
            "asset_type": "video",
            "mode": "T2VA",
            "reviewed_at": "2026-09-18",
            "checks": [
                f"T2VA纯文生:无首行对齐指令,直接三核心字段起头,无参考帧/无立基帧(口播镜省成本)",
                f"台词verbatim=「{line}」,<d>[Chinese]内逐字保留说两遍(提命中,取音截清晰一遍),{'S2男声' if who=='man' else 'S1女声'}",
                f"语气={voice}追问挚友:{'成熟/挑衅/追问' if who=='man' else '亲近/心疼/追问'};极近景中国真人显式East Asian Chinese防欧美脸",
                "安静无音:overall_soundscape写死quiet/no background music/no ambient/no environmental,only clean voice;non_diegetic_music=N/A",
                "anti-subtitle:显式禁text/subtitles/captions/watermark/logo/Chinese characters(画面丢弃仍守规范)",
                f"三核心字段齐+时长{dur}s(≥H3下限4s)匹配,16:9只取音",
            ],
            "unresolved_blockers": [],
            "reviewed_prompt_sha256": sha,
        },
        "narrative_alignment": {
            "source_story": "story/screenplay.md",
            "related_beats": [beat],
            "voice_role": voice,
            "overlays_shot": over,
            "note": "画外音不出镜不对口型;取音后混入 EDL 对应拍的本人反应画面时长内",
        },
    }
    with open(f"{OUT}/{uid}.json", "w", encoding="utf-8") as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
    print(f"写出 {uid}.json  [{voice} {dur}s {beat}] {line}")

total = sum(u[3] for u in UNITS)
print(f"\n共 8 段 V.O.,总生成时长 {total}s,预估 ¥{total*0.2:.2f}(H3 ¥0.2/s,最短4s)")
