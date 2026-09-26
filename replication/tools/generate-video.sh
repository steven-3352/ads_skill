#!/usr/bin/env bash
set -Eeuo pipefail

BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$BASE_DIR/../.." && pwd)"
ENV_FILE="/home/ubuntu/ads_skill/.env"
[[ -f "$ENV_FILE" ]] || { echo "找不到项目配置: $ENV_FILE" >&2; exit 1; }
set -a; source "$ENV_FILE"; set +a

PROMPT_FILE=""
OUTPUT_DIR="./generated-videos"
OUTPUT_NAME="video-task-$(date +%s).json"
PROVIDER="${VIDEO_PROVIDER:-minimax}"
CLI_REFERENCES=()
WAIT=false
DOWNLOAD=false

usage() {
  cat >&2 <<'USAGE'
用法: generate-video.sh --prompt <prompt.json> --output-dir <目录> [选项]
选项:
  --output-name <文件名.json>    输出响应文件名
  --provider <minimax|seedance>  接口协议，默认 minimax H3
  --reference <素材>             参考素材，可重复传入并覆盖 JSON 中的素材
  --model <模型>                 覆盖环境变量中的模型
  --wait                         提交后轮询并保存最终响应
  --download                     轮询完成后下载 MP4（需同时使用 --wait）
USAGE
  exit 2
}

die() { echo "错误: $*" >&2; exit 1; }

if [[ "${1:-}" != --* ]]; then
  PROMPT_FILE="${1:-}"
  if [[ -n "${2:-}" ]]; then OUTPUT_DIR="$(dirname "$2")"; OUTPUT_NAME="$(basename "$2")"; fi
else
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --prompt) PROMPT_FILE="${2:-}"; shift 2 ;;
      --output-dir) OUTPUT_DIR="${2:-}"; shift 2 ;;
      --output-name) OUTPUT_NAME="${2:-}"; shift 2 ;;
      --provider) PROVIDER="${2:-}"; shift 2 ;;
      --reference) CLI_REFERENCES+=("${2:-}"); shift 2 ;;
      --model) VIDEO_MODEL="${2:-}"; shift 2 ;;
      --wait) WAIT=true; shift ;;
      --download) DOWNLOAD=true; shift ;;
      -h|--help) usage ;;
      *) echo "未知参数: $1" >&2; usage ;;
    esac
  done
fi
[[ -n "$PROMPT_FILE" && -f "$PROMPT_FILE" ]] || usage
if [[ "$PROVIDER" == "seedance" ]]; then
  "$BASE_DIR/validate-seedance-prompt-review.sh" "$PROMPT_FILE" video
else
  "$BASE_DIR/validate-h3-prompt-review.sh" "$PROMPT_FILE" video
fi
mkdir -p "$OUTPUT_DIR"
OUTPUT="$OUTPUT_DIR/$OUTPUT_NAME"
command -v jq >/dev/null || { echo "需要 jq" >&2; exit 1; }
command -v curl >/dev/null || { echo "需要 curl" >&2; exit 1; }

PROMPT="$(jq -er '.prompt' "$PROMPT_FILE")"
if [[ "${#CLI_REFERENCES[@]}" -gt 0 ]]; then
  REFERENCES="$(printf '%s\n' "${CLI_REFERENCES[@]}" | jq -Rsc 'split("\n") | map(select(length > 0))')"
else
  REFERENCES="$(jq -c '.images // []' "$PROMPT_FILE")"
fi

# Seedance rejects first/last-frame items mixed with reference media in one request.
if [[ "$PROVIDER" == "seedance" ]]; then
  CONTENT_CHECK="$(jq -c '.content // []' "$PROMPT_FILE")"
  if [[ "$CONTENT_CHECK" != "[]" ]]; then
    HAS_FRAME="$(jq '[.[] | select(.role == "first_frame" or .role == "last_frame")] | length' <<< "$CONTENT_CHECK")"
    HAS_REFERENCE="$(jq '[.[] | select(.role == "reference_image" or .role == "reference_video" or .role == "reference_audio")] | length' <<< "$CONTENT_CHECK")"
    if [[ "$HAS_FRAME" -gt 0 && "$HAS_REFERENCE" -gt 0 ]]; then
      echo "Seedance 参数错误：first_frame/last_frame 不能与 reference_image/reference_video/reference_audio 混用" >&2
      exit 1
    fi
  fi
