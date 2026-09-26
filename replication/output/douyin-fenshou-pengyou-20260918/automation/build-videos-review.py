#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""构建 videos-review.html:每单元 关键帧→生成的视频→对白/表演,供人工审(合 only-validate-4-texts)。"""
import json, glob, os, re, html

PROJ = "/home/ubuntu/ads_skill/replication/output/douyin-fenshou-pengyou-20260918"
def rel(p): return os.path.relpath(p, PROJ)
def dlg(prompt): return re.findall(r"<d>\[Chinese\]\s*(.*?)</d>", prompt)

cards=[]; done=0; total=0
for f in sorted(glob.glob(f"{PROJ}/prompts/SH*-video.json")):
    d=json.load(open(f,encoding="utf-8")); uid=os.path.basename(f).replace("-video.json",""); sh=uid[:4]
    rev=d["h3_prompt_review"]; na=d["narrative_alignment"]; mode=rev["mode"]; dur=d["duration"]; total+=dur
    scene="男线·咖啡馆(SC_M)" if "cafe" in d["prompt"] else "女线·居家(SC_F)"
    mp4=f"{PROJ}/shots/shot-{sh}/videos/{uid}.mp4"
    has=os.path.exists(mp4); done+=1 if has else 0
    d_html="".join(f'<span class="line">{html.escape(x)}</span>' for x in dlg(d["prompt"])) or '<span class="novo">无出镜对白(反应/道具镜;V.O.后期配)</span>'
    ev="".join(f"<li>{html.escape(e)}</li>" for e in na["visual_evidence"])
    frame=d["images"][0]
    media=(f'<video src="{html.escape(rel(mp4))}" controls preload="metadata" poster="{html.escape(rel(frame))}"></video>'
           if has else
           f'<div class="pending"><img src="{html.escape(rel(frame))}"><span>待充值生成</span></div>')
    st="ok" if has else "wait"
    cards.append(f"""
    <section class="card {st}">
      <div class="head"><span class="uid">{uid}</span>
        <span class="badge {'fl2va' if mode=='FL2VA' else 'i2va'}">{mode}</span>
        <span class="badge dur">{dur}s</span><span class="scene">{scene}</span>
        <span class="beat">{html.escape(' · '.join(na['related_beats']))}</span>
        <span class="stat {st}">{'✅ 已生成' if has else '⏳ 待充值'}</span></div>
      <div class="media">{media}</div>
      <div class="block"><h4>出镜对白</h4><div class="dlg">{d_html}</div></div>
      <div class="block"><h4>表演/内心外化</h4><ul class="ev">{ev}</ul></div>
    </section>""")

page=f"""<!DOCTYPE html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>《分手后要不要做朋友》· 视频审阅</title><style>
 *{{box-sizing:border-box}} body{{margin:0;font-family:-apple-system,'PingFang SC','Microsoft YaHei',sans-serif;background:#0f1115;color:#e8eaf0;line-height:1.6}}
 header{{padding:26px 20px;background:linear-gradient(135deg,#1a1d29,#12141c);border-bottom:1px solid #2a2f3d}}
 header h1{{margin:0 0 6px;font-size:22px}} header p{{margin:2px 0;color:#9aa3b5;font-size:14px}}
 .warn{{color:#ffcf6b;font-weight:600}}
 .wrap{{max-width:1040px;margin:0 auto;padding:20px}}
 .card{{background:#171a22;border:1px solid #262b38;border-radius:12px;padding:18px;margin:18px 0}}
 .card.wait{{opacity:.72;border-style:dashed}}
 .head{{display:flex;align-items:center;flex-wrap:wrap;gap:10px;margin-bottom:12px}}
 .uid{{font-weight:700;font-size:17px}} .badge{{font-size:12px;padding:2px 9px;border-radius:20px;font-weight:600}}
 .i2va{{background:#1e3a5f;color:#7db9ff}} .fl2va{{background:#4a2a5f;color:#d79bff}} .dur{{background:#2a3d2a;color:#8fd98f}}
 .scene{{color:#c8a15a;font-size:13px}} .beat{{color:#7f8aa0;font-size:13px}}
 .stat{{margin-left:auto;font-size:13px;font-weight:600}} .stat.ok{{color:#8fd98f}} .stat.wait{{color:#ffcf6b}}
 .media{{margin-bottom:12px}} video{{width:100%;max-width:640px;border-radius:8px;border:1px solid #2a2f3d;background:#000;display:block}}
 .pending{{position:relative;max-width:640px}} .pending img{{width:100%;border-radius:8px;filter:grayscale(.6) brightness(.5)}}
 .pending span{{position:absolute;inset:0;display:flex;align-items:center;justify-content:center;font-size:16px;color:#ffcf6b;font-weight:700}}
 .block{{margin:10px 0}} .block h4{{margin:0 0 6px;font-size:13px;color:#9aa3b5}}
 .dlg .line{{display:inline-block;background:#20263a;border-left:3px solid #7db9ff;padding:5px 11px;margin:3px 6px 3px 0;border-radius:4px;font-size:15px}}
 .novo{{color:#7f8aa0;font-style:italic}} ul.ev{{margin:0;padding-left:20px}} ul.ev li{{font-size:14px;color:#c4cad6;margin:2px 0}}
</style></head><body>
<header><div class="wrap" style="padding:0">
 <h1>《分手后要不要做朋友》· 20 单元视频审阅</h1>
 <p>抖音 · 16:9 · MiniMax-H3 · 男线↔女线交叉硬切 · 后期统一烧字幕 · V.O.朋友/闺蜜后期豆包配</p>
 <p>已生成 <b>{done}/20</b> 条 · 总生成时长 {total}s · <span class="warn">账户积分不足,剩 {20-done} 条待充值后一键续跑(已生成的防覆盖跳过,不重复扣费)</span></p>
 <p>点击视频播放;字幕未烧属正常(H3只出配音+表演,字幕/旁白 stage5 后期统一处理)</p>
</div></header>
<div class="wrap">{''.join(cards)}</div></body></html>"""

open(f"{PROJ}/videos-review.html","w",encoding="utf-8").write(page)
print(f"写出 videos-review.html:已生成 {done}/20,总{total}s")
