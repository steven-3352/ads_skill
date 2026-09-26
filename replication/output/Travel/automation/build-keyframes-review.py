#!/usr/bin/env python3
# 生成关键帧审阅 HTML（20张，按镜01-18；01/04 FL2VA首尾并排）。UTF-8 显式，mojibake 自检。
import html, pathlib

PROJ = pathlib.Path("/home/ubuntu/ads_skill/replication/output/Travel")

# (镜号, 景别, 画面, 生成方式, [(标签,相对review路径)...])
SHOTS = [
 ("01","极近景俯拍·FL2VA首尾","手把叠好的红冲锋衣放进行李箱（起始态→终止态）","文生图",
    [("首帧·举衣悬箱","../shots/01/first.png"),("尾帧·放平手按","../shots/01/last.png")]),
 ("02","特写平视","桌面手绘环中国路线图，指尖划过青海湖","文生图",[("","../shots/02/keyframe.png")]),
 ("03","中景平视缓推","空副驾座上放两人合照","参考母板A",[("","../shots/03/keyframe.png")]),
 ("04","全景·FL2VA首尾","点火驶出小区（停门口→驶离）","文生图",
    [("首帧·停门口","../shots/04/first.png"),("尾帧·驶离","../shots/04/last.png")]),
 ("05","中景驾驶舱POV","主驾视角看公路，副驾摆合照","参考母板A",[("","../shots/05/keyframe.png")]),
 ("06","远景航拍","青海湖笔直公路直通天际","文生图",[("","../shots/06/keyframe.png")]),
 ("07","全景航拍低仰","茶卡盐湖天空之镜","文生图",[("","../shots/07/keyframe.png")]),
 ("08","全景低仰","稻城亚丁雪山牛奶海经幡","文生图",[("","../shots/08/keyframe.png")]),
 ("09","中景车内POV","川藏318弯道雪山","文生图",[("","../shots/09/keyframe.png")]),
 ("10","全景平移","拉萨布达拉宫经幡","文生图",[("","../shots/10/keyframe.png")]),
 ("11","全景航拍逆光","敦煌鸣沙山月牙泉驼队剪影","文生图",[("","../shots/11/keyframe.png")]),
 ("12","全景逆光剪影","额济纳胡杨林女主背影","参考母板B",[("","../shots/12/keyframe.png")]),
 ("13","远景航拍广角","呼伦贝尔草原风掀草浪","文生图",[("","../shots/13/keyframe.png")]),
 ("14","中景背影跟拍","洱海边女主背影临湖","参考母板B",[("","../shots/14/keyframe.png")]),
 ("15","近景手持","手握两人合照，指腹摩挲","文生图静物",[("","../shots/15/keyframe.png")]),
 ("16","中景车内后座","回望后视镜公路夕阳","文生图",[("","../shots/16/keyframe.png")]),
 ("17","全景航拍黄昏","日落公路逆光驶向太阳","文生图",[("","../shots/17/keyframe.png")]),
 ("18","特写平视慢推","副驾两人合照特写","参考母板A",[("","../shots/18/keyframe.png")]),
]

def esc(s): return html.escape(s)

cards=[]
for num,shot,pic,how,imgs in SHOTS:
    tag_cls = "how-ref" if "母板" in how else ("how-still" if "静物" in how else "how-t2i")
    imgs_html="".join(
      f"<figure><img src='{esc(p)}' alt='镜{num}' loading='lazy'>{f'<figcaption>{esc(lbl)}</figcaption>' if lbl else ''}</figure>"
      for lbl,p in imgs)
    multi = " multi" if len(imgs)>1 else ""
    cards.append(f"""<div class='card'>
      <div class='hd'><span class='n'>{esc(num)}</span><span class='shot'>{esc(shot)}</span><span class='how {tag_cls}'>{esc(how)}</span></div>
      <div class='imgs{multi}'>{imgs_html}</div>
      <div class='pic'>{esc(pic)}</div>
    </div>""")

