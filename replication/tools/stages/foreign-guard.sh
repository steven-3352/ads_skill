#!/usr/bin/env bash
# =============================================================================
# foreign-guard.sh — 他片零改动 gate（同目录多子片共存刚需）
#
#   一个项目目录里可能寄居多条子片（如 xiaozhu-qichuang-20260914/ 同时住着
#   《小猪起床了》和 fenshou《我们还是分手吧》）。付费 stage 跑本子片时，绝不能误
#   改 / 覆盖 / 删除他片的可交付文件。本脚本按描述符 owner_globs 划出"我的文件"，
#   对项目目录里其余可交付文件做 sha256 基线，stage 前后比对，任何非 owner 文件
#   增 / 改 / 删即 exit 13，并报污染清单。
#
#   用法：
#     foreign-guard.sh baseline <project-dir> <descriptor>   # stage 前：快照
#     foreign-guard.sh check    <project-dir> <descriptor>   # stage 后：比对，污染 exit 13
#
#   排除（易变簿记 / 非交付物，不纳入基线）：.git、automation/（账本与 orchestrator
#   工作区，本身就该变）、requests/、manifest.json、*.lock、.state.* 临时文件、
#   node_modules。基线文件写在 automation/<sub>.foreign-baseline.json。
# =============================================================================
set -Eeuo pipefail

mode="${1:-}"; project_dir="${2:-}"; descriptor="${3:-}"
[[ -n "$mode" && -d "$project_dir" && -f "$descriptor" ]] || {
  echo "usage: foreign-guard.sh <baseline|check> <project-dir> <descriptor>" >&2; exit 2; }
command -v jq >/dev/null || { echo "jq required" >&2; exit 2; }
project_dir="$(cd "$project_dir" && pwd)"
sub="$(jq -r '.subproject_id' "$descriptor")"
baseline="$project_dir/automation/$sub.foreign-baseline.json"

FG_MODE="$mode" FG_DIR="$project_dir" FG_DESC="$descriptor" FG_BASELINE="$baseline" \
python3 - <<'PY'
import os, sys, json, hashlib, re, fnmatch

mode     = os.environ["FG_MODE"]
root     = os.environ["FG_DIR"]
desc     = json.load(open(os.environ["FG_DESC"], encoding="utf-8"))
baseline = os.environ["FG_BASELINE"]
owner_globs = desc.get("owner_globs", [])

EXCLUDE_DIRS   = {".git", "node_modules"}
# 相对项目目录、按前缀/模式排除的易变簿记
EXCLUDE_PREFIX = ("automation/",)
EXCLUDE_PARTS  = {"requests"}
EXCLUDE_NAMES  = {"manifest.json"}

def glob_to_re(g):
    # 支持 ** = 任意层级，* = 段内任意，? = 单字符
    out, i, n = [], 0, len(g)
    while i < n:
        c = g[i]
        if g[i:i+2] == "**":
            out.append(".*"); i += 2
            if i < n and g[i] == "/": i += 1
            continue
        if c == "*": out.append("[^/]*")
        elif c == "?": out.append("[^/]")
        else: out.append(re.escape(c))
        i += 1
    return re.compile("^" + "".join(out) + "$")

owner_res = [glob_to_re(g) for g in owner_globs]

def is_owner(rel):
    return any(r.match(rel) for r in owner_res)

def excluded(rel):
    if rel.startswith(EXCLUDE_PREFIX): return True
    parts = rel.split("/")
    if EXCLUDE_DIRS & set(parts): return True
    if EXCLUDE_PARTS & set(parts): return True
    if parts[-1] in EXCLUDE_NAMES: return True
    if parts[-1].endswith(".lock") or parts[-1].startswith(".state.") or parts[-1].startswith(".manifest."): return True
    return False

def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 20), b""):
            h.update(chunk)
    return h.hexdigest()

