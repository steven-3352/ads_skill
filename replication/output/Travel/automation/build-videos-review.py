#!/usr/bin/env python3
# 生成视频审阅 HTML（18镜，<video> 相对路径引 mp4，经 ads-review nginx 播放）。UTF-8 显式，mojibake 自检。
import html, pathlib
PROJ = pathlib.Path("/home/ubuntu/ads_skill/replication/output/Travel")

# (镜号, 景别/模式, 画面, 时长, 旁白(后期TTS,仅展示), mp4相对review路径)
SHOTS = [
 ("01","极近景FL2VA","叠红冲锋衣入箱（首帧举衣→尾帧v2平放入箱手离开）","4s","出发前一晚，我把你那件红外套，叠好，放进去。","../shots/01/video.mp4"),
 ("02","特写I2VA","指尖划过手绘环中国路线图·青海湖圈点","4s","这张图是咱俩画的，你圈的地方，我都记着。","../shots/02/video.mp4"),
 ("03","中景缓推I2VA","车内空副驾放两人合照相框","4s","说好两个人一起去的，现在啊，就剩我自己了。","../shots/03/video.mp4"),
 ("04","全景FL2VA","点火驶出小区（停门口→驶离）","4s","走吧。第一站，去你圈了最久的地方。","../shots/04/video.mp4"),
 ("05","驾驶舱POV I2VA","主驾视角看公路，副驾摆合照","4s","副驾上摆着咱俩的合照，这一路，你陪着我。","../shots/05/video.mp4"),
 ("06","远景航拍I2VA","青海湖笔直公路直通天际","4s","青海湖到了。这蓝，照片根本拍不出来，你说得对。","../shots/06/video.mp4"),
 ("07","全景航拍I2VA","茶卡盐湖天空之镜","4s","走到茶卡，脚下全是天，你要在准得乐疯。","../shots/07/video.mp4"),
 ("08","全景低仰I2VA","稻城亚丁雪山牛奶海经幡","4s","亚丁的雪山下头，风好大，我替你多站了会儿。","../shots/08/video.mp4"),
 ("09","车内POV I2VA","川藏318弯道雪山","4s","318 弯得吓人，你老说，开着开着就到了。","../shots/09/video.mp4"),
 ("10","全景平移I2VA","拉萨布达拉宫经幡朝圣","4s","到了拉萨，我替咱俩许了个愿，是啥不告诉你。","../shots/10/video.mp4"),
 ("11","全景航拍逆光I2VA","敦煌鸣沙山月牙泉驼队剪影","4s","敦煌的风裹着沙子，打在脸上，你肯定嫌糙。","../shots/11/video.mp4"),
 ("12","全景剪影I2VA","额济纳胡杨林女主背影","4s","胡杨林黄了。你不是老念叨嘛，黄了才好看。","../shots/12/video.mp4"),
 ("13","远景航拍I2VA","呼伦贝尔草原风掀草浪","4s","草原上风一刮，草浪一片一片的，人是真舒坦。","../shots/13/video.mp4"),
 ("14","中景背影I2VA","洱海边女主背影临湖","4s","洱海边上站着，风吹过来，我总觉得，你就在旁边。","../shots/14/video.mp4"),
 ("15","近景手持I2VA","手握两人合照，指腹摩挲","4s","地图上你圈过的每个地方，我一个一个，都替你走到了。","../shots/15/video.mp4"),
 ("16","车内后座I2VA","回望后视镜公路夕阳","5s","剩下的路还很长，没关系的，我一个人，会慢慢替你走完。","../shots/16/video.mp4"),
 ("17","全景航拍黄昏I2VA","日落公路逆光驶向太阳","4s","你在那边，这些好看的，应该都看到了吧？","../shots/17/video.mp4"),
 ("18","特写慢推I2VA","副驾两人合照特写定格","5s","答应过你的……我都做到了。","../shots/18/video.mp4"),
]

