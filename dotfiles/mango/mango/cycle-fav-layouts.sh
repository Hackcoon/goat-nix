#!/usr/bin/env bash
# cycle-fav-layouts.sh — SUPER+A cycles tile -> scroller -> monocle -> dwindle.
#
# SUPER+L (switch_layout over circle_layout, all 14) is untouched; this is
# the short rotation for the famous four. Stateless: reads the focused
# monitor's current layout symbol over mmsg, maps it to a name, and
# dispatches setlayout for the next one. If you're on some other layout,
# it jumps to tile.
set -u
FAVS="tile scroller monocle dwindle"

NEXT=$(mmsg get all-monitors 2>/dev/null | python3 -c "
import json, sys
favs = 'tile scroller monocle dwindle'.split()
mon = json.load(sys.stdin)['monitors']
sym = next(m['layout_symbol'] for m in mon if m.get('active'))
names = {'T': 'tile', 'S': 'scroller', 'M': 'monocle', 'DW': 'dwindle'}
cur = names.get(sym, '')
i = favs.index(cur) if cur in favs else -1
print(favs[(i + 1) % len(favs)])
")
[ -z "$NEXT" ] && exit 1

mmsg dispatch "setlayout,$NEXT" >/dev/null 2>&1
