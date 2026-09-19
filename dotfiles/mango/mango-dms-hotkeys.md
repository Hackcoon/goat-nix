# MangoWC + DMS Hotkeys (fury)

Mango 0.16.x + DankMaterialShell 1.6. Config: `~/.config/mango/config.conf` (hot-reloads, validate with `mango -p -c ~/.config/mango/config.conf`), media keys in `media.conf` (indented so they stay off `SUPER+H`). Cheatsheet: `SUPER+H`. Descriptions come from the `#` comment above each bind.

## DMS shell

| Shortcut | Action |
|---|---|
| `SUPER + Space` | Spotlight launcher |
| `SUPER + V` | Clipboard history |
| `SUPER + M` | Process list |
| `SUPER + Comma` | DMS settings |
| `SUPER + N` | Notifications panel |
| `SUPER + Shift + N` | Do not disturb toggle |
| `SUPER + W` | Wallpaper switcher |
| `SUPER + O` | Control center |
| `SUPER + Shift + C` | Color picker |
| `SUPER + T` | Theme dark/light toggle |
| `SUPER + Y` | YouTube web app (brave --app) |
| `SUPER + Alt + L` | Lock screen |
| `CTRL + Alt + P` | Power menu |
| `SUPER + X` | Power menu quick |
| `SUPER + P` | Power profile cycle (perf/balanced/saver) |
| `SUPER + Shift + P` | Media play/pause |
| `SUPER + H` | This cheatsheet |
| `SUPER + Shift + H` | Zsh aliases list (rofi, Enter copies) |
| `CTRL + Alt + SUPER + B` | Toggle DMS bar (island-safe script) |

## Layouts (14, per-tag)

`SUPER+L` cycles: tile, scroller, monocle, grid, deck, center_tile, vertical_tile, right_tile, vertical_scroller, vertical_grid, vertical_deck, dwindle, fair, vertical_fair.

| Shortcut | Action |
|---|---|
| `SUPER + L` | Next layout (all 14) |
| `SUPER + A` | Fave-four rotation (tile, scroller, monocle, dwindle) |
| `SUPER + I` | More masters (`incnmaster +1`) |
| `SUPER + CTRL + D` | Fewer masters (`incnmaster -1`) |
| `SUPER + CTRL + Return` | Swap with master (`zoom`) |
| `SUPER + Shift + I` | Dwindle toggle split |

## Apps

| Shortcut | Action |
|---|---|
| `SUPER + Return` | Kitty |
| `SUPER + D` | Dolphin |
| `SUPER + E` | Thunar |
| `SUPER + B` | Browser (`xdg-open https://` → Brave WebGPU build) |
| `SUPER + F` | Firefox |
| `SUPER + C` | VSCodium |
| `SUPER + Shift + Return` | Kitty dropdown scratchpad |

## Windows

| Shortcut | Action |
|---|---|
| `SUPER + Q` | Close (`killclient`) |
| `SUPER + Shift + Q` | Force kill (`killclient force`, SIGKILL) |
| `SUPER + Shift + F` | Fullscreen |
| `SUPER + CTRL + F` | Maximize (keeps bar/border) |
| `SUPER + CTRL + Space` | Float current |
| `SUPER + Alt + Space` | Float all |
| `ALT + Tab` / `ALT + Shift + Tab` | Next / prev window (`focusstack`) |
| `SUPER + Arrows` | Focus dir |
| `SUPER + CTRL + Arrows` | Swap tiling window (`exchange_client`) |
| `SUPER + Alt + Arrows` | Move floating (`smartmovewin`) |
| `SUPER + Shift + Arrows` | Resize 50px |
| `SUPER + LMB drag` / `RMB drag` | Move / resize |
| `SUPER + G` | Group with right neighbor |
| `SUPER + CTRL + K` / `L` | Group left / right |
| `SUPER + CTRL + H` | Leave group |
| `SUPER + CTRL + Tab` / `CTRL + Shift + Tab` | Next / prev group member |

## Screenshots (DMS → satty)

| Shortcut | Action |
|---|---|
| `SUPER + S` | Region → satty annotate |
| `SUPER + Shift + S` | Window → satty |
| `SUPER + CTRL + Shift + S` | Fullscreen → satty |
| `Print` | Full save (file + clipboard) |
| `Shift + Print` | Region save |
| `Alt + Print` | Window save |

## Tags (workspaces, 9, carousel wraps 9↔1)

| Shortcut | Action |
|---|---|
| `SUPER + Tab` | Next used tag (skips empty) |
| `SUPER + Shift + Tab` | Prev used tag |
| `SUPER + Period` / `Shift + Period` | Cycle all tags fwd/back (incl. empty, via script) |
| `SUPER + Wheel up/down` | Prev / next used tag |
| `SUPER + 1..9` | View tag N |
| `SUPER + Shift + 1..9` | Send window to tag + follow |
| `SUPER + CTRL + 1..9` | Send silent (no follow) |
| `SUPER + Shift + [` / `]` | Move window one tag left / right |
| `SUPER + U` | Tiling scratchpad |
| `SUPER + Shift + U` | Minimize |
| `SUPER + CTRL + U` | Restore minimized |

## Media keys (`media.conf`, hidden from cheatsheet)

| Key | Action |
|---|---|
| `XF86AudioRaiseVolume` | Volume +3 |
| `XF86AudioLowerVolume` | Volume -3 |
| `XF86AudioMute` | Mute |
| `XF86MonBrightnessUp` | Brightness +5 |
| `XF86MonBrightnessDown` | Brightness -5 |

## Appearance

`border 1px` red focus, `radius 12`, `gaps 5`, `focused_opacity 1.0`, `unfocused_opacity 0.9`, `shadows on` (floating only, size 10 blur 15). Mouse `accel -0.5 flat`. DMS fragments sourced from `~/.config/mango/dms/`.
