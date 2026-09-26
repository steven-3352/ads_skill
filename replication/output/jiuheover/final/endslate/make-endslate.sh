#!/usr/bin/env bash
# make-endslate.sh —— 通用可复用片尾生成器（竖屏 9:16）
# 特性：①参数化出品/主创/CTA，不绑定任何具体影片，可挂到任意片尾
#      ②支持把「幕后花絮」片段随意烧录进来（自动缩放铺底 + 烧角标），无花絮则只出出品卡
# 依赖：ffmpeg（含 drawtext / libx264）、Noto Serif/Sans CJK 字体
# 用法：
#   make-endslate.sh --out tail.mp4 \
#     [--brand "○○影业 出品"] [--line "编剧 / 导演   ○○○"] [--line "美术   ○○○"] \
#     [--cta "关注 · 追更完整正片"] [--slate-dur 5] [--bts 花絮1.mp4 --bts 花絮2.mp4]
#   --line 可重复，按顺序逐行居中排版；--bts 可重复，逐段烧「幕后花絮」角标
set -euo pipefail

SERIF="/usr/share/fonts/opentype/noto/NotoSerifCJK-Bold.ttc"
SANS="/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"
W=768; H=1344; FPS=24; AR=48000
OUT="endslate.mp4"; BRAND=""; CTA=""; SLATE_DUR=5
LINES=()
BTS=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --out) OUT="$2"; shift 2;;
    --brand) BRAND="$2"; shift 2;;
    --line) LINES+=("$2"); shift 2;;
    --cta) CTA="$2"; shift 2;;
    --slate-dur) SLATE_DUR="$2"; shift 2;;
    --bts) BTS+=("$2"); shift 2;;
    -h|--help) grep '^#' "$0" | sed 's/^# \?//'; exit 0;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT
i=0; PARTS=()

# ---- 幕后花絮段：任意片段缩放铺进 9:16 黑底 + 烧「幕后花絮」角标 ----
for clip in "${BTS[@]}"; do
  [[ -f "$clip" ]] || { echo "跳过不存在的花絮: $clip" >&2; continue; }
  seg="$TMP/bts_$i.mp4"
  # 有音轨用原声，无音轨补静音；统一到目标规格
  if ffprobe -v error -select_streams a -show_entries stream=index -of csv=p=0 "$clip" | grep -q .; then
    ffmpeg -y -i "$clip" -filter_complex \
      "[0:v]scale=$W:$H:force_original_aspect_ratio=decrease,pad=$W:$H:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,fps=$FPS,drawbox=x=24:y=40:w=196:h=64:color=black@0.45:t=fill,drawtext=fontfile=$SANS:text='幕后花絮':fontcolor=white@0.9:fontsize=38:x=44:y=54[v];[0:a]aresample=$AR[a]" \
      -map "[v]" -map "[a]" -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -r $FPS -c:a aac -b:a 160k -ar $AR -ac 2 "$seg" >/dev/null 2>&1
  else
    ffmpeg -y -i "$clip" -f lavfi -i "anullsrc=r=$AR:cl=stereo" -shortest -filter_complex \
      "[0:v]scale=$W:$H:force_original_aspect_ratio=decrease,pad=$W:$H:(ow-iw)/2:(oh-ih)/2:color=black,setsar=1,fps=$FPS,drawbox=x=24:y=40:w=196:h=64:color=black@0.45:t=fill,drawtext=fontfile=$SANS:text='幕后花絮':fontcolor=white@0.9:fontsize=38:x=44:y=54[v]" \
      -map "[v]" -map "1:a" -c:v libx264 -preset medium -crf 20 -pix_fmt yuv420p -r $FPS -c:a aac -b:a 160k -ar $AR -ac 2 "$seg" >/dev/null 2>&1
  fi
  PARTS+=("$seg"); i=$((i+1))
done

# ---- 出品卡：黑底 drawtext（品牌 + 分隔线 + N 行主创 + CTA）+ 极轻底噪渐隐 ----
BASE=$((H/2-90)); STEP=54
VF="drawbox=x=(iw-160)/2:y=$((BASE-58)):w=160:h=3:color=white@0.5:t=fill"
[[ -n "$BRAND" ]] && VF="$VF,drawtext=fontfile=$SERIF:text='$BRAND':fontcolor=white:fontsize=50:x=(w-text_w)/2:y=$((BASE-135))"
y=$BASE
for ln in "${LINES[@]}"; do
  VF="$VF,drawtext=fontfile=$SANS:text='$ln':fontcolor=white@0.85:fontsize=32:x=(w-text_w)/2:y=$y"
  y=$((y+STEP))
done
[[ -n "$CTA" ]] && VF="$VF,drawtext=fontfile=$SANS:text='$CTA':fontcolor=white@0.7:fontsize=34:x=(w-text_w)/2:y=$((y+50))"
VF="$VF,fade=t=in:st=0:d=0.6,fade=t=out:st=$(awk "BEGIN{print $SLATE_DUR-0.6}"):d=0.6,format=yuv420p"

slate="$TMP/slate.mp4"
ffmpeg -y -f lavfi -i "color=c=black:s=${W}x${H}:d=${SLATE_DUR}:r=$FPS" \
  -f lavfi -i "anoisesrc=color=pink:d=${SLATE_DUR}:r=$AR" \
  -filter_complex "[0:v]$VF[v];[1:a]lowpass=f=2000,volume=0.03,pan=stereo|c0=c0|c1=c0,afade=t=out:st=$(awk "BEGIN{print $SLATE_DUR-2}"):d=2[a]" \
  -map "[v]" -map "[a]" -t "$SLATE_DUR" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -r $FPS -c:a aac -b:a 160k -ar $AR -ac 2 "$slate" >/dev/null 2>&1
PARTS+=("$slate")

# ---- 拼接输出 ----
list="$TMP/list.txt"; : > "$list"
for p in "${PARTS[@]}"; do echo "file '$p'" >> "$list"; done
ffmpeg -y -f concat -safe 0 -i "$list" -c:v libx264 -preset medium -crf 18 -pix_fmt yuv420p -r $FPS \
  -c:a aac -b:a 160k -ar $AR -ac 2 -movflags +faststart "$OUT" >/dev/null 2>&1
echo "✔ 通用片尾: $OUT  时长 $(ffprobe -v error -show_entries format=duration -of csv=p=0 "$OUT")s  (花絮段 ${#BTS[@]} 个 + 出品卡 ${SLATE_DUR}s)"
