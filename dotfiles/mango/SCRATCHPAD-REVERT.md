# Scratchpad: Hyprland parity status (mango 0.16.2)

## Verdict: exact Hyprland behavior is NOT possible on 0.16.2

V0.16.2 (27 Aug, latest release — this machine runs it) has no special
workspace (Tag 0). The dispatchers from the docs site
(`toggle_special_tag`, `tag_special_tag`, `tag_special_silent`) only
exist on dev main. Attempting them fails validation:

```
[ERROR]: Unknown dispatch in bind: toggle_special_tag
```

Proof from the installed binary: it contains `toggle_scratchpad`,
`minimized`, `restore_minimized`, `toggle_named_scratchpad` — and no
`special_tag` dispatcher. The attempt was reverted; `mango -p` is clean.

## Current (closest available) setup — already in `config.conf`

- `SUPER+u` → `toggle_scratchpad` (show/hide pool)
- `SUPER+SHIFT+u` → `minimized` (send focused window to pool)
- `SUPER+CTRL+u` → `restore_minimized` (bring one back)
- `SUPER+A` → `toggle_named_scratchpad` kitty dropdown 1280x800
  (Dropterminal replacement; spawns if not running)

Pool semantics differ from Hyprland special: windows hide one at a
time and `toggle_scratchpad` cycles them, instead of showing all
special windows together as an overlay.

## Upgrade path (when a newer mango lands)

1. Re-apply the Tag 0 binds:
   `SUPER,u,toggle_special_tag`, `SUPER+SHIFT,u,tag_special_tag`,
   `SUPER+CTRL,u,tag_special_silent`
2. Validate with `mango -p -c ~/.config/mango/config.conf` — apply
   only if exit 0 with no `Unknown dispatch` errors.
3. Optional tuning then available: `special_dim=`,
   `special_gappih/v/oh/ov=`, `windowrule=tags:0,...` auto-place.
