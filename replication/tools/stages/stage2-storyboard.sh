#!/usr/bin/env bash
# =============================================================================
# stage2-storyboard.sh — 分镜/对白/音效/提示词 stage（内容层，无付费）
#   phase run     : screenplay_confirmed  -> production_plan_pending（暂停，派分镜子 agent）
#   phase gate-out: production_plan_pending -> storyboard_confirmed
#     收编 scripts/validate-production-plan.mjs（三元组绑定 / verbatim 子串 / 秒数守恒 /
#     每节拍×通道恰好认领一次 / 路径沙箱），exit0 才放行；plan sha256 入账。
# =============================================================================
set -Eeuo pipefail
phase="${1:-}"; project_dir="${2:-}"; sub="${3:-}"; desc="${4:-}"; cur="${5:-}"
[[ -n "$phase" && -d "$project_dir" && -f "$desc" ]] || { echo "stage2 bad args" >&2; exit 1; }
REPO_ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"
emit_reject(){ jq -cn --argjson c "$1" --arg r "$2" '{decision:"reject",code:$c,reason:$r}'; exit 0; }

plan_rel="$(jq -r '.production_plan // ("contracts/"+.subproject_id+"-production-plan.json")' "$desc")"
plan_path="$project_dir/$plan_rel"

case "$phase" in
  run)
    [[ "$cur" == screenplay_confirmed ]] || emit_reject 10 "stage2 run 需当前状态 screenplay_confirmed（当前 $cur）"
    jq -cn --arg p "$plan_rel" \
      '{decision:"pause",from:"screenplay_confirmed",to:"production_plan_pending",gate:"stage2:run",evidence:[],
        instructions:("派隔离子 agent 担当 ad-creative-expert 做分镜填空（§8 节拍覆盖 / §9 A-G+H1-H4），并派模型技能（h3-prompt-writing）写各镜提示词过 H3 校验器。锁定物含："+$p+" + shots/<sub>-*/contract.md + review。\n完成后调 run.sh <dir> stage2-storyboard --sub <sub> --phase gate-out（内部收编 validate-production-plan.mjs）")}'
    ;;
  gate-out)
    [[ "$cur" == production_plan_pending ]] || emit_reject 10 "stage2 gate-out 需当前状态 production_plan_pending（当前 $cur）；请先跑 --phase run"
    [[ -f "$plan_path" ]] || emit_reject 12 "production-plan 缺失：$plan_rel"
    # 收编 validate-production-plan.mjs
    set +e
    vout="$(node "$REPO_ROOT/scripts/validate-production-plan.mjs" "$plan_path" --project-root "$project_dir" 2>&1)"
    vrc=$?
    set -e
    if [[ $vrc -ne 0 ]]; then
      emit_reject 12 "validate-production-plan.mjs 未过（exit $vrc）：$(echo "$vout" | tr '\n' '｜' | head -c 400)"
    fi
    hash="$(sha256sum "$plan_path" | awk '{print $1}')"
    jq -cn --arg p "$plan_rel" --arg h "$hash" --arg vo "$(echo "$vout" | head -c 200)" \
      '{decision:"advance",from:"production_plan_pending",to:"storyboard_confirmed",gate:"stage2:gate-out",
        note:("validate-production-plan.mjs pass: "+$vo),
        evidence:[{kind:"validate_exit",ref:"scripts/validate-production-plan.mjs",code:0},
                  {kind:"sha256",path:$p,hash:$h}]}'
    ;;
  *) echo "stage2: unknown phase $phase" >&2; exit 1 ;;
esac
