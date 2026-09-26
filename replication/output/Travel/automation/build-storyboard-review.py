#!/usr/bin/env python3
# 生成分镜审阅 HTML（读剧本逐镜表），供用户公网眼判分镜设计。UTF-8 显式。
import re, html, json, pathlib

PROJ = pathlib.Path("/home/ubuntu/ads_skill/replication/output/Travel")
sp = (PROJ / "story/travel-screenplay.md").read_text(encoding="utf-8")

# 解析逐镜剧本表：| 镜号 | 时长 | 景别/机位 | 画面 | 旁白 | 字数 | 环境声/花字 |
rows = []
for line in sp.splitlines():
    m = re.match(r"^\|\s*(\d{2})\s*\|", line)
    if not m:
        continue
    cells = [c.strip() for c in line.strip().strip("|").split("|")]
    if len(cells) >= 7 and re.fullmatch(r"\d{2}", cells[0]):
        rows.append(cells[:7])  # num,dur,shot,pic,vo,chars,sound

arc = [
 ("起 · 收拾（怅惘）","01–03","叠衣入箱、抚过路线图、点出『就剩我自己』——空箱+空副驾暗示，不解释原因"),
 ("承 · 点火（坚定）","04–05","『走吧』点火转折；合照上副驾，宣告『这一路你陪我』"),
 ("转 · 打卡蒙太奇（眷恋）","06–14","9 站风光快切；旁白破排比，改回忆碎片/打趣/替你多看两眼"),
 ("合 · 回慢（释然）","15–18","走遍你圈的线→剩下的路慢慢替你走→『你在那边应该看到了吧』→题眼落字"),
]

def td(s): return html.escape(s)

tr_html = []
for r in rows:
    num,dur,shot,pic,vo,chars,sound = r
    dens = ""
    try:
        d = float(re.sub(r"[^\d.]","",dur) or 0); c = int(re.sub(r"[^\d]","",chars) or 0)
        if d: dens = f"{c/d:.1f}"
    except: pass
    warn = "" if (dens=="" or float(dens)>=3.0) else " style='color:#c0392b;font-weight:600'"
    tr_html.append(f"""<tr>
      <td class='num'>{td(num)}</td><td>{td(dur)}s</td><td>{td(shot)}</td>
      <td class='pic'>{td(pic)}</td>
      <td class='vo'>{td(vo)}<span class='chars'>（{td(chars)}字·{dens}字/秒）</span></td>
      <td class='snd'>{td(sound)}</td></tr>""")

arc_html = "".join(
  f"<div class='arc'><div class='arc-h'>{td(a)}<span class='arc-n'>镜 {td(b)}</span></div><div class='arc-d'>{td(c)}</div></div>"
  for a,b,c in arc)

page = f"""<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>一个人的环中国自驾 · 分镜审阅</title>
<style>
:root{{--bg:#0f1115;--card:#171a21;--line:#262b36;--ink:#e8eaed;--dim:#9aa3b2;--accent:#e0a458}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--bg);color:var(--ink);font:15px/1.7 -apple-system,"PingFang SC","Microsoft YaHei",sans-serif}}
.wrap{{max-width:1080px;margin:0 auto;padding:28px 18px 80px}}
h1{{font-size:24px;margin:0 0 4px}}
.sub{{color:var(--dim);margin:0 0 20px;font-size:13px}}
.meta{{display:flex;flex-wrap:wrap;gap:8px 18px;color:var(--dim);font-size:13px;margin-bottom:22px}}
.meta b{{color:var(--ink);font-weight:600}}
h2{{font-size:16px;border-left:3px solid var(--accent);padding-left:9px;margin:30px 0 12px}}
.arcs{{display:grid;grid-template-columns:repeat(auto-fit,minmax(230px,1fr));gap:10px;margin-bottom:8px}}
.arc{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:12px 14px}}
.arc-h{{font-weight:600;display:flex;justify-content:space-between;align-items:baseline;gap:8px}}
.arc-n{{color:var(--accent);font-size:12px;font-weight:500}}
.arc-d{{color:var(--dim);font-size:13px;margin-top:6px}}
table{{width:100%;border-collapse:collapse;font-size:13.5px;margin-top:4px}}
th,td{{border:1px solid var(--line);padding:9px 10px;vertical-align:top;text-align:left}}
th{{background:#1c2029;color:var(--dim);font-weight:600;position:sticky;top:0}}
.num{{color:var(--accent);font-weight:700;text-align:center;width:38px}}
.pic{{color:#cfd6e2;width:26%}}
.vo{{width:30%}}
.chars{{display:block;color:var(--dim);font-size:11.5px;margin-top:3px}}
.snd{{color:var(--dim);width:16%;font-size:12.5px}}
.note{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:14px 16px;color:var(--dim);font-size:13px;margin-top:22px}}
.note b{{color:var(--ink)}}
</style></head>
<body><div class="wrap">
<h1>一个人的环中国自驾 · 兑现承诺</h1>
<p class="sub">分镜审阅页（stage2 已锁 storyboard_confirmed）· 生成前请眼判画面/旁白/节奏设计</p>
<div class="meta">
  <span><b>平台</b> 抖音 9:16 竖屏</span><span><b>时长</b> ~68s（生成 74s 余量）</span>
  <span><b>镜数</b> 18</span><span><b>类型</b> 情感·公路·兑现承诺</span>
  <span><b>视频模型</b> MiniMax-H3</span><span><b>声音</b> 旁白后期 seed-audio TTS · 成片零对白字幕</span>
</div>
<h2>情绪节拍</h2>
<div class="arcs">{arc_html}</div>
<h2>逐镜分镜（18 镜）</h2>
<table>
<thead><tr><th>镜</th><th>时长</th><th>景别/机位</th><th>画面</th><th>旁白（送 TTS）</th><th>环境声/花字</th></tr></thead>
<tbody>{''.join(tr_html)}</tbody></table>
<div class="note">
<b>说明：</b>本页为分镜设计审阅，尚未生成任何图片/视频。旁白为非同期独白，H3 只生成画面+环境声，旁白与花字后期叠加，成片不烧对白字幕。<br>
<b>下一步（付费 stage3 生图）：</b>先出母板（合照道具/人物背影身份根）→ 认可后逐镜关键帧。付费前会给金丝雀+精确成本账，等你确认再花钱。<br>
<b>合规：</b>无品牌/商标；不作『失去伴侣』死亡具象（留白暗示）；318 等不暗示危险驾驶。
</div>
</div></body></html>"""

out = PROJ / "review/storyboard-review.html"
out.write_text(page, encoding="utf-8")
# mojibake 自检
bad = page.encode("utf-8").count(b"\xc3\x83") + page.count("Ã") + page.count("â€")
print(f"wrote {out} | rows={len(rows)} | mojibake={bad}")
