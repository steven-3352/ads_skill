#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="/home/ubuntu/ads_skill"
PROJECT_DIR="$ROOT_DIR/replication/output/love-story-level-5"
RUN_DIR="$PROJECT_DIR/automation-runs"
TASK_NAME="love-story-level-5-level-1"
STAMP="$(date '+%Y%m%d-%H%M%S')"
LOG_FILE="$RUN_DIR/${TASK_NAME}-${STAMP}.log"
FINAL_FILE="$RUN_DIR/${TASK_NAME}-${STAMP}.final.md"
PID_FILE="$RUN_DIR/${TASK_NAME}.pid"

PROMPT='无人值守完成 replication/output/love-story-level-5/01-虾壳.md 的“第一级自动生产”。不要向用户提问；无法安全判断、素材不合格、凭据缺失或预算不满足时停止并写报告，绝不绕过检查。

项目边界：先读 SKILL.md、references/three-skill-production-sop.md、references/ai-video-production-sop.md，以及 love-story-level-5 内 README.md、characters.md、01-虾壳.md、故事板、提示词和全部现有素材。所有案例产物只写入 love-story-level-5 及其子目录。通用编排层、SOP 优化和项目经验增量沉淀到根项目 references/；优先更新现有 canonical 文档，确需新增文档时同步更新 DOCUMENTATION.md、references/README.md 和 SKILL.md 索引。不要改无关文件，不 commit，不 push。

一级完成范围：盘点并验收已有图片和镜头01 MP4；补齐镜头02-08所需首帧与真实视频；下载生成结果；输出可供人工直接照做的剪辑包。不要自动终剪，不把静态推拉当视频。人工只负责依照剪辑包完成拼接、对白/旁白、字幕、声音和导出。

付费硬闸门：任何付费 API 之前，先生成 automation/preflight.json、automation/preflight.md 和 automation/cost-plan.json。使用 ffprobe/解码抽帧核实已有 MP4 的路径、时长、分辨率、帧率和可解码性；列出每个镜头已有资产、缺口、引用、预计生成秒数和风险。逐镜检查人物/服装/场景连续性、动作归属、动作可拍性、提示词时间容量、运镜冲突、前后衔接、无模型文字/水印要求，以及 Seedance/MiniMax 的 first_frame/last_frame/reference 兼容规则。问题未解决的镜头不得生成。

提示词可实现性硬闸门：每个视频提示词输出、展示或提交前必须先过 seedance-prompt-zh 审查，明确回答当前方案能否容易稳定表现、哪里不容易、如何在不改变主题和叙事功能下优化，并复审最终版本；把审查记录和最终 prompt 的 SHA-256 写入 seedance_feasibility_review。记录缺失、未通过、有 blocker 或 hash 失配时，不得称为正式提示词且不得生成。

费用按图片0.25元/张、视频0.20元/秒估算，已有素材不计费；目标总额10-20元，硬上限20元。cost-plan必须列首次成本、每镜头成本、预留重试和最坏累计值。不得为了达到10元增加无关生成；如果完成必要镜头实际低于10元，允许低于目标并解释。如果首次计划或任何下一次调用会超过20元，立即停止。每次付费调用前重新计算余额并记录。首次失败只诊断并重做最小失败单元；任何付费重试都不得自动执行，必须在报告中列增量成本后停止，等待用户另行确认。

预检全部通过后才可调用 replication/tools/generate-image.sh 和 replication/tools/generate-video.sh。默认复用已有镜头01，绝不重复生成。遵循 screenwriting-master 的既定剧情、可摄影动作、口语对白和克制表演；遵循 seedance-prompt-zh：每个@图片/@视频/@音频明确职责，10秒以上分时段，运镜不冲突，中文/字幕/旁白全部后期。保存每次请求JSON、响应、下载MP4、模型、时长和成本。生成后逐文件做ffprobe、完整解码、关键帧抽取和视觉检查；不能完成视觉检查时明确标为未验收。

必须输出 edit/01-虾壳-editing-pack.md：9:16完整时间线；镜头01-08实际文件名、素材入点/出点、目标时长、硬切/叠化/声音桥、画面功能、连续性；镜头01是否需剪掉母卡开头；逐句完整字幕表（时间码、说话人、画内/画外、断行、停顿、安全区）；小周/林晚/陈屿/老赵完整对白和建议免费音色；林晚两句旁白“后来我才知道，他不是喜欢剥虾。”和“他只是记得，我喜欢吃。”的准确时间码、语速、音量与停顿；虾壳脆响、筷子、水滴、呼吸、纸巾、键盘、餐馆人声、静默及BGM的分轨和相对音量；字幕字体/字号/颜色/描边/位置；切黑和1080x1920、24fps、H.264/AAC导出建议；人工终检清单。本集无商品广告，明确无品牌CTA。终版配音不得使用系统TTS；建议剪映中不带VIP标识的免费音色，并要求人工记录实际音色与朗读时长。

统一编排记录必须输出 automation/manifest.json、automation/stages.json、automation/production-log.md、automation/qc-report.md 和 automation/FINAL-REPORT.md。记录输入hash、路由screenwriting→ads镜头任务→seedance、阶段状态、依赖、产物、提示词版本、API/模型、成本、失败类型、重试和验收结论。把实际经验抽象到项目根 references/，至少覆盖预检闸门、预算算法、最小失败单元、人工剪辑交接字段，以及未来统一编排器的输入/状态/产物接口。禁止伪造生成、终剪或验收通过。

严格顺序：检查git与素材→只读预检→成本计划→付费闸门→必要首帧→逐镜再检查→必要视频→下载/验收→剪辑包→编排日志/SOP沉淀→FINAL-REPORT。若中途阻塞，也必须写完当前可安全产出的预检、成本、剪辑草案和最终报告。最终摘要列出完成项、未完成项、实际成本、文件路径、人工剪辑入口和阻塞原因。'

mkdir -p "$RUN_DIR"

if [[ -f "$PID_FILE" ]]; then
  old_pid="$(sed -n '1p' "$PID_FILE" 2>/dev/null || true)"
  if [[ "$old_pid" =~ ^[0-9]+$ ]] && kill -0 "$old_pid" 2>/dev/null; then
    echo "任务已在运行 (PID $old_pid)。"
    exit 1
  fi
  rm -f "$PID_FILE"
fi

cd "$ROOT_DIR"
nohup codex exec --dangerously-bypass-approvals-and-sandbox -C "$ROOT_DIR" -o "$FINAL_FILE" "$PROMPT" >"$LOG_FILE" 2>&1 &
pid=$!
printf '%s\n' "$pid" >"$PID_FILE"

echo "已启动《虾壳》一级自动生产任务。"
echo "PID: $pid"
echo "日志: $LOG_FILE"
echo "最终摘要: $FINAL_FILE"
