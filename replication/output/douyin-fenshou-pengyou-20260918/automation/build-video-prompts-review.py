#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""构建 video-prompts-review.html:展示20条H3视频提示词供人工审(关键帧缩略图+对白+表演+英文prompt)。"""
import json, glob, os, re, html

PROJ = "/home/ubuntu/ads_skill/replication/output/douyin-fenshou-pengyou-20260918"
files = sorted(glob.glob(f"{PROJ}/prompts/SH*-video.json"))

def rel(p): return os.path.relpath(p, PROJ)

def extract_dialogue(prompt):
    return re.findall(r"<d>\[Chinese\]\s*(.*?)</d>", prompt)

cards = []
total = 0
for f in files:
    d = json.load(open(f, encoding="utf-8"))
    uid = os.path.basename(f).replace("-video.json","")
    rev = d["h3_prompt_review"]; na = d["narrative_alignment"]
    mode = rev["mode"]; dur = d["duration"]; total += dur
    scene = "男线·咖啡馆 SC_M" if na["related_shots"][0][:4] in ("SH01","SH02","SH03","SH04","SH05","SH07","SH08","SH09","SH10","SH11") and "cafe" else ""
    # 判定场景:靠 prompt 里 cafe/home
    scene = "男线 · 咖啡馆(SC_M)" if "cafe" in d["prompt"] else "女线 · 居家客厅(SC_F)"
    dlg = extract_dialogue(d["prompt"])
    beats = " · ".join(na["related_beats"])
    frames = "".join(
        f'<figure><img src="{html.escape(rel(p))}" loading="lazy"><figcaption>{"首帧" if i==0 else "尾帧"}</figcaption></figure>'
        for i,p in enumerate(d["images"]))
    dlg_html = "".join(f'<span class="line">{html.escape(x)}</span>' for x in dlg) if dlg else '<span class="novo">无出镜对白(反应/道具镜;V.O.后期豆包配)</span>'
    ev_html = "".join(f"<li>{html.escape(e)}</li>" for e in na["visual_evidence"])
    modecls = "fl2va" if mode=="FL2VA" else "i2va"
    cards.append(f"""
    <section class="card">
      <div class="head">
        <span class="uid">{uid}</span>
        <span class="badge {modecls}">{mode}</span>
        <span class="badge dur">{dur}s</span>
        <span class="scene">{scene}</span>
        <span class="beat">{html.escape(beats)}</span>
      </div>
      <div class="frames">{frames}</div>
      <div class="block"><h4>出镜对白(H3直出·内嵌口型)</h4><div class="dlg">{dlg_html}</div></div>
      <div class="block"><h4>表演/内心外化(喂给H3的身体动作)</h4><ul class="ev">{ev_html}</ul></div>
      <details class="block"><summary>英文提示词全文(integrated_multimodal_description)</summary><pre>{html.escape(d['prompt'])}</pre></details>
    </section>""")

page = f"""<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>《分手后要不要做朋友》· 20条H3视频提示词审阅</title>
<style>
 *{{box-sizing:border-box}} body{{margin:0;font-family:-apple-system,'PingFang SC','Microsoft YaHei',sans-serif;background:#0f1115;color:#e8eaf0;line-height:1.6}}
 header{{padding:28px 20px;background:linear-gradient(135deg,#1a1d29,#12141c);border-bottom:1px solid #2a2f3d}}
 header h1{{margin:0 0 6px;font-size:22px}} header p{{margin:2px 0;color:#9aa3b5;font-size:14px}}
 .wrap{{max-width:1040px;margin:0 auto;padding:20px}}
 .card{{background:#171a22;border:1px solid #262b38;border-radius:12px;padding:18px;margin:18px 0}}
 .head{{display:flex;align-items:center;flex-wrap:wrap;gap:10px;margin-bottom:14px}}
 .uid{{font-weight:700;font-size:17px;letter-spacing:.5px}}
 .badge{{font-size:12px;padding:2px 9px;border-radius:20px;font-weight:600}}
 .i2va{{background:#1e3a5f;color:#7db9ff}} .fl2va{{background:#4a2a5f;color:#d79bff}} .dur{{background:#2a3d2a;color:#8fd98f}}
 .scene{{color:#c8a15a;font-size:13px}} .beat{{color:#7f8aa0;font-size:13px;margin-left:auto}}
 .frames{{display:flex;gap:12px;flex-wrap:wrap;margin-bottom:14px}}
 figure{{margin:0}} figure img{{width:280px;max-width:44vw;border-radius:8px;border:1px solid #2a2f3d;display:block}}
 figcaption{{text-align:center;font-size:12px;color:#8a93a6;margin-top:4px}}
 .block{{margin:12px 0}} .block h4{{margin:0 0 6px;font-size:13px;color:#9aa3b5;font-weight:600}}
 .dlg .line{{display:inline-block;background:#20263a;border-left:3px solid #7db9ff;padding:6px 12px;margin:3px 6px 3px 0;border-radius:4px;font-size:15px}}
 .novo{{color:#7f8aa0;font-style:italic}}
 ul.ev{{margin:0;padding-left:20px}} ul.ev li{{font-size:14px;color:#c4cad6;margin:2px 0}}
 details summary{{cursor:pointer;color:#7db9ff;font-size:13px}} pre{{white-space:pre-wrap;word-break:break-word;background:#0c0e14;border:1px solid #232838;border-radius:8px;padding:12px;font-size:12px;color:#a9b4c6;margin-top:8px}}
</style></head><body>
<header>
 <div class="wrap" style="padding:0">
  <h1>《分手后要不要做朋友》· 20 条 H3 视频提示词审阅</h1>
  <p>抖音 · 16:9 · MiniMax-H3 · 男线↔女线交叉硬切 · 中景为主(道具特写首帧+拍9、近景仅拍5)</p>
  <p>共 20 个生成单元 · 总生成时长 {total}s · 预估 ¥{total*0.2:.2f} · 文本校验(validate-h3-prompt-review)20/20 通过</p>
  <p>蓝=I2VA单首帧 / 紫=FL2VA首尾帧(状态变化镜) · V.O.朋友/闺蜜为后期豆包配音,不在H3生成</p>
 </div>
</header>
<div class="wrap">
{''.join(cards)}
</div>
</body></html>"""

out = f"{PROJ}/video-prompts-review.html"
open(out,"w",encoding="utf-8").write(page)
print("写出", out, f"({len(cards)} 卡片, 总{total}s)")
