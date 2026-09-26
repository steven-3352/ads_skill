#!/usr/bin/env python3
# 生成《后来》MV 剩余关键帧提示词 JSON（带 h3-prompt-writing 审阅块 + sha256）
import json, hashlib, os

OUT = "replication/output/houlai-mv/prompts"
MA = "replication/output/you-budong-me/assets/master-A.png"   # 女主 ~26 长发 米色针织
MB = "replication/output/you-budong-me/assets/master-B.png"   # 男主 ~38 藏青毛衣白衬衫 内敛偏冷

WOMAN = ("a realistic East Asian Chinese woman, about 26 years old, long straight dark hair, "
         "soft beige knit sweater")
MAN = ("a realistic East Asian Chinese man, about 38 years old, short dark hair, reserved calm face, "
       "navy sweater over a white shirt")
BRIGHT = ("The room is evenly and normally lit, bright and clear with natural neutral-warm light; "
          "it is NOT a single dim warm lamp and NOT moody darkness; even at night the room lights are on "
          "and the space is clearly visible.")
TAIL_2P = ("They are Chinese with East Asian faces, not western faces. Realistic cinematic film still, "
           "natural color, shallow depth of field. No text, no subtitles, no lyrics, no logo, no watermark anywhere.")
TAIL_1P = ("She is Chinese with an East Asian face, not a western face. Realistic cinematic film still, "
           "natural color, shallow depth of field. No text, no subtitles, no lyrics, no logo, no watermark anywhere.")