page=f"""<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>环中国自驾 · 关键帧审阅</title>
<style>
:root{{--bg:#0f1115;--card:#171a21;--line:#262b36;--ink:#e8eaed;--dim:#9aa3b2;--accent:#e0a458}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--bg);color:var(--ink);font:15px/1.6 -apple-system,"PingFang SC","Microsoft YaHei",sans-serif}}
.wrap{{max-width:1200px;margin:0 auto;padding:26px 16px 80px}}
h1{{font-size:22px;margin:0 0 4px}}
.sub{{color:var(--dim);margin:0 0 8px;font-size:13px}}
.note{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:13px 15px;color:var(--dim);font-size:12.5px;margin:14px 0 22px}}
.note b{{color:var(--ink)}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(240px,1fr));gap:16px}}
.card{{background:var(--card);border:1px solid var(--line);border-radius:12px;overflow:hidden;display:flex;flex-direction:column}}
.hd{{display:flex;align-items:center;gap:7px;padding:9px 11px;border-bottom:1px solid var(--line)}}
.n{{color:var(--accent);font-weight:800;font-size:15px}}
.shot{{color:var(--dim);font-size:11.5px;flex:1;line-height:1.3}}
.how{{font-size:10.5px;padding:2px 7px;border-radius:20px;white-space:nowrap}}
.how-t2i{{background:#1e2733;color:#7fb3ff}}
.how-ref{{background:#2b2417;color:var(--accent)}}
.how-still{{background:#1f2a1f;color:#8fd18f}}
.imgs{{display:flex;gap:2px;background:#000}}
.imgs figure{{margin:0;flex:1;position:relative}}
.imgs img{{width:100%;display:block}}
.imgs figcaption{{position:absolute;left:0;bottom:0;right:0;background:rgba(0,0,0,.6);color:#fff;font-size:10.5px;padding:3px 6px;text-align:center}}
.imgs.multi figure:first-child:after{{content:"→";position:absolute;right:-8px;top:50%;transform:translateY(-50%);color:var(--accent);font-weight:800;z-index:2}}
.pic{{padding:9px 11px;color:#cfd6e2;font-size:12.5px}}
</style></head>
<body><div class="wrap">
<h1>一个人的环中国自驾 · 关键帧审阅（20 张）</h1>
<p class="sub">Stage3 生图 · 18 镜关键帧全部生成，累计扣费 ¥5.5（母板 ¥0.5 + 关键帧 ¥5.0）· 请眼判身份/质感/合规/画面</p>
<div class="note">
<b>看点：</b>① 人物镜身份是否一致（母板A合照=03/05/15/18，母板B女主背影=12/14）；② 真实照片质感无塑料蜡感；③ 画面无文字/招牌/品牌/车牌字（打卡地名靠后期花字）；④ 9 站风光是否到位。<br>
<b>FL2VA 首尾（01/04）：</b>并排两图=同一镜的动作起止帧，供视频阶段生成"放入/驶出"动作。<b>注：01 首帧木地板、尾帧浅地毯背景不一致</b>，视频阶段做 FL2VA 前我会以首帧为参考重生尾帧锁背景（或该镜降为单首帧），不影响本页按单张画面审阅。<br>
<b>通过后：</b>逐张 accept 入账 → 关键帧组 gate-out → 进 stage4 H3 视频（~74s ≈ ¥14.8，另报账）。要改哪镜直接说镜号+怎么改，认可前重出最省钱（¥0.25/张）。
</div>
<div class="grid">
{''.join(cards)}
</div>
</div></body></html>"""

out=PROJ/"review/keyframes-review.html"
out.write_text(page,encoding="utf-8")
bad=page.encode("utf-8").count(b"\xc3\x83")+page.count("Ã")+page.count("â€")
print(f"wrote {out} | cards={len(SHOTS)} imgs={sum(len(s[4]) for s in SHOTS)} | mojibake={bad}")
