#!/usr/bin/env bash
# toggle-dms-bar.sh — show/hide the DMS bar (Dank Island OR DankBar).
#
# Your DMS runs in Dank Island mode (dankIslandBarId="default" in
# settings.json), and DMS's `bar hide/toggle` IPC refuses island bars
# (BAR_IS_ISLAND). The island's master switch is the bar config's
# "enabled" field (SettingsData.dankIslandEnabled), so this script flips
# that field directly in settings.json and pokes DMS to reload.
#
# If you ever switch back to a regular DankBar (dankIslandBarId=""),
# this script still works — "enabled" hides/shows normal bars too.
set -u
S="$HOME/.config/DankMaterialShell/settings.json"

python3 - "$S" <<'PY'
import json, sys
p = sys.argv[1]
d = json.load(open(p))
bars = d.get("barConfigs", [])
if not bars:
    print("no bar configs"); sys.exit(1)
bar = bars[0]
bar["enabled"] = not bar.get("enabled", True)
json.dump(d, open(p, "w"), indent=2)
print("island/bar enabled =", bar["enabled"])
PY

# Nudge DMS to pick up the settings change (it also watches the file;
# this just makes it immediate):
dms ipc call settings dump >/dev/null 2>&1 || true
