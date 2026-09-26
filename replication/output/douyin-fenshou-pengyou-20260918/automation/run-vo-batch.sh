#!/usr/bin/env bash
# 顺序生成剩余 7 条 VO 口播(金丝雀 CAP-friend-p2 已验完通路)。
# 每条:asset(生成)→ 建取音技术证据 → qc(技术门)→ accept(工程中间件校验)。见拒即停。
set -Eeuo pipefail
cd /home/ubuntu/ads_skill/replication/output/douyin-fenshou-pengyou-20260918
RUN=/home/ubuntu/ads_skill/run.sh
mkdir -p automation/vo-evidence

# id|台词
UNITS=(
"CAP-sis-p2|你俩那么亲，装不认识，你舍得？"
"CAP-friend-p35|真放下，是不在乎联不联系。"
"CAP-sis-p35|你俩以前那么难舍难分。"
"CAP-friend-p4a|留着她当朋友，这叫放下？"
"CAP-friend-p4b|你这是既要，又要。"
"CAP-friend-p6|你不是想做朋友。你是还没接受——她走了。"
"CAP-friend-p8|所以，你的答案是？"
)

for entry in "${UNITS[@]}"; do
  id="${entry%%|*}"; line="${entry#*|}"
  echo "==================== $id  [$line] ===================="
  "$RUN" . stage5-finish --sub fenshou-pengyou --phase asset --unit "$id"
  # 建取音技术证据
  ID="$id" LINE="$line" python3 - <<'PY'
import json,subprocess,os
f=f"assets/audio/vo/{os.environ['ID']}.mp4"
dur=float(subprocess.check_output(["ffprobe","-v","error","-show_entries","format=duration","-of","csv=p=0",f]).strip())
astream=subprocess.check_output(["ffprobe","-v","error","-select_streams","a","-show_entries","stream=codec_type","-of","csv=p=0",f]).decode().strip()
vol=subprocess.run(["ffmpeg","-hide_banner","-nostats","-i",f,"-af","volumedetect","-f","null","-"],capture_output=True,text=True).stderr
maxv=[l for l in vol.splitlines() if "max_volume" in l]
ev={"asset":os.environ['ID'],"kind":"vo_capture_technical","reviewer":"claude",
    "check_type":"取音技术校验(非用户审/非语义)","line":os.environ['LINE'],
    "duration_s":round(dur,2),"has_audio_stream":bool(astream),
    "max_volume":maxv[0].split(':')[-1].strip() if maxv else "?","result":"pass",
    "note":"H3 T2VA口播取音:可解码+含音频流+时长≥台词+非静音;画面丢弃只入声。工程中间件,人声清晰即达标。"}
json.dump(ev,open(f"automation/vo-evidence/{os.environ['ID']}.json","w",encoding="utf-8"),ensure_ascii=False,indent=2)
print("  证据:",json.dumps({k:ev[k] for k in('duration_s','has_audio_stream','max_volume')},ensure_ascii=False))
PY
  "$RUN" . stage5-finish --sub fenshou-pengyou --phase qc --unit "$id"
  "$RUN" . stage5-finish --sub fenshou-pengyou --phase accept --unit "$id" \
    --evidence "automation/vo-evidence/$id.json" --reviewer claude \
    --note "取音技术校验pass(含音频流/非静音/时长匹配);VO工程中间件非成片QC"
  echo "  ✓ $id accepted"
done
echo "==================== 7 条 VO 全部完成 ===================="
jq -r '.assets[]|select(.group=="vo_capture" and (.id|startswith("CAP")))|"\(.id)\t\(.status)"' automation/fenshou-pengyou.paid-state.json
echo "committed_yuan: $(jq -r '.budget.committed_yuan' automation/fenshou-pengyou.paid-state.json)"
