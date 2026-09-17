#!/usr/bin/env bash
# =============================================================================
# stage1-screenplay.sh — 剧本 stage（内容层，无付费）
#   由 run.sh 调用，契约见 run.sh 顶部注释。
#   phase run     : route_confirmed  -> screenplay_pending   （暂停，派 screenwriting-master）
#   phase gate-out: screenplay_pending -> screenplay_confirmed（校验剧本文件 + 确认标记 + sha256）
# =============================================================================
set -Eeuo pipefail
phase="${1:-}"; project_dir="${2:-}"; sub="${3:-}"; desc="${4:-}"; cur="${5:-}"
[[ -n "$phase" && -d "$project_dir" && -f "$desc" ]] || { echo "stage1 bad args" >&2; exit 1; }
emit_reject(){ jq -cn --argjson c "$1" --arg r "$2" '{decision:"reject",code:$c,reason:$r}'; exit 0; }

sp_rel="$(jq -r '.screenplay // ("story/"+.subproject_id+"-screenplay.md")' "$desc")"
sp_path="$project_dir/$sp_rel"

case "$phase" in
  run)
    [[ "$cur" == route_confirmed ]] || emit_reject 10 "stage1 run 需当前状态 route_confirmed（当前 $cur）"
    jq -cn --arg sp "$sp_rel" \
      '{decision:"pause",from:"route_confirmed",to:"screenplay_pending",gate:"stage1:run",evidence:[],
        instructions:("派隔离子 agent 调 screenwriting-master，按阶段纪律复核/修改用户原稿，产出确认版剧本到："+$sp+"\n剧本须含确认标记行（例：状态：screenplay_confirmed）。产出并经用户确认后，调 run.sh <dir> stage1-screenplay --sub <sub> --phase gate-out")}'
    ;;
  gate-out)
    [[ "$cur" == screenplay_pending ]] || emit_reject 10 "stage1 gate-out 需当前状态 screenplay_pending（当前 $cur）；请先跑 --phase run"
    [[ -f "$sp_path" ]] || emit_reject 12 "剧本文件缺失：$sp_rel"
    [[ -s "$sp_path" ]] || emit_reject 12 "剧本文件为空：$sp_rel"
    grep -q "screenplay_confirmed" "$sp_path" || emit_reject 12 "剧本缺确认标记 screenplay_confirmed：$sp_rel（须用户确认后由 screenwriting-master 回写）"
    hash="$(sha256sum "$sp_path" | awk '{print $1}')"
    jq -cn --arg sp "$sp_rel" --arg h "$hash" \
      '{decision:"advance",from:"screenplay_pending",to:"screenplay_confirmed",gate:"stage1:gate-out",
        note:"剧本文件存在+确认标记+sha256 入账",
        evidence:[{kind:"file_exists",path:$sp},{kind:"marker",token:"screenplay_confirmed"},{kind:"sha256",path:$sp,hash:$h}]}'
    ;;
  *) echo "stage1: unknown phase $phase" >&2; exit 1 ;;
esac
