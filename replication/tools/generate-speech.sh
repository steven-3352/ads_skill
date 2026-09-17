#!/usr/bin/env bash
# 豆包(火山 openspeech) Seed-Audio TTS 合成:非流式 HTTP，单次 POST 直接返回音频。
# 用途：为对白/旁白配音生成真人声（补齐本机无 TTS 的能力边界）。
# 文档：POST $DOUBAO_BASE_URL/api/v3/tts/create ，X-Api-Key 单头鉴权。
# 计费依据：响应 original_duration（秒，上限 120）。
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$BASE_DIR/../.." && pwd)"
ENV_FILE="/home/ubuntu/ads_skill/.env"
[[ -f "$ENV_FILE" ]] || { echo "missing env: $ENV_FILE" >&2; exit 1; }
set -a; source "$ENV_FILE"; set +a

PROMPT_FILE=""
OUTPUT_DIR="./generated-audio"
OUTPUT_NAME=""
CLI_TEXT=""
CLI_SPEAKER=""
CLI_FORMAT=""
CLI_SR=""
CLI_MODEL=""
CLI_RESOURCE_ID=""
AUDIT_DIR=""
REQUEST_ID=""

usage() {
  cat >&2 <<'USAGE'
用法:
  generate-speech.sh --prompt <prompt.json> --output-dir <目录> [选项]
  generate-speech.sh --text "我喜欢你" --speaker <音色ID> --output-dir <目录>
选项:
  --prompt <file.json>     合成参数 JSON（见下方字段；与 --text 二选一或互补，CLI 覆盖 JSON）
  --output-dir <目录>      输出目录（默认 ./generated-audio）
  --output-name <名.wav>   输出文件名（默认按 format 生成时间戳名）
  --text <文本>            待合成文本/提示词（覆盖 JSON .text_prompt）
  --speaker <音色ID>       豆包音色 ID（覆盖 JSON .speaker）
  --format <wav|mp3|pcm|ogg_opus>  输出格式（覆盖 JSON .audio_config.format，默认 wav）
  --sample-rate <Hz>       采样率（覆盖 JSON .audio_config.sample_rate）
  --model <模型>           默认 seed-audio-1.0（覆盖 JSON .model）
  --resource-id <id>       计费资源标识 X-Api-Resource-Id（seed-audio 必带，默认 volc.service_type.10074；覆盖 JSON .resource_id / env DOUBAO_TTS_RESOURCE_ID；传 none 不发该头）
  --audit-dir <目录>       落盘请求/响应生命周期证据（付费幂等，配合 --request-id）
  --request-id <id>        单次付费请求幂等键

prompt.json 支持字段:
  text_prompt(必填,或用 --text) / model / speaker /
  audio_url | audio_data_file(本地音频→base64) | image_url | image_data_file(本地图→base64) /
  references(@音频N 参考列表,原样透传) /
  audio_config:{format,sample_rate,speech_rate,loudness_rate,pitch_rate,enable_subtitle} /
  watermark:{aigc_watermark:bool}
注: speaker / audio_* / image_* 互斥；图片参考不能与音频参考混用。
USAGE
  exit 2
}

die() { echo "错误: $*" >&2; exit 1; }

if [[ "${1:-}" != --* && -n "${1:-}" ]]; then
  PROMPT_FILE="${1:-}"
  if [[ -n "${2:-}" ]]; then OUTPUT_DIR="$(dirname "$2")"; OUTPUT_NAME="$(basename "$2")"; fi
else
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prompt) PROMPT_FILE="${2:-}"; shift 2 ;;
      --output-dir) OUTPUT_DIR="${2:-}"; shift 2 ;;
      --output-name) OUTPUT_NAME="${2:-}"; shift 2 ;;
      --text) CLI_TEXT="${2:-}"; shift 2 ;;
      --speaker) CLI_SPEAKER="${2:-}"; shift 2 ;;
      --format) CLI_FORMAT="${2:-}"; shift 2 ;;
      --sample-rate) CLI_SR="${2:-}"; shift 2 ;;
      --model) CLI_MODEL="${2:-}"; shift 2 ;;
      --resource-id) CLI_RESOURCE_ID="${2:-}"; shift 2 ;;
      --audit-dir) AUDIT_DIR="${2:-}"; shift 2 ;;
      --request-id) REQUEST_ID="${2:-}"; shift 2 ;;
      -h|--help) usage ;;
      *) echo "未知参数: $1" >&2; usage ;;
    esac
  done
fi