shots = [
  # id, prompt, refs, mode, checks
  ("KF-S02-first",
   f"Cinematic still, 16:9, medium shot, slight handheld feel. Sudden rain on a city street at dusk. {WOMAN} and {MAN} squeeze under one small umbrella; the man tilts the umbrella toward the woman so his own shoulder is getting wet in the rain. They stand close, shoulders almost touching, but their hands are NOT yet joined, hanging at their sides. Tender first-spark mood, rain streaks and wet pavement reflections. {TAIL_2P}",
   [MA, MB], "FL2VA first frame (couple under umbrella, hands not yet joined)",
   ["couple East Asian/Chinese, identity via master-A + master-B",
    "rainy dusk street, one umbrella tilted to protect the woman, man's shoulder wet",
    "hands NOT yet joined (this is the FIRST frame of a hand-holding state change)",
    "medium shot, 16:9 1344x768, slight handheld",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S02-last",
   f"Cinematic still, 16:9, medium shot, slight handheld feel. Same rainy dusk city street, same umbrella. {WOMAN} and {MAN} now hold hands, fingers clasped together at their sides, a small shy tender glance between them. Rain streaks, wet pavement reflections, warm streetlight glow. {TAIL_2P}",
   [MA, MB], "FL2VA last frame (hands now joined — resolves the state change)",
   ["couple East Asian/Chinese, identity via master-A + master-B",
    "SAME street/umbrella as S02 first for continuity",
    "hands NOW clasped together (last frame of the hand-holding change)",
    "medium shot, 16:9 1344x768",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S03-first",
   f"Cinematic still, 16:9, medium-close shot, slight handheld. A small bright modern rental kitchen. {WOMAN} and {MAN} cook together for the first time, both smiling, vegetables and a cutting board on the counter, a pan on the stove. {BRIGHT} Warm domestic happiness. {TAIL_2P}",
   [MA, MB], "FL2VA first frame (couple cooking together, before the flour smudge)",
   ["couple East Asian/Chinese, identity via master-A + master-B",
    "bright normal kitchen light, not a single dim warm lamp",
    "cooking together, smiling, no flour on face yet (first frame)",
    "medium-close, 16:9 1344x768",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S03-last",
   f"Cinematic still, 16:9, medium-close shot, slight handheld. Same bright rental kitchen. There is a small smudge of white flour on the woman's cheek and nose; {WOMAN} and {MAN} are laughing together, heads leaning close, playful. {BRIGHT} {TAIL_2P}",
   [MA, MB], "FL2VA last frame (flour smudge + shared laughter — resolves the change)",
   ["couple East Asian/Chinese, identity via master-A + master-B",
    "SAME kitchen as S03 first for continuity",
    "white flour smudge on woman's cheek/nose, both laughing (last frame)",
    "bright normal kitchen light",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S04-first",
   f"Cinematic still, 16:9, close two-shot, static. Night, a cozy living room sofa. {WOMAN} and {MAN} are nestled together under a soft blanket, her head near his shoulder, city lights glowing softly through the window behind them. {BRIGHT} Calm, secure, intimate mood. {TAIL_2P}",
   [MA, MB], "I2VA first frame (couple nestled on sofa at night, promise beat)",
   ["couple East Asian/Chinese, identity via master-A + master-B",
    "night living room but room clearly lit (soft ambient), city lights in window",
    "nestled under blanket, calm secure intimacy",
    "close two-shot, static, 16:9 1344x768",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S06-first",
   f"Cinematic still, 16:9, medium over-shoulder two-shot, static. A dinner table set with a full home-cooked meal that is going cold. {WOMAN} and {MAN} sit across/adjacent, each absorbed in their own phone, not looking at each other, a clear emotional distance between them. {BRIGHT} Estranged, quiet mood. {TAIL_2P}",
   [MA, MB], "I2VA first frame (couple at dinner, both on phones, estrangement)",
   ["couple East Asian/Chinese, identity via master-A + master-B",
    "full meal going cold, both on phones, not looking at each other",
    "bright normal dining light, not moody",
    "medium over-shoulder two-shot, 16:9 1344x768",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S07-first",
   f"Cinematic still, 16:9, medium shot, static. Late night bedroom. {MAN} sits with his back turned at a desk, working late on a laptop; {WOMAN} sits on the edge of the bed behind him looking down at her phone, quietly hurt. {BRIGHT} Accumulated loneliness within the same room. {TAIL_2P}",
   [MA, MB], "I2VA first frame (he turned away working, she on bed with phone)",
   ["couple East Asian/Chinese, identity via master-A + master-B",
    "he back-turned at desk laptop, she on bed edge with phone, quiet hurt",
    "late night but room lit normally (desk lamp + ambient), not pitch dark",
    "medium shot, 16:9 1344x768",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S08-first",
   f"Cinematic still, 16:9, close shot, tense. A living room, {WOMAN} and {MAN} stand face to face mid-argument. She is crying, face wet with tears; he is agitated and frustrated, jaw tight. Raw emotional confrontation, bodies tense. {BRIGHT} {TAIL_2P}",
   [MA, MB], "FL2VA first frame (face-to-face argument peak, before he turns away)",
   ["couple East Asian/Chinese, identity via master-A + master-B",
    "face to face argument, she crying, he agitated (first frame of turn-away change)",
    "living room lit normally, not moody",
    "close shot, 16:9 1344x768",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S08-last",
   f"Cinematic still, 16:9, close shot, tense. Same living room. {MAN} has turned his back to her, shoulders rigid; {WOMAN} covers her face with her hand, breaking down. The rift is final. {BRIGHT} {TAIL_2P}",
   [MA, MB], "FL2VA last frame (he has turned away, she covers face — resolves change)",
   ["couple East Asian/Chinese, identity via master-A + master-B",
    "SAME living room as S08 first for continuity",
    "he turned his back, she covers her face (last frame)",
    "room lit normally",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S09-first",
   f"Cinematic still, 16:9, medium shot, static. An apartment entryway. {MAN} stands holding the handle of a rolling suitcase, the front door half open behind him; {WOMAN} stands still a few steps away, unable to stop him, heartbroken. {BRIGHT} {TAIL_2P}",
   [MA, MB], "FL2VA first frame (man with suitcase at half-open door, she stands still)",
   ["couple East Asian/Chinese, identity via master-A + master-B",
    "man holding rolling suitcase, door half open, she standing still heartbroken",
    "entryway lit normally",
    "medium shot, 16:9 1344x768",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S09-last",
   f"Cinematic still, 16:9, medium shot, static. Same apartment entryway, now the front door is fully closed. {WOMAN} stands alone in the empty entryway facing the shut door, the suitcase and the man gone. Silence and emptiness. {BRIGHT} {TAIL_1P}",
   [MA], "FL2VA last frame (door shut, she alone — resolves the departure)",
   ["woman East Asian/Chinese, identity via master-A",
    "SAME entryway as S09 first for continuity, door now fully closed",
    "she alone facing the shut door, man and suitcase gone (last frame)",
    "entryway lit normally",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S10-first",
   f"Cinematic still, 16:9, wide shot. An emptied apartment: a shelf that once held two matching cups now holds only one, a half-empty open wardrobe, bare spots where his things used to be. {WOMAN} sits curled up on the floor, knees drawn in, small in the empty space. {BRIGHT} Hollow, quiet grief. {TAIL_1P}",
   [MA], "I2VA first frame (empty apartment, she curled on the floor)",
   ["woman East Asian/Chinese, identity via master-A",
    "only one cup left, half-empty wardrobe, signs he moved out",
    "she curled on the floor, small in empty space",
    "wide shot, room lit normally, 16:9 1344x768",
    "no text/subtitles/lyrics/logo/watermark"]),

  ("KF-S12-first",
   f"Cinematic still, 16:9, close shot of {WOMAN} and her smartphone. Present day, soft morning light. She holds the phone; a plain messaging-app chat screen is open with an empty-looking conversation, her thumb hovering over the on-screen keyboard as if she has just typed something into the input box. Her face is quiet, holding back emotion. {BRIGHT} (Exact message text will be composited in post; render a clean blank chat input, do NOT bake in any words.) {TAIL_1P}",
   [MA], "FL2VA first frame (she typing in a chat box; message text added in post to stay legible)",
   ["woman East Asian/Chinese, identity via master-A",
    "close on face + phone, plain chat UI, thumb over keyboard, quiet held-back emotion",
    "chat input left BLANK (exact Chinese message composited in post, avoids garbled render)",
    "soft morning light, 16:9 1344x768",
    "no baked-in text/subtitles/lyrics/logo/watermark"]),

  ("KF-S12-last",
   f"Cinematic still, 16:9. {WOMAN} seen from a near-back angle as she lowers her now dark, locked smartphone and rises to her feet, turning toward a bright window full of warm morning sunlight that washes over her. A sense of quiet release and letting go. {BRIGHT} {TAIL_1P}",
   [MA], "FL2VA last frame (phone locked, she rises and walks toward the light — release)",
   ["woman East Asian/Chinese, identity via master-A",
    "phone screen dark/locked, she rises and turns toward bright sunlit window",
    "mood of quiet release / letting go, warm morning light",
    "near-back angle, 16:9 1344x768",
    "no text/subtitles/lyrics/logo/watermark"]),
]

os.makedirs(OUT, exist_ok=True)
made = []
for sid, prompt, refs, mode, checks in shots:
    h = hashlib.sha256(prompt.encode("utf-8")).hexdigest()
    doc = {
        "id": sid,
        "prompt": prompt,
        "model": "gpt-image-2",
        "size": "1344x768",
        "references": refs,
        "authoring_skill": "h3-prompt-writing",
        "h3_prompt_review": {
            "skill": "h3-prompt-writing",
            "authorship": "generated_by_skill",
            "result": "pass",
            "asset_type": "image",
            "mode": mode,
            "checks": checks,
            "unresolved_blockers": [],
            "reviewed_prompt_sha256": h,
        },
    }
    path = os.path.join(OUT, sid + ".json")
    with open(path, "w", encoding="utf-8") as f:
        json.dump(doc, f, ensure_ascii=False, indent=2)
    made.append((sid, len(refs)))

for sid, n in made:
    print(f"{sid}  refs={n}")
print(f"共 {len(made)} 个提示词 JSON")
