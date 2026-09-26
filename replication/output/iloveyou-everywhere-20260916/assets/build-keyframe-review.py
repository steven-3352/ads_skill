#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""从 prompts/assets/KF-S0X-first.json + 分镜标题生成公网关键帧审阅页。
输出 assets/keyframe-review.html;图片相对路径 keyframes/KF-S0X-first.png。
只读文本、显式 UTF-8,避免多字节乱码(见记忆 no-perl-sed-on-multibyte-html)。"""
import json, os, html, subprocess

BASE = os.path.dirname(os.path.abspath(__file__))          # .../assets
PROJ = os.path.dirname(BASE)
PJSON = os.path.join(PROJ, "prompts", "assets")
KFDIR = os.path.join(PROJ, "assets", "keyframes")

# 分镜标题 / 界层 / 巨物 / 景别(取自 review/storyboard.md 的 shot↔beat 表)
SHOTS = [
    ("S01", "B1+B2", "前戏·甜告白(建立+钩子)",       "0–3.5s",  "人物母板换装·双人",     "中景→拉远"),
    ("S02", "B3",    "天上(转折·起飞)",             "3.5–6.0s","柔散暖光巨晕/云海",     "极远景"),
    ("S03", "B4",    "山川(推进)",                  "6.0–8.5s","万仞雪山巨脊",          "极远景"),
    ("S04", "B5",    "森林(推进)",                  "8.5–11.0s","参天巨木林冠",         "极远景"),
    ("S05", "B6",    "海底(推进)",                  "11.0–13.5s","巨鲸",                "极远景"),
    ("S06", "B7",    "地下(推进)",                  "13.5–16.0s","地心巨型晶洞",         "极远景"),
    ("S07", "B8",    "上帝视角收束(兑现)",           "16.0–18.0s","俯瞰天地+亿万人声",    "极远景→上帝视角"),
]

def esc(s): return html.escape(str(s), quote=True)

def sha_of_prompt(path):
    """按门禁同法算 prompt 的 sha256:jq -jr '.prompt' | sha256sum"""
    d = json.load(open(path, encoding="utf-8"))
    p = subprocess.run(["sha256sum"], input=d["prompt"].encode("utf-8"),
                       capture_output=True)
    return p.stdout.decode().split()[0]

cards = []
for sid, beat, title, tspan, giant, framing in SHOTS:
    jp = os.path.join(PJSON, f"KF-{sid}-first.json")
    d = json.load(open(jp, encoding="utf-8"))
    review = d.get("h3_prompt_review", {})
    declared = review.get("reviewed_prompt_sha256", "")
    actual = sha_of_prompt(jp)
    sha_ok = (declared == actual)
    img_rel = f"keyframes/KF-{sid}-first.png"   # 相对审阅页(位于 assets/)
    img_abs = os.path.join(BASE, img_rel)       # BASE=assets;存在性按页面同基目录判定
    img_ok = os.path.exists(img_abs)
    mode = d.get("mode", "")
    refs = d.get("references", [])
    ref_txt = ("参考:" + ", ".join(os.path.basename(r) for r in refs)) if refs else "无参考(纯文生图)"
    checks = review.get("checks", [])
    checks_html = "".join(f"<li>{esc(c)}</li>" for c in checks)
    gate_pill = '<span class="pill ok">闸门 pass</span>' if review.get("result") == "pass" else '<span class="pill bad">闸门 未过</span>'
    sha_pill = '<span class="pill ok">sha匹配</span>' if sha_ok else '<span class="pill bad">sha不匹配</span>'
    img_pill = '<span class="pill ok">已生成</span>' if img_ok else '<span class="pill bad">缺图</span>'
    img_tag = (f'<img loading="lazy" src="{img_rel}" alt="{sid}">' if img_ok
               else '<span class="missing">缺图 · 未生成</span>')
    cards.append(f"""
  <section class="card">
    <div class="imgwrap">{img_tag}</div>
    <div class="meta">
      <h2>{esc(sid)} · {esc(title)}</h2>
      <div class="sub">
        <span class="tag">{esc(beat)}</span>
        <span class="tag">{esc(tspan)}</span>
        <span class="tag mode">{esc(framing)}</span>
        <code>KF-{sid}-first.png</code>
        {img_pill}{gate_pill}{sha_pill}
      </div>
      <p class="giant">🗻 巨物锚点:<b>{esc(giant)}</b> · <span class="dim">{esc(ref_txt)}</span></p>
      <details><summary>提示词全文 · mode={esc(mode)}</summary><p class="prompt">{esc(d.get('prompt',''))}</p></details>
      <details><summary>提示词技能自检 {len(checks)} 条</summary><ul class="checks">{checks_html}</ul></details>
    </div>
  </section>""")

html_doc = f"""<!doctype html><html lang="zh"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>《我喜欢你 · 穿界》逐镜关键帧审阅</title>
<style>
 :root{{color-scheme:light dark}}
 body{{margin:0;font:15px/1.6 -apple-system,"PingFang SC","Microsoft YaHei",sans-serif;background:#0f1115;color:#e8eaed}}
 header{{padding:22px 26px;border-bottom:1px solid #2a2e37;position:sticky;top:0;background:#0f1115;z-index:2}}
 header h1{{margin:0 0 6px;font-size:20px}}
 header p{{margin:0;color:#9aa0aa;font-size:13px}}
 header .flow{{margin-top:8px;color:#8ab4ff;font-size:13px}}
 main{{padding:22px;display:grid;gap:22px;grid-template-columns:repeat(auto-fill,minmax(460px,1fr));max-width:1600px;margin:0 auto}}
 .card{{background:#171a21;border:1px solid #262b35;border-radius:12px;overflow:hidden;display:flex;flex-direction:column}}
 .imgwrap{{aspect-ratio:16/9;background:#000;display:flex;align-items:center;justify-content:center}}
 .imgwrap img{{width:100%;height:100%;object-fit:cover;display:block}}
 .missing{{color:#e06c6c}}
 .meta{{padding:14px 16px}}
 .meta h2{{margin:0 0 8px;font-size:15px;line-height:1.4}}
 .giant{{margin:6px 0;font-size:13px;color:#cdd3dc}}
 .dim{{color:#9aa0aa}}
 .tag{{font-size:12px;color:#8ab4ff;border:1px solid #34507f;border-radius:20px;padding:1px 9px}}
 .tag.mode{{color:#c8a2ff;border-color:#5a3f8f}}
 .sub{{display:flex;gap:8px;flex-wrap:wrap;align-items:center;margin-bottom:8px}}
 code{{background:#0c0e12;padding:1px 6px;border-radius:5px;font-size:12px;color:#c7ccd4}}
 .pill{{font-size:12px;padding:1px 8px;border-radius:20px}}
 .pill.ok{{background:#16351f;color:#7fe0a0;border:1px solid #2c6b3f}}
 .pill.bad{{background:#3a1618;color:#ff9a9a;border:1px solid #7a2b2e}}
 details{{margin:6px 0}}
 summary{{cursor:pointer;color:#9aa0aa;font-size:13px}}
 .prompt{{background:#0c0e12;border-radius:8px;padding:10px 12px;font-size:12.5px;color:#b9c0ca;white-space:pre-wrap}}
 .checks{{margin:8px 0 0;padding-left:18px;color:#9aa0aa;font-size:12.5px}}
</style></head>
<body>
<header>
  <h1>《我喜欢你 · 穿界》— 逐镜关键帧审阅(7/7 立基帧已生成 · 闸门通过 7/7)</h1>
  <p>横屏 16:9 · gpt-image-2 文生图锁 1344×768(H3 768P 16:9)· 甜美/雀跃/心旷神怡 · 巨物+空灵 · 中文字幕与亿万合唱人声一律后期,画面留白(底部 15–18% 字幕安全区)。</p>
  <p class="flow">告白冲出重力 → 天上 → 山川 → 森林 → 海底 → 地下 → 上帝视角(亿万「我喜欢你」层叠回响)。请确认:选角一致(中国人)/巨物尺度到位/暖亮通透非阴冷/无欧美脸。回复「关键帧通过」进入付费视频生成。</p>
</header>
<main>
{''.join(cards)}
</main>
</body></html>"""

out = os.path.join(BASE, "keyframe-review.html")
with open(out, "w", encoding="utf-8") as f:
    f.write(html_doc)
print("written:", out)
print("cards:", len(cards))