command -v jq >/dev/null || die "需要 jq"
command -v curl >/dev/null || die "需要 curl"
command -v base64 >/dev/null || die "需要 base64"
[[ -n "${DOUBAO_API_KEY:-}" ]] || die "缺少 DOUBAO_API_KEY（请在 .env 配置）"
[[ -n "${DOUBAO_BASE_URL:-}" ]] || die "缺少 DOUBAO_BASE_URL（请在 .env 配置）"

# 读取 JSON（可缺省），用 CLI 覆盖
J='{}'
if [[ -n "$PROMPT_FILE" ]]; then
  [[ -f "$PROMPT_FILE" ]] || die "找不到 prompt 文件: $PROMPT_FILE"
  J="$(jq -c '.' "$PROMPT_FILE")" || die "prompt JSON 解析失败"
fi
getj() { jq -r "$1 // empty" <<< "$J"; }

MODEL="${CLI_MODEL:-$(getj '.model')}"; MODEL="${MODEL:-seed-audio-1.0}"
TEXT="${CLI_TEXT:-$(getj '.text_prompt')}"
[[ -n "$TEXT" ]] || die "缺少 text_prompt（用 --text 或 JSON .text_prompt 提供）"
SPEAKER="${CLI_SPEAKER:-$(getj '.speaker')}"
AUDIO_URL="$(getj '.audio_url')"
AUDIO_DATA_FILE="$(getj '.audio_data_file')"
IMAGE_URL="$(getj '.image_url')"
IMAGE_DATA_FILE="$(getj '.image_data_file')"
REFERENCES="$(jq -c '.references // empty' <<< "$J")"

FMT="${CLI_FORMAT:-$(getj '.audio_config.format')}"; FMT="${FMT:-wav}"
case "$FMT" in wav|mp3|pcm|ogg_opus) ;; *) die "format 只能是 wav|mp3|pcm|ogg_opus";; esac
SR="${CLI_SR:-$(getj '.audio_config.sample_rate')}"
SPEECH_RATE="$(getj '.audio_config.speech_rate')"
LOUDNESS_RATE="$(getj '.audio_config.loudness_rate')"
PITCH_RATE="$(getj '.audio_config.pitch_rate')"
ENABLE_SUBTITLE="$(getj '.audio_config.enable_subtitle')"
AIGC_WM="$(jq -r '.watermark.aigc_watermark // empty' <<< "$J")"

# —— 互斥校验（照文档） ——
VOICE_SRC=0
[[ -n "$SPEAKER" ]] && VOICE_SRC=$((VOICE_SRC+1))
[[ -n "$AUDIO_URL" ]] && VOICE_SRC=$((VOICE_SRC+1))
[[ -n "$AUDIO_DATA_FILE" ]] && VOICE_SRC=$((VOICE_SRC+1))
[[ "$VOICE_SRC" -le 1 ]] || die "speaker / audio_url / audio_data_file 互斥，最多传一个"
IMG_SRC=0
[[ -n "$IMAGE_URL" ]] && IMG_SRC=$((IMG_SRC+1))
[[ -n "$IMAGE_DATA_FILE" ]] && IMG_SRC=$((IMG_SRC+1))
[[ "$IMG_SRC" -le 1 ]] || die "image_url / image_data_file 互斥，最多传一个"
if [[ "$IMG_SRC" -gt 0 && ( -n "$SPEAKER" || -n "$AUDIO_URL" || -n "$AUDIO_DATA_FILE" ) ]]; then
  die "图片参考不能与音频参考(speaker/audio_*)混用"
fi

# 输出名/路径
EXT="$FMT"; [[ "$FMT" == "ogg_opus" ]] && EXT="ogg"
[[ -n "$OUTPUT_NAME" ]] || OUTPUT_NAME="tts-$(date +%s).$EXT"
mkdir -p "$OUTPUT_DIR"
OUTPUT="$OUTPUT_DIR/$OUTPUT_NAME"
[[ ! -e "$OUTPUT" ]] || die "拒绝覆盖已存在输出: $OUTPUT"

if [[ -n "$AUDIT_DIR" || -n "$REQUEST_ID" ]]; then
  [[ -n "$AUDIT_DIR" && -n "$REQUEST_ID" ]] || die "audit-dir 与 request-id 必须同时使用"
  mkdir -p "$AUDIT_DIR"
fi

TEMP_DIR="$(mktemp -d)"; trap 'rm -rf "$TEMP_DIR"' EXIT
BODY="$TEMP_DIR/request.json"
RESPONSE="${AUDIT_DIR:-$TEMP_DIR}/response.json"

