# CAPABILITY-MAP — iloveyou-everywhere-20260916

SOP 三 Skill 分工(见记忆 `sop-three-skill-roles-and-crosscheck`):

| 角色 | Skill | 本项目职责 |
|---|---|---|
| 总控 | ad-creative-expert | intake、编任务单、调度、验收、成本报账;守门禁(分镜前确认、付费前锁模型) |
| 编剧 | screenwriting-master | 写/优化剧本(`story/screenplay.md`)、逐拍事件设计、[C] 内容丰满度 |
| 提示词 | 模型技能(倾向 minimax-hailuo) | 把每拍写成生成提示词、逐界选 I2VA/FL2VA、身份锁、无缝转场参数 |

跨审:单会话扮三角需独立交叉审(编剧不自审提示词、提示词不自审剧本)。

## 关键决策(待锁)
- **模型**:倾向 MiniMax-H3(画内对白 + 声音 + 运镜)。付费前写入 `contracts/prompt-policy.json` 锁定。
- **生成粒度**:六界逐界单独生成 + 无缝转场拼接(命中率高)vs 长连续镜 → 分镜阶段定。
- **声音**:B1–B3 真人告白(H3 画内或后期配音);B4–B8 回响 + 结尾合唱 = **后期声音设计**(不依赖模型出合唱)。
- **字幕**:如需,后期统一烧(`tools/burn-subtitles.sh`),生成镜不直出。

## 巨物锚点清单(每界一个压倒性尺度主体 = 巨物效果)
天上=柔散暖光巨晕/云海 · 山川=万仞雪山巨脊 · 森林=参天巨木林冠 · 海底=巨鲸 · 地下=地心巨型晶洞 · 收束=上帝视角俯瞰天地。
