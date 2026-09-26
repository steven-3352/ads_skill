#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""生成《分手后要不要做朋友》关键帧公网抽验页。图片走相对路径,经 nginx /ads-review/ 提供。"""
import json, os, glob, re

ROOT = "/home/ubuntu/ads_skill/replication/output/douyin-fenshou-pengyou-20260918"
PLAN = os.path.join(ROOT, "contracts/production-plan.json")
STATE = os.path.join(ROOT, "automation/fenshou-pengyou.paid-state.json")
OUT = os.path.join(ROOT, "keyframes-review.html")

plan = json.load(open(PLAN, encoding="utf-8"))
state = json.load(open(STATE, encoding="utf-8"))

# 被 reject 且已 supersede 的资产 → 排除展示
excluded = set()
for a in state.get("assets", []):
    if a.get("status") == "rejected":
        out = a.get("output", "")
        excluded.add(os.path.basename(out))

FL2VA = {"SH01-U1","SH01-U2","SH08-U1","SH09-U1","SH09-U2","SH11-U1","SH11-U2"}

def esc(s):
    return (str(s or "").replace("&","&amp;").replace("<","&lt;")
            .replace(">","&gt;").replace('"',"&quot;"))

shots = plan.get("narrativeShots", [])
scene_label = {"SC_M":"男线·咖啡馆","SC_F":"女线·居家"}

blocks = []
total_imgs = 0
for sh in shots:
    shid = sh.get("id","")
    title = sh.get("title","")
    scene = scene_label.get(sh.get("sceneId",""), sh.get("sceneId",""))
    focus = sh.get("watchFocus","")
    imgdir = os.path.join(ROOT, f"shots/shot-{shid}/images")
    pngs = sorted(glob.glob(os.path.join(imgdir, "*.png")))
    cards = []
    for p in pngs:
        b = os.path.basename(p)
        if b in excluded:
            continue
        rel = f"shots/shot-{shid}/images/{b}"
        unit = re.sub(r"-(first|last)(-r\d+)?\.png$", "", b)
        fl = " · FL2VA首尾" if unit in FL2VA else ""
        tag = "首帧" if "-first" in b else ("尾帧" if "-last" in b else "")
        if "-r2" in b: tag += "(返工替代)"
        cards.append(f'''<figure><a href="{esc(rel)}" target="_blank">
<img loading="lazy" src="{esc(rel)}" alt="{esc(b)}"></a>
<figcaption>{esc(b)} <span class="tag">{esc(tag)}{esc(fl)}</span></figcaption></figure>''')
        total_imgs += 1
    blocks.append(f'''<section class="shot">
<h2>{esc(shid)} · {esc(scene)}</h2>
<p class="title">{esc(title)}</p>
<p class="focus">看点:{esc(focus)}</p>
<div class="grid">{"".join(cards)}</div></section>''')

html = f'''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>《分手后要不要做朋友》关键帧抽验</title>
<style>
body{{margin:0;background:#111;color:#eee;font-family:-apple-system,"PingFang SC","Microsoft YaHei",sans-serif;line-height:1.5}}
header{{padding:18px 20px;background:#1a1a1a;border-bottom:1px solid #333;position:sticky;top:0;z-index:9}}
header h1{{margin:0;font-size:18px}}
header p{{margin:6px 0 0;color:#9aa;font-size:13px}}
main{{padding:16px}}
.shot{{margin:0 0 28px;border:1px solid #2a2a2a;border-radius:10px;padding:14px;background:#161616}}
.shot h2{{margin:0 0 4px;font-size:16px;color:#8fd}}
.title{{margin:2px 0;color:#ddd;font-size:14px}}
.focus{{margin:2px 0 12px;color:#9aa;font-size:12px}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(280px,1fr));gap:12px}}
figure{{margin:0;background:#0c0c0c;border-radius:8px;overflow:hidden;border:1px solid #262626}}
figure img{{width:100%;display:block;aspect-ratio:16/9;object-fit:cover;background:#000}}
figcaption{{padding:6px 8px;font-size:12px;color:#bbb;word-break:break-all}}
.tag{{color:#f5a}}
</style></head><body>
<header><h1>《分手后要不要做朋友》· 关键帧抽验(抖音 16:9 / MiniMax-H3)</h1>
<p>共 {total_imgs} 帧关键帧,已过技术+语义 QC,shots 关卡已 gate-out。点图放大。确认后即进付费 stage4 视频。</p></header>
<main>{"".join(blocks)}</main></body></html>'''

with open(OUT, "w", encoding="utf-8") as f:
    f.write(html)
print(f"written {OUT} ({total_imgs} imgs, excluded {sorted(excluded)})")
