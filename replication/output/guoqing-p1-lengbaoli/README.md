# guoqing-p1｜《你说你要冷静，可你冷的是我》

- 目标：国庆 21.3s 对白驱动情感短剧（dou-keyi 同一对情侣续篇），16:9 横屏，MiniMax-H3，目标 10/3 发布。
- 当前阶段：`shot_videos_pending`（4 条视频已生成过技术 QC，草稿 edit/guoqing-p1-draft-v1.mp4，等用户看 review/videos-review.html 签核）。以总账为准：`./run.sh replication/output/guoqing-p1-lengbaoli --status --sub guoqing-p1`
- 权威文件：
  - 剧本：`story/screenplay.md`（用户终审 v2 大白话版逐字副本 + 确认记录；来源见 `story/source.md`）
  - 分镜：`contracts/production-plan.json`（机读，含 sceneSettings.SC_LIVING）+ `review/storyboard.md`（场景总设定 + A-G / H1-H4 填空）
  - 公共资产：`contracts/assets.json`；提示词 `prompts/`
  - 描述符/账本：`automation/guoqing-p1.project.json`、`.ledger.ndjson`、`.paid-state.json`
- 审阅页：https://www.tonbird.top/ads-review/guoqing-p1-lengbaoli/review/masters-review.html
- 预算：首轮 ≈¥6.8（公共资产 ¥0.75 + 关键帧 5 张 ¥1.25 + 视频 24s ¥4.8），hard_cap ¥10。
