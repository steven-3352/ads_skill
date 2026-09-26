# fuke-A-home-v2 语义 QC 证据 — REJECT

- 资产：fuke-A-home-v2（女主居家服装母板 · 第二版，带 --reference master-A 强化否定参考服装）
- 产物：replication/output/fuke/assets/A-home-v2.png
- 结论：**拒绝（rejected）**
- 拒绝原因：**服装磁吸顽固**——即便提示词显式否定参考图服装、强化黄色小熊睡衣，image-edit 仍把脸母板 master-A 的**米白针织毛衣**磁吸过来（头部丸子头/发箍可覆盖，躯干服装区域顶不掉）。两次 --reference 生成均失败。
- 根因：复用 you-budong-me 脸母板（穿米白毛衣）与"固定黄色小熊睡衣造型"不可兼得。
- 处置：改**纯文生图**路线（references=[]，同已成功的 C 女同事母板），服装精确可控；女主脸全新但作为全片唯一造型锚锁死一致。重出 **fuke-A-home-v3**；本资产 superseded_by=fuke-A-home-v3。
- 时间：2026-09-22
