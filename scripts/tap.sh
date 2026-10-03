#!/usr/bin/env bash
# Tap a UI node by its .id() or exact text, using `oniro-app dump` (normalized bounds "b").
# Usage: scripts/tap.sh <id-or-text>
set -euo pipefail
find_node() {
oniro-app dump 2>/dev/null | python3 -c "
import json,sys
key=sys.argv[1]
d=json.load(sys.stdin)
W,H=d['display']['width'],d['display']['height']
hit=[]
def walk(n):
    if isinstance(n,dict):
        if not hit and (n.get('id')==key or n.get('text')==key) and 'b' in n: hit.append(n['b'])
        for v in n.values(): walk(v)
    elif isinstance(n,list):
        for v in n: walk(v)
walk(d['tree'])
if not hit: sys.exit('not found: '+key)
b=hit[0]
print(int((b[0]+b[2])/2*W), int((b[1]+b[3])/2*H))
" "$1"
}
# Retry: the UI may still be starting or animating.
for i in 1 2 3 4 5; do
  if POS=$(find_node "$1" 2>/dev/null); then break; fi
  POS=""; sleep 1
done
[ -n "$POS" ] || { echo "not found: $1" >&2; exit 1; }
read -r X Y <<< "$POS"
oniro-app input --type click --x "$X" --y "$Y" >/dev/null
echo "tapped $1 at $X,$Y"
