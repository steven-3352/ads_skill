# 金丝雀 U1-first-r2 语义否决记录

- **资产**: U1-first-r2（output: shots/shot-U1/images/U1-first-r2.png，cost ¥0.25 已花，沉没）
- **审阅方式**: 人工业务审阅（公网 https://www.tonbird.top/ads-review/jiuheover/review/index.html）
- **否决理由**: 酒器仍不符——r2 渲成矮胖白瓷瓶 + 白瓷小盅，用户要的是特定造型的中式白酒瓶与白酒杯。
- **用户指令（业务）**: 「酒杯，酒瓶都不对，参考 1.jpeg（白酒瓶），1白酒.png（白酒杯）作为参考图重新生成试试。」
- **参考素材**（用户提供，置于 assets/，仅作生成参考、不入交付/不入 git）:
  - 白酒瓶 assets/1.jpeg：乳白瓷圆柱直筒瓶身、平肩短颈、红色瓶盖+金色环圈、瓶身素白无字。
  - 白酒杯 assets/1白酒.png：透明玻璃高脚小酒杯（细玻璃杆 + 小碗杯身 + 圆底座），中式白酒品鉴杯。
- **补救**: 将 U1-first.json 改为三参考图（master-A 锁身份 + 1.jpeg 锁瓶型 + 1白酒.png 锁杯型），酒器措辞精确对齐参考并调整负向锁（删 no goblet/no glass bottle，加 no white porcelain cup/no ceramic cup），重盖章后授权 U1-first-r3 重生。
- **处置**: reject 本 r2 留痕 → 授权 U1-first-r3 重生。
- **reviewer**: human-canary-review（用户业务否决，编排代记）
