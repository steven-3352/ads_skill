# 能力地图（guoqing-p1）

| 阶段 | 看哪些文件 | 负责 Skill / 工具 |
|---|---|---|
| 剧本 | story/screenplay.md | screenwriting-master（上游已完成，用户终审） |
| 分镜 | contracts/production-plan.json、review/storyboard.md | ad-creative-expert；校验 scripts/validate-production-plan.mjs |
| 图片/视频提示词 | prompts/*.json | h3-prompt-writing；门 replication/tools/validate-h3-prompt-review.sh |
| 付费生成 | automation/guoqing-p1.paid-state.json | run.sh → stages/stage3-images.sh / stage4-videos.sh → paid-asset-orchestrator.sh → generate-image.sh / generate-video.sh |
| 状态机 | automation/guoqing-p1.ledger.ndjson | run.sh（唯一写者），references/state-machine/main-sequence.json |
| 规范 | SKILL.md、references/video-production-sop.md、references/storyboard-methodology.md | — |