def esc(s): return html.escape(s)
cards=[]
for num,shot,pic,dur,vo,mp4 in SHOTS:
    exists=(PROJ/"shots"/num/"video.mp4").exists()
    badge = "<span class='ok'>已生成</span>" if exists else "<span class='miss'>生成中·刷新</span>"
    # 始终挂播放器：已生成的可播，生成中的稍后刷新即出现
    vid = f"<video src='{esc(mp4)}' controls preload='metadata' playsinline></video>"
    cards.append(f"""<div class='card'>
      <div class='hd'><span class='n'>{esc(num)}</span><span class='shot'>{esc(shot)}</span><span class='dur'>{esc(dur)}</span>{badge}</div>
      <div class='vwrap'>{vid}</div>
      <div class='pic'>{esc(pic)}</div>
      <div class='vo'>旁白(后期TTS配)：{esc(vo)}</div>
    </div>""")

page=f"""<!DOCTYPE html>
<html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>环中国自驾 · 视频审阅</title>
<style>
:root{{--bg:#0f1115;--card:#171a21;--line:#262b36;--ink:#e8eaed;--dim:#9aa3b2;--accent:#e0a458}}
*{{box-sizing:border-box}}
body{{margin:0;background:var(--bg);color:var(--ink);font:15px/1.6 -apple-system,"PingFang SC","Microsoft YaHei",sans-serif}}
.wrap{{max-width:1280px;margin:0 auto;padding:26px 16px 80px}}
h1{{font-size:22px;margin:0 0 4px}}
.sub{{color:var(--dim);margin:0 0 8px;font-size:13px}}
.note{{background:var(--card);border:1px solid var(--line);border-radius:10px;padding:13px 15px;color:var(--dim);font-size:12.5px;margin:14px 0 22px}}
.note b{{color:var(--ink)}}
.grid{{display:grid;grid-template-columns:repeat(auto-fill,minmax(260px,1fr));gap:16px}}
.card{{background:var(--card);border:1px solid var(--line);border-radius:12px;overflow:hidden;display:flex;flex-direction:column}}
.hd{{display:flex;align-items:center;gap:7px;padding:9px 11px;border-bottom:1px solid var(--line)}}
.n{{color:var(--accent);font-weight:800;font-size:15px}}
.shot{{color:var(--dim);font-size:11.5px;flex:1;line-height:1.3}}
.dur{{font-size:10.5px;color:#7fb3ff;background:#1e2733;padding:2px 7px;border-radius:20px}}
.miss{{font-size:10.5px;color:#ffcf8a;background:#332a1e;padding:2px 7px;border-radius:20px}}
.ok{{font-size:10.5px;color:#8ce0a0;background:#1e3324;padding:2px 7px;border-radius:20px}}
.vwrap{{background:#000;line-height:0}}
.vwrap video{{width:100%;display:block;max-height:70vh}}
.ph{{color:var(--dim);font-size:12px;padding:40px 0;text-align:center;line-height:1.4}}
.pic{{padding:9px 11px;color:#cfd6e2;font-size:12.5px}}
.vo{{padding:0 11px 11px;color:var(--dim);font-size:12px;font-style:italic}}
</style></head>
<body><div class="wrap">
<h1>一个人的环中国自驾 · 视频审阅（18 镜）</h1>
<p class="sub">Stage4 H3 视频 · 抖音 9:16 · 旁白后期 TTS 单配（视频本身零对白字幕）· 请眼判画面/连贯/质感/合规</p>
<div class="note">
<b>看点：</b>① 画面真实质感无塑料蜡感；② 运镜自然不飘、无崩坏变形；③ 无文字/招牌/品牌/车牌字（地名靠后期花字）；④ 情绪弧 怅惘→坚定→眷恋→释然。<br>
<b>音频：</b>视频自带现场同期音效底噪（风/引擎/水声等），<b>旁白与配乐后期加</b>，此处先审画面与音效。<br>
<b>镜01/04 FL2VA：</b>看首尾动作是否连贯（镜01尾帧已重生锁背景，注意叠衣入箱的背景连续）。<br>
<b>要改哪镜：</b>直接说镜号+问题，我单独 reject 重生成（¥0.2/秒）。全部认可后进成片拼接。
</div>
<div class="grid">
{''.join(cards)}
</div>
</div></body></html>"""

out=PROJ/"review/videos-review.html"
out.write_text(page,encoding="utf-8")
bad=page.encode("utf-8").count(b"\xc3\x83")+page.count("Ã")+page.count("â€")
present=sum(1 for s in SHOTS if (PROJ/"shots"/s[0]/"video.mp4").exists())
print(f"wrote {out} | cards={len(SHOTS)} videos_present={present}/18 | mojibake={bad}")
