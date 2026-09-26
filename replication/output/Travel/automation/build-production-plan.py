#!/usr/bin/env python3
# 生成 Travel production-plan.json（旁白驱动风光公路片，MiniMax-H3）
# 旁白=后期seed-audio TTS；dialogue通道挂生成单元以启用密度门；花字走postTask；镜18豁免。
import json, sys, pathlib

REPO = pathlib.Path("/home/ubuntu/ads_skill")
PROJ = REPO / "replication/output/Travel"
SP = PROJ / "story/travel-screenplay.md"
story_text = SP.read_text(encoding="utf-8")

# 每镜: (num, title, dur, action_sound(bool), has_text(bool), verbatim旁白, exempt理由或None)
SHOTS = [
 (1 ,"叠红冲锋衣入箱·双行李箱锚点", 4, True , True , "出发前一晚，我把你那件红外套，叠好，放进去。", None),
 (2 ,"手绘环中国路线图·指尖划过青海湖", 4, False, True , "这张图是咱俩画的，你圈的地方，我都记着。", None),
 (3 ,"空副驾+两人合照·缓推", 4, False, False, "说好两个人一起去的，现在啊，就剩我自己了。", None),
 (4 ,"点火出发·车驶出小区", 4, True , True , "走吧。第一站，去你圈了最久的地方。", None),
 (5 ,"驾驶舱POV·空副驾放合照", 4, False, False, "副驾上摆着咱俩的合照，这一路，你陪着我。", None),
 (6 ,"青海湖·笔直公路航拍", 4, False, True , "青海湖到了。这蓝，照片根本拍不出来，你说得对。", None),
 (7 ,"茶卡盐湖·天空之镜", 4, True , True , "走到茶卡，脚下全是天，你要在准得乐疯。", None),
 (8 ,"稻城亚丁·雪山牛奶海经幡", 4, True , True , "亚丁的雪山下头，风好大，我替你多站了会儿。", None),
 (9 ,"川藏318·弯道随路起伏", 4, True , True , "318 弯得吓人，你老说，开着开着就到了。", None),
 (10,"拉萨布达拉宫·经幡朝圣", 4, True , True , "到了拉萨，我替咱俩许了个愿，是啥不告诉你。", None),
 (11,"敦煌鸣沙山月牙泉·驼队剪影", 4, True , True , "敦煌的风裹着沙子，打在脸上，你肯定嫌糙。", None),
 (12,"额济纳胡杨林·逆光背影", 4, False, True , "胡杨林黄了。你不是老念叨嘛，黄了才好看。", None),
 (13,"呼伦贝尔草原·风掀草浪", 4, True , True , "草原上风一刮，草浪一片一片的，人是真舒坦。", None),
 (14,"洱海·人物背影临湖", 4, False, True , "洱海边上站着，风吹过来，我总觉得，你就在旁边。", None),
 (15,"湖边握合照·指腹摩挲", 4, False, True , "地图上你圈过的每个地方，我一个一个，都替你走到了。", None),
 (16,"车内后座·回望后视镜公路", 5, False, True , "剩下的路还很长，没关系的，我一个人，会慢慢替你走完。", None),
 (17,"日落公路·逆光驶向太阳", 4, False, True , "你在那边，这些好看的，应该都看到了吧？", None),
 (18,"合照特写慢推·淡出落字", 5, False, True , "答应过你的……我都做到了。",
    "结尾题眼慢收：画面淡出黑屏+钢琴尾音承接，属设计内结局静默留白（非死尾），旁白密度自检已留痕（SOP §7 例外）。"),
]

def sid(n): return f"{n:02d}"

shots = []
for (n, title, dur, asound, htext, vb, exempt) in SHOTS:
    if vb not in story_text:
        print(f"WARN verbatim not found in screenplay for shot {n}: {vb}", file=sys.stderr)
    scene = f"sc-{sid(n)}"
    beat_id = f"b{sid(n)}"
    # beat 通道 = 生成单元覆盖(picture+dialogue+ambience[+action_sound]) ∪ postTask覆盖(onscreen_text)
    unit_channels = ["picture", "dialogue", "ambience"]
    if asound:
        unit_channels.append("action_sound")
    beat_channels = list(unit_channels)
    if htext:
        beat_channels.append("onscreen_text")

    unit = {
        "id": f"u{sid(n)}",
        "sceneId": scene,
        "durationSeconds": dur,
        "cuts": [{
            "id": f"c{sid(n)}",
            "seconds": dur,
            "coverage": [{"beatId": beat_id, "channels": unit_channels}],
        }],
        "prompts": {
            "images": [f"prompts/shots/travel-{sid(n)}-image.json"],
            "video": f"prompts/shots/travel-{sid(n)}-video.json",
        },
        "references": [],
        "media": {"firstFrame": None, "lastFrame": None, "video": None},
    }
    if exempt:
        unit["dialogueDensityExempt"] = exempt

    post = [{
        "id": f"p{sid(n)}-vo",
        "type": "voiceover_tts",
        "description": "旁白走 seed-audio TTS，对画面逐句对齐铺满（成片零对白字幕，H3不生成对白/不写<d>）。",
        "coverage": [],
    }]
    if htext:
        post.append({
            "id": f"p{sid(n)}-txt",
            "type": "onscreen_text",
            "description": "后期烧花字（地名·打卡进度 / 情绪落字），非对白字幕。",
            "coverage": [{"beatId": beat_id, "channels": ["onscreen_text"]}],
        })

    shots.append({
        "id": sid(n),
        "title": title,
        "source": {"storyFile": "story/travel-screenplay.md", "verbatim": vb},
        "requiredBeats": [{
            "id": beat_id, "sceneId": scene, "text": vb, "channels": beat_channels,
        }],
        "generationUnits": [unit],
        "postTasks": post,
    })

doc = {
    "schemaVersion": 1,
    "projectId": "travel",
    "promptPolicy": {
        "model": "MiniMax-H3",
        "authoringSkill": "h3-prompt-writing",
        "reviewGate": "replication/tools/validate-h3-prompt-review.sh",
    },
    "constraints": {"maxGenerationSeconds": 6, "minDialogueCharsPerSecond": 3.0},
    "narrativeShots": shots,
}

out = PROJ / "contracts/production-plan.json"
out.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
total = sum(s[2] for s in SHOTS)
print(f"wrote {out} | {len(shots)} shots | 生成总时长 {total}s")
