# Hyprland → MangoWC + DMS Keybind Port Report

Ported from `~/.config/hypr/binds.lua` (JaKooLit-style Lua binds) to
`~/.config/mango/config.conf` (mango `bind=` syntax). Media/function keys
were **excluded from this port** per your request.

Mango hot-reloads its config — everything below is already live.

---

## Legend

- ✅ **Ported** — exact or near-exact equivalent
- 🔀 **Ported, remapped** — works, but the original chord collided with a DMS bind (or another port), so it lives on a different key
- 🔄 **Ported, semantics differ** — mango's closest dispatcher; behavior isn't 1:1
- ❌ **Not ported** — no mango equivalent, or Hyprland-specific
- ⏭️ **Skipped** — media/function keys (per your request) or duplicates

---

## STANDARD

| Chord | Hyprland action | Status | Mango bind |
|---|---|---|---|
| `SUPER+D` | vicinae launcher | 🔀 | `SUPER+d` → vicinae toggle. DMS already owns `SUPER+space` (spotlight); vicinae keeps its own key |
| `SUPER+B` | default browser | ✅ | `xdg-open https://` |
| `SUPER+Return` | kitty | ✅ | `kitty` |
| `SUPER+E` | thunar | ✅ | `thunar` |

## FEATURES / EXTRAS

| Chord | Hyprland action | Status | Mango bind |
|---|---|---|---|
| `SUPER+SHIFT+F` | fullscreen | ✅ | `togglefullscreen` |
| `SUPER+CTRL+F` | maximize (fs 1) | ✅ | `togglemaximizescreen` (keeps bar/border, closest to Hyprland maximize) |
| `SUPER+SPACE` | float current | 🔀 | `SUPER+CTRL+space` → `togglefloating`. SUPER+SPACE stays DMS spotlight |
| `SUPER+ALT+SPACE` | float ALL | ✅ | `toggle_all_floating` |

## SYSTEM

| Chord | Hyprland action | Status | Mango bind |
|---|---|---|---|
| `SUPER+Q` | killactive | ✅ | `killclient` |
| `SUPER+SHIFT+Q` | force-terminate (KillActiveProcess.sh) | 🔄 | `killclient force` (SIGKILL). Script used `hyprctl activewindow` — replaced by mango's built-in force flag |
| `CTRL+ALT+P` | fury-bar power menu | ✅ | same quickshell ipc command |
| `SUPER+SHIFT+N` | fury-bar notif panel | ✅ | same quickshell ipc command |
| `SUPER+SHIFT+E` | Kool_Quick_Settings.sh | ❌ | Rofi menu reading Hyprland config files — deep-Hyprland-specific, see below |
| `SUPER+SHIFT+Q` note | — | — | see above |

## MASTER LAYOUT

| Chord | Hyprland action | Status | Mango bind |
|---|---|---|---|
| `SUPER+CTRL+D` | removemaster | ✅ | `incnmaster,-1` |
| `SUPER+I` | addmaster | ✅ | `incnmaster,+1` |
| `SUPER+CTRL+Return` | swapwithmaster | ✅ | `zoom` (mango's name for swap-focused-with-master) |

Mango note: `SUPER+i` in mango's shipped default config was `minimized`;
your port now owns that chord (user config supersedes defaults — mango only
reads YOUR config, the default file is just reference material).

## DWINDLE LAYOUT

| Chord | Hyprland action | Status | Mango bind |
|---|---|---|---|
| `SUPER+SHIFT+I` | togglesplit | ✅ | `dwindle_toggle_current_split` |
| `SUPER+P` | pseudo | ❌ | Hyprland pseudo-tiling has no mango equivalent |
| `SUPER+M` | splitratio 0.3 | ❌ | Mango sets split ratio via config only (`dwindle_split_ratio=`), no runtime dispatcher |

## GROUP (tabbed windows)

Mango groups are dwl/dwl-groups style: directional join/leave instead of
Hyprland's toggle+move-into. Cycled members with arrows, not Tab (Tab was
needed for tags — see below).

| Chord | Hyprland action | Status | Mango bind |
|---|---|---|---|
| `SUPER+G` | togglegroup | 🔄 | `groupjoin,right` — pulls the right-hand neighbor in as a group |
| `SUPER+Tab` | changegroupactive f | ⏭️ | **Conflict resolved in favor of workspace cycling** — in your Hyprland set, SUPER+Tab was double-booked and the workspace won (see WORKSPACES). Group cycle moved to `SUPER+CTRL+Tab` → `groupfocus,next` |
| `SUPER+CTRL+Tab` | group.active index 1 | 🔄 | `SUPER+CTRL+Tab` → `groupfocus,next` (cycle; mango has no jump-to-index) |
| `SUPER+SHIFT+Tab` | changegroupactive b | 🔀 | `SUPER+CTRL+SHIFT+Tab` → `groupfocus,prev` |
| `SUPER+CTRL+K` | moveintogroup l | ✅ | `groupjoin,left` |
| `SUPER+CTRL+L` | moveintogroup r | ✅ | `groupjoin,right` |
| `SUPER+CTRL+H` | moveoutofgroup | ✅ | `groupleave` |

## WINDOW CYCLING

| Chord | Hyprland action | Status | Mango bind |
|---|---|---|---|
| `ALT+Tab` | (function) | ✅ | `switcher,next` — mango's thumbnail switcher; releasing the modifier selects the highlighted window |

## RESIZE / MOVE / SWAP / FOCUS