# 本地音频/图片 → base64（不落盘进源 JSON）
local_b64() { base64 < "$1" | tr -d '\n'; }
AUDIO_DATA=""
if [[ -n "$AUDIO_DATA_FILE" ]]; then
  [[ "$AUDIO_DATA_FILE" == /* ]] || AUDIO_DATA_FILE="$PROJECT_DIR/$AUDIO_DATA_FILE"
  [[ -f "$AUDIO_DATA_FILE" ]] || die "找不到本地参考音频: $AUDIO_DATA_FILE"
  AUDIO_DATA="$(local_b64 "$AUDIO_DATA_FILE")"
fi
IMAGE_DATA=""
if [[ -n "$IMAGE_DATA_FILE" ]]; then
  [[ "$IMAGE_DATA_FILE" == /* ]] || IMAGE_DATA_FILE="$PROJECT_DIR/$IMAGE_DATA_FILE"
  [[ -f "$IMAGE_DATA_FILE" ]] || die "找不到本地参考图片: $IMAGE_DATA_FILE"
  IMAGE_DATA="$(local_b64 "$IMAGE_DATA_FILE")"
fi

# 组装 audio_config（仅含已设字段）
AC="$(jq -n --arg fmt "$FMT" \
  --arg sr "$SR" --arg spr "$SPEECH_RATE" --arg lr "$LOUDNESS_RATE" \
  --arg pr "$PITCH_RATE" --arg sub "$ENABLE_SUBTITLE" \
  '{format:$fmt}
   + (if $sr  != "" then {sample_rate:($sr|tonumber)}   else {} end)
   + (if $spr != "" then {speech_rate:($spr|tonumber)}   else {} end)
   + (if $lr  != "" then {loudness_rate:($lr|tonumber)}  else {} end)
   + (if $pr  != "" then {pitch_rate:($pr|tonumber)}     else {} end)
   + (if $sub != "" then {enable_subtitle:($sub=="true")} else {} end)')"

# 组装请求体
jq -n \
  --arg model "$MODEL" --arg text "$TEXT" \
  --arg speaker "$SPEAKER" --arg audio_url "$AUDIO_URL" --arg audio_data "$AUDIO_DATA" \
  --arg image_url "$IMAGE_URL" --arg image_data "$IMAGE_DATA" \
  --argjson audio_config "$AC" \
  --arg aigc_wm "$AIGC_WM" \
  --argjson references "${REFERENCES:-null}" \
  '{model:$model, text_prompt:$text, audio_config:$audio_config}
   + (if $speaker    != "" then {speaker:$speaker}       else {} end)
   + (if $audio_url  != "" then {audio_url:$audio_url}   else {} end)
   + (if $audio_data != "" then {audio_data:$audio_data} else {} end)
   + (if $image_url  != "" then {image_url:$image_url}   else {} end)
   + (if $image_data != "" then {image_data:$image_data} else {} end)
   + (if $references != null then {references:$references} else {} end)
   + (if $aigc_wm    != "" then {watermark:{aigc_watermark:($aigc_wm=="true")}} else {} end)' \
  > "$BODY"

CREATE_URL="${DOUBAO_TTS_CREATE_URL:-${DOUBAO_BASE_URL%/}/api/v3/tts/create}"
REQ_ID_HEADER="${REQUEST_ID:-$(date +%s)-$RANDOM}"
# 可选计费资源标识：seed-audio 接口的授权校验要求显式带 X-Api-Resource-Id，
# 缺省会 403(45000030 not granted)。默认取 seed-audio 资源 volc.service_type.10074。
# 优先级：--resource-id > JSON .resource_id > 环境变量 DOUBAO_TTS_RESOURCE_ID > 默认值。留空("none")则不发该头。
RESOURCE_ID="${CLI_RESOURCE_ID:-$(getj '.resource_id')}"; RESOURCE_ID="${RESOURCE_ID:-${DOUBAO_TTS_RESOURCE_ID:-volc.service_type.10074}}"
RES_HEADER_ARGS=()
[[ -n "$RESOURCE_ID" && "$RESOURCE_ID" != "none" ]] && RES_HEADER_ARGS=(-H "X-Api-Resource-Id: $RESOURCE_ID")

if [[ -n "$AUDIT_DIR" ]]; then
  [[ ! -e "$AUDIT_DIR/submission.locked" ]] || die "request id 已用过: $REQUEST_ID"
  # 存请求体但抹掉可能很大的 base64 参考数据，避免审计目录膨胀/泄露原始素材
  jq 'if .audio_data then .audio_data="<base64 omitted>" else . end
      | if .image_data then .image_data="<base64 omitted>" else . end' "$BODY" \
      > "$AUDIT_DIR/request-body.json"
  jq -n --arg id "$REQUEST_ID" --arg url "$CREATE_URL" --arg out "$OUTPUT" --arg model "$MODEL" \
    '{request_id:$id,create_url:$url,output:$out,model:$model,automatic_retry:false,state:"submitting"}' \
    > "$AUDIT_DIR/lifecycle.json"
  : > "$AUDIT_DIR/submission.locked"
fi

set +e
curl --fail-with-body -sS -X POST "$CREATE_URL" \
  -H 'Content-Type: application/json; charset=utf-8' -H 'Accept: application/json' \
  -H "X-Api-Key: $DOUBAO_API_KEY" -H "X-Api-Request-Id: $REQ_ID_HEADER" \
  "${RES_HEADER_ARGS[@]}" \
  --data-binary "@$BODY" > "$RESPONSE"
CURL_RESULT=$?
set -e
if [[ "$CURL_RESULT" -ne 0 ]]; then
  echo "豆包 TTS 请求失败（curl exit $CURL_RESULT），服务端响应：" >&2
  jq 'if .audio then .audio="<omitted>" else . end' "$RESPONSE" >&2 2>/dev/null || sed -n '1,60p' "$RESPONSE" >&2
  [[ -n "$AUDIT_DIR" ]] && jq -n --arg id "$REQUEST_ID" '{request_id:$id,state:"ambiguous_submission",automatic_retry:false}' > "$AUDIT_DIR/lifecycle.json"
  exit "$CURL_RESULT"
fi

# 成功判定：优先看是否拿到音频(audio 或 url)；否则按 code/message 报错
AUDIO_B64="$(jq -r '.audio // empty' "$RESPONSE" 2>/dev/null || true)"
AUDIO_URL_OUT="$(jq -r '.url // empty' "$RESPONSE" 2>/dev/null || true)"
CODE="$(jq -r '.code // empty' "$RESPONSE" 2>/dev/null || true)"
MSG="$(jq -r '.message // empty' "$RESPONSE" 2>/dev/null || true)"
if [[ -z "$AUDIO_B64" && -z "$AUDIO_URL_OUT" ]]; then
  echo "豆包 TTS 未返回音频。code=$CODE message=$MSG" >&2
  jq 'if .audio then .audio="<omitted>" else . end' "$RESPONSE" >&2 2>/dev/null || true
  [[ -n "$AUDIT_DIR" ]] && jq -n --arg id "$REQUEST_ID" --arg c "$CODE" --arg m "$MSG" '{request_id:$id,state:"ambiguous_result",code:$c,message:$m,automatic_retry:false}' > "$AUDIT_DIR/lifecycle.json"
  exit 1
fi

if [[ -n "$AUDIO_B64" ]]; then
  printf '%s' "$AUDIO_B64" | base64 --decode > "$OUTPUT" || die "音频 base64 解码失败"
else
  curl --fail-with-body -sS -L "$AUDIO_URL_OUT" -o "$OUTPUT" || die "音频下载失败: $AUDIO_URL_OUT"
fi
[[ -s "$OUTPUT" ]] || die "输出音频为空: $OUTPUT"

ORIG_DUR="$(jq -r '.original_duration // empty' "$RESPONSE" 2>/dev/null || true)"
PROC_DUR="$(jq -r '.duration // empty' "$RESPONSE" 2>/dev/null || true)"
# 若返回字级时间戳则一并存下（方便逐句重放/对字幕）
if [[ -n "$AUDIT_DIR" ]]; then
  jq '.subtitle // empty' "$RESPONSE" > "$AUDIT_DIR/subtitle.json" 2>/dev/null || true
  sha256sum "$OUTPUT" > "$AUDIT_DIR/output.sha256"
  jq -n --arg id "$REQUEST_ID" --arg out "$OUTPUT" --arg od "$ORIG_DUR" \
    '{request_id:$id,state:"completed",output:$out,original_duration:$od,automatic_retry:false}' \
    > "$AUDIT_DIR/lifecycle.json"
fi
echo "音频已保存: $OUTPUT"
echo "计费时长 original_duration=${ORIG_DUR:-?}s  处理后 duration=${PROC_DUR:-?}s  format=$FMT"
