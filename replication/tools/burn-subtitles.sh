#!/usr/bin/env bash
# burn-subtitles.sh — 确定性字幕后期烧录(SOP §13.2.1 前置准备的落地工具)
#
# 背景:MiniMax-H3 对白镜"非确定性烧字幕"(同片有的烧有的不烧,不能做成品)。
# 标准:H3 只出配音,字幕一律由本工具后期统一烧,一套样式、100% 一致、¥0。
#
# 两种字幕来源(二选一):
#   --subs  <a.srt|a.ass>     直接用现成 SRT/ASS
#   --manifest <m.json>       用结构化字幕清单自动生成 SRT 再烧(推荐,清单在分镜阶段就建)
#
# manifest.json 结构(时间单位:秒):
#   {
#     "clip_order": ["C1","C2","C3"],   // 可选:给出则按"弃尾拼接"换算全片时间轴
#     "clip_dur": 5.0,                   // 可选:每条弃尾后时长(默认 5.0);全片时间 = clip序号*clip_dur + t_start
#     "lines": [
#       {"clip":"C1","speaker":"S1","text":"起床啦——","t_start":0.3,"t_end":2.4},
#       {"clip":"C1","speaker":"S2","text":"唔……不要——","t_start":2.6,"t_end":4.8},
#       ...
#     ]
#   }
#   说明:给了 clip_order+clip_dur → lines 的 t_start/t_end 视为"片内相对时间",工具按 clip 序号加偏移换算成全片时间轴;
#         未给 → t_start/t_end 视为已是全片绝对时间。
#
# 统一样式(可被 --font-size / --margin-v 覆盖):Noto Sans CJK SC、底部居中、白字+黑描边、约画面 88% 高。
#
# 用法:
#   burn-subtitles.sh --input final.mp4 --manifest subs.json --output final.subbed.mp4
#   burn-subtitles.sh --input final.mp4 --subs subs.srt     --output final.subbed.mp4 [--font-size 42] [--margin-v 48]
set -euo pipefail

FONT_NAME="Noto Sans CJK SC"
FONT_SIZE=36
MARGIN_V=48
OUTLINE=2
IN=""; OUT=""; SUBS=""; MANIFEST=""
while [ $# -gt 0 ]; do
  case "$1" in
    --input) IN="$2"; shift 2;;
    --output) OUT="$2"; shift 2;;
    --subs) SUBS="$2"; shift 2;;
    --manifest) MANIFEST="$2"; shift 2;;
    --font-size) FONT_SIZE="$2"; shift 2;;
    --margin-v) MARGIN_V="$2"; shift 2;;
    --font-name) FONT_NAME="$2"; shift 2;;
    -h|--help) sed -n '2,40p' "$0"; exit 0;;
    *) echo "未知参数: $1" >&2; exit 2;;
  esac
done

[ -n "$IN" ] && [ -f "$IN" ] || { echo "缺 --input 或文件不存在: $IN" >&2; exit 2; }
[ -n "$OUT" ] || { echo "缺 --output" >&2; exit 2; }
[ -n "$SUBS" ] || [ -n "$MANIFEST" ] || { echo "需 --subs 或 --manifest 其一" >&2; exit 2; }

# 字体存在性检查(避免烧成方块)
if ! fc-list 2>/dev/null | grep -qi "$FONT_NAME"; then
  echo "警告:未找到字体「$FONT_NAME」,可能回退成方块。请先安装中文字体(如 Noto Sans CJK)。" >&2
fi

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT

# manifest → SRT
if [ -n "$MANIFEST" ]; then
  [ -f "$MANIFEST" ] || { echo "manifest 不存在: $MANIFEST" >&2; exit 2; }
  SUBS="$WORK/from-manifest.srt"
  python3 - "$MANIFEST" "$SUBS" <<'PY'
import json, sys
mf, out = sys.argv[1], sys.argv[2]
d = json.load(open(mf, encoding="utf-8"))
lines = d["lines"]
order = d.get("clip_order")
clip_dur = float(d.get("clip_dur", 5.0))
idx = {c: i for i, c in enumerate(order)} if order else None
def ts(sec):
    if sec < 0: sec = 0.0
    h = int(sec // 3600); m = int(sec % 3600 // 60); s = int(sec % 60); ms = int(round((sec - int(sec)) * 1000))
    if ms == 1000: s += 1; ms = 0
    return f"{h:02d}:{m:02d}:{s:02d},{ms:03d}"
rows = []
for ln in lines:
    a = float(ln["t_start"]); b = float(ln["t_end"])
    if idx is not None and "clip" in ln:
        off = idx[ln["clip"]] * clip_dur
        a += off; b += off
    rows.append((a, b, ln["text"]))
rows.sort(key=lambda r: r[0])
with open(out, "w", encoding="utf-8") as f:
    for i, (a, b, t) in enumerate(rows, 1):
        f.write(f"{i}\n{ts(a)} --> {ts(b)}\n{t}\n\n")
print(f"[manifest→srt] {len(rows)} 条字幕 -> {out}", file=sys.stderr)
PY
fi

[ -f "$SUBS" ] || { echo "字幕文件不存在: $SUBS" >&2; exit 2; }

# 统一 ASS 样式(subtitles filter 的 force_style):底部居中(Alignment=2)、白字、黑描边、无阴影
STYLE="FontName=${FONT_NAME},FontSize=${FONT_SIZE},PrimaryColour=&H00FFFFFF,OutlineColour=&H00000000,BorderStyle=1,Outline=${OUTLINE},Shadow=0,Alignment=2,MarginV=${MARGIN_V}"

# 转义字幕路径给 filtergraph
SUBS_ESC="$(printf '%s' "$SUBS" | sed "s/'/\\\\'/g")"

echo "烧录中: $IN  +  $SUBS  ->  $OUT"
ffmpeg -v error -y -i "$IN" \
  -vf "subtitles='${SUBS_ESC}':force_style='${STYLE}'" \
  -c:v libx264 -crf 18 -preset medium -pix_fmt yuv420p \
  -c:a copy -movflags +faststart "$OUT"

echo "OK -> $OUT ($(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")s)"
