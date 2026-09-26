# fuke-A-home 语义 QC（人工看图）证据 — REJECT

- 资产：fuke-A-home（女主居家服装母板 · 首版）
- 产物：replication/output/fuke/assets/A-home.png
- 审阅方式：人工目视（主 agent 交叉审 + 技术QC已过）
- 结论：**拒绝（rejected）**
- 拒绝原因：**服装磁吸**——提示词要求「鲜明黄色卡通小熊图案居家睡衣套装」，实际生成为**米白色针织毛衣**（脸母板 master-A.png 本身穿米白毛衣，被 --reference 磁吸带过来）。发型（丸子头）、小熊发箍、锁脸、灯光/肤质均正确，唯服装不符固定造型锁。
- 处置：改进 fuke-A-home.json 提示词（显式声明参考图仅用于面部身份识别、否定参考图服装、强化黄色小熊睡衣宽松版型），重出 **fuke-A-home-v2**；本资产 superseded_by=fuke-A-home-v2。
- 时间：2026-09-22