fi
DURATION="$(jq -r '.duration // 5' "$PROMPT_FILE")"
RATIO="$(jq -r '.ratio // .aspect_ratio // "9:16"' "$PROMPT_FILE")"
GENERATE_AUDIO="$(jq -r '.generate_audio // true' "$PROMPT_FILE")"
WATERMARK="$(jq -r '.watermark // false' "$PROMPT_FILE")"
RESOLUTION="$(jq -r '.resolution // empty' "$PROMPT_FILE")"
CAMERA_FIXED="$(jq -r '.camera_fixed // empty' "$PROMPT_FILE")"

if [[ "$PROVIDER" == "seedance" ]]; then
  [[ -n "${SEEDANCE_API_KEY:-}" ]] || { echo "缺少 SEEDANCE_API_KEY" >&2; exit 1; }
  [[ -n "${SEEDANCE_BASE_URL:-}" ]] || die "缺少 SEEDANCE_BASE_URL（请在 .env 配置，脚本不再使用硬编码兜底地址）"
  BASE_URL="${SEEDANCE_BASE_URL%/}"; [[ "$BASE_URL" == */v1 ]] || BASE_URL="$BASE_URL/v1"
  MODEL="${VIDEO_MODEL:-${SEEDANCE_MODEL_ID:-doubao-seedance-2-0-mini-260615}}"
  CONTENT="$(jq -c '.content // empty' "$PROMPT_FILE")"
  if [[ -z "$CONTENT" || "$CONTENT" == "null" ]]; then
    CONTENT="$(jq -c '[.[] | {type:"image_url", image_url:{url:.}, role:"reference_image"}]' <<< "$REFERENCES")"
  fi
  SEEDANCE_TEMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$SEEDANCE_TEMP_DIR"' EXIT
  CONTENT_FILE="$SEEDANCE_TEMP_DIR/content.json"
  printf '%s' "$CONTENT" > "$CONTENT_FILE"

  # Local image inputs avoid hard-coded public URLs. They are converted only in
  # the temporary request and never persisted in the source prompt JSON.
  while IFS=$'\t' read -r INDEX LOCAL_PATH; do
    [[ -n "$LOCAL_PATH" ]] || continue
    if [[ "$LOCAL_PATH" != /* ]]; then LOCAL_PATH="$PROJECT_DIR/$LOCAL_PATH"; fi
    [[ -f "$LOCAL_PATH" ]] || { echo "找不到本地 Seedance 素材: $LOCAL_PATH" >&2; exit 1; }
    case "${LOCAL_PATH##*.}" in
      jpg|JPG|jpeg|JPEG) MIME_TYPE="image/jpeg" ;;
      webp|WEBP) MIME_TYPE="image/webp" ;;
      *) MIME_TYPE="image/png" ;;
    esac
    DATA_URL_FILE="$SEEDANCE_TEMP_DIR/data-url-$INDEX.txt"
    {
      printf 'data:%s;base64,' "$MIME_TYPE"
      base64 < "$LOCAL_PATH" | tr -d '\n'
    } > "$DATA_URL_FILE"
    NEXT_CONTENT_FILE="$SEEDANCE_TEMP_DIR/content-next.json"
    jq --argjson index "$INDEX" --rawfile data_url "$DATA_URL_FILE" \
      '.[$index].image_url = {url:$data_url} | del(.[$index].local_path)' \
      "$CONTENT_FILE" > "$NEXT_CONTENT_FILE"
    mv "$NEXT_CONTENT_FILE" "$CONTENT_FILE"
  done < <(jq -r 'to_entries[] | select(.value.local_path != null) | [.key, .value.local_path] | @tsv' "$CONTENT_FILE")

  REQUEST="$SEEDANCE_TEMP_DIR/request.json"
  jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --slurpfile content "$CONTENT_FILE" \
    --arg ratio "$RATIO" --argjson audio "$GENERATE_AUDIO" --argjson watermark "$WATERMARK" \
    --arg duration "$DURATION" --arg resolution "$RESOLUTION" --arg camera_fixed "$CAMERA_FIXED" \
    '{model:$model,prompt:$prompt,metadata:({content:$content[0],ratio:$ratio,generate_audio:$audio,watermark:$watermark} +
      (if $duration != "" then {duration:($duration|tonumber)} else {} end) +
      (if $resolution != "" then {resolution:$resolution} else {} end) +
      (if $camera_fixed != "" then {camera_fixed:($camera_fixed == "true")} else {} end))}' > "$REQUEST"
  if ! curl --fail-with-body -sS -X POST "${SEEDANCE_CREATE_PATH:-$BASE_URL/video/generations}" \
    -H 'Content-Type: application/json' -H "Authorization: Bearer $SEEDANCE_API_KEY" \
    --data-binary "@$REQUEST" > "$OUTPUT"; then
    echo "Seedance 创建任务失败，服务端响应：" >&2
    jq . "$OUTPUT" >&2 2>/dev/null || sed -n '1,120p' "$OUTPUT" >&2
    exit 1
  fi
  echo "Seedance 视频任务响应已保存: $OUTPUT"
  if [[ "$WAIT" == true ]]; then
    TASK_ID="$(jq -r '.id // .task_id // empty' "$OUTPUT")"; [[ -n "$TASK_ID" ]] || exit 1
    STATUS_FILE="$OUTPUT.status.json"
    while true; do
      curl --fail-with-body -sS "${SEEDANCE_STATUS_BASE:-$BASE_URL/videos}/$TASK_ID" \
        -H "Authorization: Bearer $SEEDANCE_API_KEY" > "$STATUS_FILE"
      STATUS="$(jq -r '.status // .data.status // empty' "$STATUS_FILE" | tr '[:upper:]' '[:lower:]')"
      echo "任务 $TASK_ID 状态: ${STATUS:-unknown}"
      [[ "$STATUS" == "completed" || "$STATUS" == "success" ]] && break
      [[ "$STATUS" == "failed" ]] && exit 1
      sleep "${SEEDANCE_POLL_SECONDS:-30}"
    done
    echo "最终任务响应已保存: $STATUS_FILE"
    if [[ "$DOWNLOAD" == true ]]; then
      VIDEO_URL="$(jq -r '.metadata.url // .data.url // .data.video_url // .video_url // empty' "$STATUS_FILE")"
      [[ -n "$VIDEO_URL" ]] || { echo "完成响应中没有找到视频 URL，请检查: $STATUS_FILE" >&2; exit 1; }
      VIDEO_OUTPUT="$OUTPUT_DIR/${OUTPUT_NAME%.json}.mp4"
      curl --fail-with-body -sS -L "$VIDEO_URL" -o "$VIDEO_OUTPUT"
      [[ -s "$VIDEO_OUTPUT" ]] || { echo "视频下载失败或文件为空: $VIDEO_OUTPUT" >&2; exit 1; }
      echo "视频已下载: $VIDEO_OUTPUT"
    fi
  fi
elif [[ "$PROVIDER" == "minimax" ]]; then
  [[ -n "${MINIMAX_API_KEY:-${MINIMAX_H3_API_KEY:-}}" ]] || die "缺少 MINIMAX_API_KEY 或 MINIMAX_H3_API_KEY"
  API_KEY="${MINIMAX_API_KEY:-$MINIMAX_H3_API_KEY}"
  MODE="${H3_API_MODE:-v2}"
  MINIMAX_TEMP_DIR="$(mktemp -d)"
  trap 'rm -rf "$MINIMAX_TEMP_DIR"' EXIT
  REQUEST="$MINIMAX_TEMP_DIR/request.json"

  if [[ "$MODE" == "v2" ]]; then
    BASE_URL="${MINIMAX_H3_BASE_URL:-${MINIMAX_BASE_URL:-}}"
    [[ -n "$BASE_URL" ]] || die "缺少 MINIMAX_H3_BASE_URL 或 MINIMAX_BASE_URL（请在 .env 配置，脚本不再使用硬编码兜底地址）"
    BASE_URL="${BASE_URL%/}"
    CREATE_URL="${MINIMAX_CREATE_URL:-$BASE_URL/minimax/v2/video_generation}"
    STATUS_BASE="${MINIMAX_STATUS_BASE:-$BASE_URL/minimax/v2/query/video_generation}"
    MODEL="${VIDEO_MODEL:-${MINIMAX_MODEL_ID:-MiniMax-H3}}"
    MINIMAX_RESOLUTION_VALUE="${MINIMAX_RESOLUTION:-${RESOLUTION:-768P}}"
    [[ "$MINIMAX_RESOLUTION_VALUE" == "720p" ]] && MINIMAX_RESOLUTION_VALUE="768P"
    CONTEXT_IR="${MINIMAX_USE_CONTEXT_IR:-false}"
    CONTENT="$(jq -c '.content // empty' "$PROMPT_FILE")"

    if [[ -z "$CONTENT" || "$CONTENT" == "null" ]]; then
      CONTENT="$(jq -c 'to_entries | map({type:"image_url",image_url:{url:("pending")},local_path:.value,role:(if .key == 0 then "first_frame" else "last_frame" end)})' <<< "$REFERENCES")"
    fi
    # 角色白名单：图片=first_frame/last_frame/reference_image；视频=reference_video；音频=reference_audio。
    BAD_ROLE="$(jq -r '
      [.[] | select(
        (.type=="image_url" and ((.role // "") as $r | ($r=="first_frame" or $r=="last_frame" or $r=="reference_image") | not)) or
        (.type=="video_url" and (.role!="reference_video")) or
        (.type=="audio_url" and (.role!="reference_audio")) or
        ((.type=="image_url" or .type=="video_url" or .type=="audio_url") | not)
      )] | length' <<< "$CONTENT")"
    [[ "$BAD_ROLE" -eq 0 ]] || die "MiniMax H3 v2 content 角色非法：图片只能 first_frame/last_frame/reference_image，视频只能 reference_video，音频只能 reference_audio"

    FRAME_COUNT="$(jq '[.[] | select(.role=="first_frame" or .role=="last_frame")] | length' <<< "$CONTENT")"
    REF_IMG="$(jq '[.[] | select(.role=="reference_image")] | length' <<< "$CONTENT")"
    REF_VID="$(jq '[.[] | select(.role=="reference_video")] | length' <<< "$CONTENT")"
    REF_AUD="$(jq '[.[] | select(.role=="reference_audio")] | length' <<< "$CONTENT")"
    REF_COUNT=$((REF_IMG + REF_VID + REF_AUD))
    RATIO_SET="$(jq -r 'if (.ratio // .aspect_ratio) then "yes" else "no" end' "$PROMPT_FILE")"

    # 帧条件族(first/last_frame)与参考族(reference_*)在 H3 v2 里互斥，不能同请求混用。
    if [[ "$FRAME_COUNT" -gt 0 && "$REF_COUNT" -gt 0 ]]; then
      die "MiniMax H3 v2 首尾帧(first/last_frame)与参考素材(reference_*)不能在同一请求混用"
    fi

    if [[ "$REF_COUNT" -gt 0 ]]; then
      # 参考族 Ref2VA：音频不能单独作参考；官方上限 图≤9 / 视频≤3 / 音频≤3。
      if [[ "$REF_AUD" -gt 0 && $((REF_IMG + REF_VID)) -eq 0 ]]; then
        die "MiniMax H3 v2 参考音频不能单独作参考，至少需一张 reference_image 或一段 reference_video"
      fi
      [[ "$REF_IMG" -le 9 ]] || die "MiniMax H3 v2 reference_image 最多 9 张（当前 $REF_IMG）"
      [[ "$REF_VID" -le 3 ]] || die "MiniMax H3 v2 reference_video 最多 3 段（当前 $REF_VID）"
      [[ "$REF_AUD" -le 3 ]] || die "MiniMax H3 v2 reference_audio 最多 3 段（当前 $REF_AUD）"
      REF_MODE=true
    else
      # 帧条件族：有图片但无 first_frame 报错；纯文生视频(完全无图片)放行。
      HAS_FIRST_FRAME="$(jq '[.[] | select(.type == "image_url" and .role == "first_frame")] | length' <<< "$CONTENT")"
      HAS_ANY_IMAGE="$(jq '[.[] | select(.type == "image_url")] | length' <<< "$CONTENT")"
      if [[ "$HAS_FIRST_FRAME" -eq 0 && "$HAS_ANY_IMAGE" -gt 0 ]]; then
        die "MiniMax H3 v2 有图片素材时至少需要一张 first_frame"
      fi
      REF_MODE=false
    fi

    CONTENT_FILE="$MINIMAX_TEMP_DIR/content.json"
    printf '%s' "$CONTENT" > "$CONTENT_FILE"
    while IFS=$'\t' read -r INDEX ITEM_TYPE LOCAL_PATH; do
      [[ -n "$LOCAL_PATH" ]] || continue
      if [[ "$LOCAL_PATH" != /* ]]; then LOCAL_PATH="$PROJECT_DIR/$LOCAL_PATH"; fi
      [[ -f "$LOCAL_PATH" ]] || die "找不到本地 MiniMax 素材: $LOCAL_PATH"
      EXT="${LOCAL_PATH##*.}"; EXT="${EXT,,}"
      case "$ITEM_TYPE" in
        image_url)
          case "$EXT" in jpg|jpeg) MIME_TYPE="image/jpeg" ;; webp) MIME_TYPE="image/webp" ;; *) MIME_TYPE="image/png" ;; esac
          URL_FIELD="image_url" ;;
        audio_url)
          # H3 参考音频仅支持 WAV / MP3（官方约束）。
          case "$EXT" in mp3) MIME_TYPE="audio/mpeg" ;; wav) MIME_TYPE="audio/wav" ;; *) die "MiniMax H3 参考音频仅支持 mp3/wav（收到 .$EXT），请先用 ffmpeg 转码" ;; esac
          URL_FIELD="audio_url" ;;
        video_url)
          case "$EXT" in mp4) MIME_TYPE="video/mp4" ;; mov) MIME_TYPE="video/quicktime" ;; *) die "MiniMax H3 参考视频仅支持 mp4/mov（收到 .$EXT）" ;; esac
          URL_FIELD="video_url" ;;
        *) die "MiniMax H3 v2 未知 content 类型: ${ITEM_TYPE:-空}" ;;
      esac
      DATA_URL_FILE="$MINIMAX_TEMP_DIR/data-url-$INDEX.txt"
      {
        printf 'data:%s;base64,' "$MIME_TYPE"
        base64 < "$LOCAL_PATH" | tr -d '\n'
      } > "$DATA_URL_FILE"
      NEXT_CONTENT_FILE="$MINIMAX_TEMP_DIR/content-next.json"
      jq --argjson index "$INDEX" --arg field "$URL_FIELD" --rawfile data_url "$DATA_URL_FILE" \
        '.[$index][$field] = {url:$data_url} | del(.[$index].local_path)' \
        "$CONTENT_FILE" > "$NEXT_CONTENT_FILE"
      mv "$NEXT_CONTENT_FILE" "$CONTENT_FILE"
    done < <(jq -r 'to_entries[] | select(.value.local_path != null) | [.key, .value.type, .value.local_path] | @tsv' "$CONTENT_FILE")

    if [[ "$REF_MODE" == true && "$RATIO_SET" == "no" ]]; then
      # 参考族(Ref2VA)且未显式指定比例：省略 ratio，交给 H3 adaptive 跟随参考图（与实测一致）。
      jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --slurpfile content "$CONTENT_FILE" \
        --arg duration "$DURATION" --arg resolution "$MINIMAX_RESOLUTION_VALUE" \
        --arg context_ir "$CONTEXT_IR" --argjson watermark "$WATERMARK" \
        '{model:$model,content:([{type:"text",text:$prompt}] + $content[0]),duration:($duration|tonumber),resolution:$resolution,use_context_ir:($context_ir == "true"),aigc_watermark:$watermark}' > "$REQUEST"
    else
      jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --slurpfile content "$CONTENT_FILE" \
        --arg duration "$DURATION" --arg resolution "$MINIMAX_RESOLUTION_VALUE" --arg ratio "$RATIO" \
        --arg context_ir "$CONTEXT_IR" --argjson watermark "$WATERMARK" \
        '{model:$model,content:([{type:"text",text:$prompt}] + $content[0]),duration:($duration|tonumber),resolution:$resolution,ratio:$ratio,use_context_ir:($context_ir == "true"),aigc_watermark:$watermark}' > "$REQUEST"
    fi
  elif [[ "$MODE" == "compat" ]]; then
    BASE_URL="${MINIMAX_H3_BASE_URL:-${MINIMAX_BASE_URL:-${MINIMAX_H3_API_URL:-}}}"
    [[ -n "$BASE_URL" ]] || die "缺少 MINIMAX_H3_BASE_URL / MINIMAX_BASE_URL / MINIMAX_H3_API_URL（请在 .env 配置，脚本不再使用硬编码兜底地址）"
    BASE_URL="${BASE_URL%/}"; [[ "$BASE_URL" == */v1 ]] || BASE_URL="$BASE_URL/v1"
    CREATE_URL="${MINIMAX_CREATE_URL:-$BASE_URL/videos}"
    STATUS_BASE="${MINIMAX_STATUS_BASE:-$BASE_URL/videos}"
    MODEL="${VIDEO_MODEL:-${MINIMAX_MODEL_ID:-Minimax-H3-768p-933-15s}}"
    # compat 的 images 需为上游可取用的 URL 或 data-URL；本地相对/绝对路径在此就地转 base64 data-URL。
    # 已是 http(s):// 或 data: 的原样放行（其他用 URL 的项目行为不变）。
    IMAGES_FILE="$MINIMAX_TEMP_DIR/images.json"
    printf '%s' "$REFERENCES" > "$IMAGES_FILE"
    while IFS=$'\t' read -r IMG_INDEX IMG_PATH; do
      [[ -n "$IMG_PATH" ]] || continue
      case "$IMG_PATH" in
        http://*|https://*|data:*) continue ;;
      esac
      IMG_LOCAL="$IMG_PATH"; [[ "$IMG_LOCAL" == /* ]] || IMG_LOCAL="$PROJECT_DIR/$IMG_LOCAL"
      [[ -f "$IMG_LOCAL" ]] || die "找不到本地 MiniMax 素材: $IMG_LOCAL"
      case "${IMG_LOCAL##*.}" in
        jpg|JPG|jpeg|JPEG) IMG_MIME="image/jpeg" ;;
        webp|WEBP) IMG_MIME="image/webp" ;;
        *) IMG_MIME="image/png" ;;
      esac
      IMG_DU="$MINIMAX_TEMP_DIR/img-du-$IMG_INDEX.txt"
      { printf 'data:%s;base64,' "$IMG_MIME"; base64 < "$IMG_LOCAL" | tr -d '\n'; } > "$IMG_DU"
      IMG_NEXT="$MINIMAX_TEMP_DIR/images-next.json"
      jq --argjson i "$IMG_INDEX" --rawfile du "$IMG_DU" '.[$i]=$du' "$IMAGES_FILE" > "$IMG_NEXT"
      mv "$IMG_NEXT" "$IMAGES_FILE"
    done < <(jq -r 'to_entries[] | [.key, .value] | @tsv' "$IMAGES_FILE")
    # images 可能是数 MB 的 base64 data-URL，必须用 --slurpfile 从文件读，
    # 不能 --argjson 走命令行参数（会 Argument list too long）。
    jq -n --arg model "$MODEL" --arg prompt "$PROMPT" --slurpfile images "$IMAGES_FILE" \
      --arg ratio "$RATIO" --arg duration "$DURATION" \
      '{model:$model,prompt:$prompt,images:$images[0],aspect_ratio:$ratio} + (if $duration != "" then {duration:($duration|tonumber)} else {} end)' > "$REQUEST"
  else
    die "H3_API_MODE 只能是 v2 或 compat"
  fi

  if ! curl --fail-with-body -sS -X POST "$CREATE_URL" \
    -H 'Content-Type: application/json; charset=utf-8' -H 'Accept: application/json' \
    -H "Authorization: Bearer $API_KEY" --data-binary "@$REQUEST" > "$OUTPUT"; then
    echo "MiniMax 创建任务失败，服务端响应：" >&2
    jq . "$OUTPUT" >&2 2>/dev/null || sed -n '1,120p' "$OUTPUT" >&2
    exit 1
  fi
  echo "MiniMax 视频任务响应已保存: $OUTPUT"

  # 付费创建门禁（不可绕过）：MiniMax 以 HTTP 200 + RetCode 业务码返回错误
  # （如 226638 积分不足），curl --fail-with-body 不会失败，旧逻辑会静默落到
  # "没有 task_id" 的泛化报错，导致批量继续空跑、看不出真因。此处显式拦截。
  MM_RETCODE="$(jq -r '.RetCode // .base_resp.status_code // empty' "$OUTPUT" 2>/dev/null || true)"
  if [[ -n "$MM_RETCODE" && "$MM_RETCODE" != "0" ]]; then
    MM_MSG="$(jq -r '.Message // .base_resp.status_msg // "unknown"' "$OUTPUT" 2>/dev/null || echo unknown)"
    echo "MiniMax 创建被拒: RetCode=$MM_RETCODE ($MM_MSG)" >&2
    if [[ "$MM_RETCODE" == "226638" ]]; then
      echo "→ 积分不足：请先给账户充值。批量必须立即停止，勿重试(重试仍会被拒且白跑流程)。" >&2
    fi
    exit 3
  fi

  extract_minimax_url() {
    jq -r '.metadata.url // .data.url // .data.video_url // .video_url // .content.url // .task.content.url // .data.content.url // empty' "$1"
  }
  VIDEO_URL="$(extract_minimax_url "$OUTPUT")"
  if [[ "$WAIT" == true && -z "$VIDEO_URL" ]]; then
    TASK_ID="$(jq -r '.id // .task_id // .data.id // .data.task_id // empty' "$OUTPUT")"
    [[ -n "$TASK_ID" ]] || die "创建响应中没有 task_id，也没有可下载的视频 URL"
    STATUS_FILE="$OUTPUT.status.json"
    while true; do
      curl --fail-with-body -sS "$STATUS_BASE/$TASK_ID" \
        -H 'Accept: application/json' -H "Authorization: Bearer $API_KEY" > "$STATUS_FILE"
      STATUS="$(jq -r '.status // .data.status // .task.status // empty' "$STATUS_FILE" | tr '[:upper:]' '[:lower:]')"
      echo "任务 $TASK_ID 状态: ${STATUS:-unknown}"
      case "$STATUS" in
        completed|success|succeeded) VIDEO_URL="$(extract_minimax_url "$STATUS_FILE")"; break ;;
        failed|cancelled|canceled|error) jq . "$STATUS_FILE" >&2; die "视频任务失败: $STATUS" ;;
      esac
      sleep "${MINIMAX_POLL_SECONDS:-10}"
    done
    echo "最终任务响应已保存: $STATUS_FILE"
  fi
  if [[ "$DOWNLOAD" == true ]]; then
    [[ -n "$VIDEO_URL" ]] || die "完成响应中没有找到视频 URL"
    VIDEO_OUTPUT="$OUTPUT_DIR/${OUTPUT_NAME%.json}.mp4"
    curl --fail-with-body -sS -L "$VIDEO_URL" -o "$VIDEO_OUTPUT"
    [[ -s "$VIDEO_OUTPUT" ]] || die "视频下载失败或文件为空: $VIDEO_OUTPUT"
    echo "视频已下载: $VIDEO_OUTPUT"
  fi
else
  echo "不支持的 provider: $PROVIDER" >&2; exit 2
fi
