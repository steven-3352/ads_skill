# 金丝雀 U1-first v1 语义否决记录

- **资产**: U1-first（v1，output: shots/shot-U1/images/U1-first.png，sha256 53b0a383…，cost ¥0.25 已花，沉没）
- **审阅方式**: 人工业务审阅（金丝雀出图挂公网 https://www.tonbird.top/ads-review/jiuheover/review/index.html）
- **否决理由**: 酒器渲成偏日式清酒器——细颈壶（徳利）+ 两只小猪口杯，与设定「中式白酒 / 茅台式素白无标白瓷瓶」不符。合规红线未破（瓶杯素白无任何文字/logo/品牌），纯器型气质问题。
- **用户指令（业务）**: 「B 酒瓶不对，白酒杯，茅台白瓷瓶。」
- **补救**: 已由独立 h3-prompt-writing 子 agent 将 16 份含酒器入画的提示词（U1~U6 first/video、U7-first、U8 first/last/video）统一改写为中式白酒器——矮胖圆润乳白瓷瓶（茅台式、短颈、白瓷盖、素白无标）+ 中式白瓷小酒盅，并加日式负向锁（no sake bottle/tokkuri/choko/long-neck…），全部重盖章过 validate-h3-prompt-review.sh（exit 0）。
- **处置**: reject 本 v1 留痕 → 授权 U1-first-r2 用改写后提示词重生金丝雀（再 ¥0.25），satisfied 后 supersede U1-first。
- **reviewer**: human-canary-review（用户业务否决，编排代记）