def snapshot():
    m = {}
    for dp, dns, fns in os.walk(root):
        dns[:] = [d for d in dns if d not in EXCLUDE_DIRS]
        for fn in fns:
            full = os.path.join(dp, fn)
            if os.path.islink(full): continue
            rel = os.path.relpath(full, root)
            if excluded(rel) or is_owner(rel): continue
            try:
                m[rel] = sha256(full)
            except OSError:
                pass
    return m

cur = snapshot()

if mode == "baseline":
    os.makedirs(os.path.dirname(baseline), exist_ok=True)
    json.dump({"subproject_id": desc["subproject_id"], "count": len(cur), "files": cur},
              open(baseline, "w", encoding="utf-8"), ensure_ascii=False, indent=2, sort_keys=True)
    print(f"foreign-guard: baseline snapshot of {len(cur)} non-owner files -> {baseline}")
    sys.exit(0)

# mode == check
if not os.path.exists(baseline):
    print(f"foreign-guard: no baseline at {baseline}; run 'baseline' before the paid stage", file=sys.stderr)
    sys.exit(2)
base = json.load(open(baseline, encoding="utf-8")).get("files", {})
added    = sorted(set(cur) - set(base))
deleted  = sorted(set(base) - set(cur))
modified = sorted(f for f in (set(cur) & set(base)) if cur[f] != base[f])
if added or deleted or modified:
    print("foreign-guard: FOREIGN FILES CHANGED — 他片被污染，拒绝推进：", file=sys.stderr)
    for f in modified: print(f"  [modified] {f}", file=sys.stderr)
    for f in added:    print(f"  [added]    {f}", file=sys.stderr)
    for f in deleted:  print(f"  [deleted]  {f}", file=sys.stderr)
    sys.exit(13)
print(f"foreign-guard: OK — {len(cur)} non-owner files unchanged")
sys.exit(0)
PY
rc=$?

# git 兜底：过滤掉 owner 命中项后仍有非 owner 改动即失败
if [[ "$mode" == "check" && $rc -eq 0 ]]; then
  if command -v git >/dev/null && git -C "$project_dir" rev-parse --git-dir >/dev/null 2>&1; then
    dirty="$(cd "$project_dir" && git status --porcelain -- . 2>/dev/null || true)"
    if [[ -n "$dirty" ]]; then
      prefix="$(cd "$project_dir" && git rev-parse --show-prefix 2>/dev/null)"
      leak="$(FG_DESC="$descriptor" FG_PREFIX="$prefix" python3 - <<'PY'
import os, json, re, sys
desc = json.load(open(os.environ["FG_DESC"], encoding="utf-8"))
prefix = os.environ.get("FG_PREFIX", "")
def glob_to_re(g):
    out, i, n = [], 0, len(g)
    while i < n:
        if g[i:i+2] == "**":
            out.append(".*"); i += 2
            if i < n and g[i] == "/": i += 1
            continue
        c = g[i]
        out.append("[^/]*" if c == "*" else "[^/]" if c == "?" else re.escape(c)); i += 1
    return re.compile("^" + "".join(out) + "$")
res = [glob_to_re(g) for g in desc.get("owner_globs", [])]
leak = []
for line in sys.stdin:
    line = line.rstrip("\n")
    if not line: continue
    path = line[3:]                     # 去掉 XY 状态两列 + 空格
    path = path.split(" -> ")[-1]       # 处理 rename
    rel = path[len(prefix):] if prefix and path.startswith(prefix) else path
    if rel.startswith("automation/"): continue
    if any(r.match(rel) for r in res): continue
    leak.append(rel)
if leak:
    print("\n".join(leak))
PY
<<<"$dirty")"
      if [[ -n "$leak" ]]; then
        echo "foreign-guard: git 兜底发现非 owner 改动（他片受保护）：" >&2
        echo "$leak" | sed 's/^/  /' >&2
        exit 13
      fi
    fi
  fi
fi
exit $rc
