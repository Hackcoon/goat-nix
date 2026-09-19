#!/usr/bin/env bash
# cycle-tag.sh — SUPER+Tab / SUPER+SHIFT+Tab workspace cycling for mango.
#
# WHY THIS EXISTS: mango's built-in viewtoright/viewtoleft silently no-op
# when a multi-tag view (toggleview via the DMS bar's right-click pill) or
# the overview is active (view_shift_tag: curtag==0 guard). This script
# computes the next/previous single tag directly over IPC, so cycling works
# from ANY view state, wraps 9<->1, and skips nothing.
#
# Usage: cycle-tag.sh [next|prev]
set -u
DIR="${1:-next}"

# Focused monitor's tag list; the first active tag = current position.
TAG_JSON=$(mmsg get all-monitors 2>/dev/null)
[ -z "$TAG_JSON" ] && exit 1

# Focused monitor ("active":true) is the only match for that quoted
# pattern — tags use "is_active" — so this cut lands at the focused
# monitor even in a multi-monitor setup.
CUR=$(echo "$TAG_JSON" \
    | sed 's/.*"active":true//' \
    | grep -oE '"index":[0-9]+,"is_active":true' | head -1 | grep -oE '[0-9]+')
[ -z "$CUR" ] && exit 1

if [ "$DIR" = "prev" ]; then
    NEXT=$(( CUR - 1 )); [ "$NEXT" -lt 1 ] && NEXT=9
else
    NEXT=$(( CUR + 1 )); [ "$NEXT" -gt 9 ] && NEXT=1
fi

mmsg dispatch "view,$NEXT" >/dev/null 2>&1