Mango splits these by window state: `exchange_client` swaps **tiling**
windows, `smartmovewin`/`movewin` move **floating** ones. Your Hyprland
chords mapped cleanly onto that split:

| Chord | Hyprland action | Status | Mango bind |
|---|---|---|---|
| `SUPER+left/right/up/down` | focus dir | ✅ | `focusdir,...` |
| `SUPER+CTRL+arrows` | movewindow (tiling) | ✅ | `exchange_client,...` (swap with neighbor = tiling move) |
| `SUPER+ALT+arrows` | movewindow (floating) | ✅ | `smartmovewin,...` (moves by snap distance) |
| `SUPER+SHIFT+arrows` | resize 50px | ✅ | `resizewin,±50,±0` |

## WORKSPACES → TAGS

Mango uses dwl-style tags (bitmask), not Hyprland workspaces. Your
numbered/monitor-relative (`m+1` etc.) binds all map:

| Chord | Hyprland action | Status | Mango bind |
|---|---|---|---|
| `SUPER+Tab` | workspace m+1 | ✅ | `viewtoright` — the double-booked Tab chord resolved as workspace, group cycle moved to `SUPER+CTRL+Tab` |
| `SUPER+SHIFT+Tab` | workspace m-1 | ✅ | `viewtoleft` |
| `SUPER+U` | togglespecialworkspace | ✅ | `toggle_special_tag` (mango's tiling scratchpad overlay) |
| `SUPER+SHIFT+U` | movetoworkspace special | ✅ | `tag_special_tag` |
| `SUPER+<1..9>` | focus workspace N | ✅ | `view,N,0` |
| `SUPER+SHIFT+<1..9>` | move window + follow | ✅ | `tag,N,0` (moves + focuses — mango focuses after tag) |
| `SUPER+CTRL+<1..9>` | move window, silent | ✅ | `tagsilent,N` |
| `SUPER+SHIFT+[ / ]` | movetoworkspace prev / m+1 | ✅ | `tagtoleft,0` / `tagtoright,0` |
| `SUPER+period` | workspace e+1 | ✅ | `viewtoright` |
| `SUPER+comma` | workspace e-1 | ❌ | **Collides with DMS settings** (SUPER+comma opens DMS Settings per DMS docs). e-1 remains reachable via `SUPER+SHIFT+Tab` or wheel |
| `SUPER+mouse_down/up` | workspace e±1 | ✅ | `axisbind=SUPER,UP/DOWN` → viewtoleft/viewtoright |
| `SUPER+<0>` / `SUPER+10` | workspace 10 | ❌ | Mango is 9-tag (`tag_num=9`); no 10th tag |

## MOUSE (move/resize by drag)

| Chord | Hyprland action | Status | Mango bind |
|---|---|---|---|
| `SUPER+mouse:272` (LMB) | window drag-move | ✅ | `mousebind=SUPER,btn_left,moveresize,curmove` |
| `SUPER+mouse:273` (RMB) | window drag-resize | ✅ | `mousebind=SUPER,btn_right,moveresize,curresize` |

## LAYOUTS — your scrollable-master cycling idea

Mango has **14 layouts** — all cycle on one key:

> `tile, scroller, monocle, grid, deck, center_tile, vertical_tile,
> right_tile, vertical_scroller, vertical_grid, vertical_deck, dwindle,
> fair, vertical_fair`

```ini
circle_layout=tile,scroller,monocle,grid,deck,center_tile,vertical_tile,right_tile,vertical_scroller,vertical_grid,vertical_deck,dwindle,fair,vertical_fair
bind=SUPER,l,switch_layout
```

`SUPER+L` now walks the full list, per-tag (each tag remembers its own
layout — layout switching in mango is per-tag, not global like Hyprland).

## MEDIA / FUNCTION KEYS

⏭️ **Not ported (your request).** DMS binds for volume/brightness already
exist in config.conf (`dms ipc call audio ...` / `brightness ...`).

Note: your `Volume.sh`/`MediaCtrl.sh` wrap pamixer/playerctl with swaync
notifications — under mango+DMS the DMS audio widget is the intended
replacement, so the DMS ipc binds are the more native choice if you ever
port these.

## Scripts checked (your "might have .sh" question)

| Script | Verdict | Why |
|---|---|---|
| `Volume.sh` | Replaced by DMS | pamixer + swaync notifications — DMS audio widget/ipc does this natively |
| `MediaCtrl.sh` | Replaced by DMS | playerctl wrapper — DMS has native MPRIS controls |
| `KillActiveProcess.sh` | Replaced natively | `hyprctl activewindow` → mango's `killclient force` does SIGKILL without a script |
| `Kool_Quick_Settings.sh` | Not ported | Reads `~/.config/hypr/UserConfigs/*`, edits Hyprland config files, toggles waybar/rainbow-borders — 100% Hyprland-dotfiles-specific. Mango equivalent is DMS Settings (`SUPER+comma`) |
| `AirplaneMode.sh` | Portable as-is | Pure `rfkill` — no Hyprland deps. Not bound here (XF86RFKill is a media key — skipped with the section). Ask if you want it on a chord |

## Summary

- ✅ 62 binds ported (incl. mouse + wheel)
- 🔀 3 remapped (SUPER+SPACE→SUPER+CTRL+SPACE, group cycle Tab→CTRL+Tab chords)
- 🔄 3 semantic equivalents (group toggle, force-kill, tiling move)
- ❌ 5 not portable (pseudo, runtime splitratio, SUPER+comma collision, workspace-10, Kool_Quick_Settings)
- ⏭️ Media/function keys skipped per request
