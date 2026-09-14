#!/usr/bin/env bash
# freesound 抗抖动版:每条查询各自重试,直到拿到 HTTP200 且 body 是合法 JSON;否则退避重试。
set -uo pipefail
set -a && source /home/ubuntu/ads_skill/.env && set +a
OUT=/home/ubuntu/ads_skill/replication/output/xiaozhu-qichuang-20260914/assets/sfx
mkdir -p "$OUT"
TOK="${FREESOUND_API_KEY}"
API="https://freesound.org/apiv2"

get_json () { # $1=query  → stdout 合法JSON;最多重试40次*每次30s
  local q="$1" tmp code first
  for a in $(seq 1 40); do
    tmp=$(mktemp)
    code=$(curl -s -G -o "$tmp" -w "%{http_code}" -H "Authorization: Token $TOK" "$API/search/text/" \
      --data-urlencode "query=$q" \
      --data-urlencode "fields=id,name,duration,license,previews" \
      --data-urlencode "sort=score" --data-urlencode "page_size=5")
    first=$(head -c 1 "$tmp")
    if [ "$code" = "200" ] && [ "$first" = "{" ]; then cat "$tmp"; rm -f "$tmp"; return 0; fi
    rm -f "$tmp"; echo "   [retry $a] «$q» HTTP=$code first='$first'" >&2; sleep 30
  done
  return 1
}

fetch () { # $1=slug $2=query $3=min $4=max(秒)
  local slug="$1" q="$2" mn="$3" mx="$4" json
  echo "=== $slug : $q ==="
  json=$(get_json "$q") || { echo "  ✗ 放弃 $slug (freesound 持续不可用)"; return; }
  echo "$json" | OUT="$OUT" SLUG="$slug" TOK="$TOK" MN="$mn" MX="$mx" python3 - <<'PY'
import sys, os, json, urllib.request
data = json.load(sys.stdin)
out, slug, tok = os.environ['OUT'], os.environ['SLUG'], os.environ['TOK']
mn, mx = float(os.environ['MN']), float(os.environ['MX'])
n = 0
for r in data.get('results', []):
    d = r.get('duration', 0)
    if d < mn or d > mx: continue
    url = r.get('previews', {}).get('preview-hq-mp3')
    if not url: continue
    n += 1
    dst = f"{out}/{slug}-{n}-id{r['id']}.mp3"
    req = urllib.request.Request(url, headers={'Authorization': f'Token {tok}'})
    try:
        with urllib.request.urlopen(req, timeout=40) as resp, open(dst, 'wb') as f:
            f.write(resp.read())
        print(f"  ✓ {os.path.basename(dst)}  [{d:.1f}s]  {r['license'].rsplit('/',2)[-2] if '/' in r['license'] else r['license']}  «{r['name'][:44]}»")
    except Exception as e:
        print(f"  ✗ id{r['id']}: {e}"); n -= 1
    if n >= 3: break
if n == 0: print("  (无符合时长的结果)")
PY
}

fetch clock-tick   "clock ticking"            6  30
fetch water-drip   "water drip slow"          2  20
fetch tableware    "chopsticks bowl"          0.2 5
fetch room-morning "room tone quiet ambience" 8  40
fetch blanket      "cloth rustle blanket"     0.4 6

echo "=== 完成 ==="; ls -la "$OUT"
