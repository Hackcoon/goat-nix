# Cheatsheet maintainer guide (for AI agents)

The Super+H cheatsheet is DMS's **native keybinds modal** — there is no
custom code to edit. It renders live from the mango config:

- Open it: `dms ipc call keybinds toggle mangowc`
- Data source: `dms keybinds show mangowc` (JSON; parse this to verify)
- Source of truth: `~/.config/mango/config.conf` (+ `media.conf`, see below)

## How descriptions work

DMS takes each bind's description from the **last `#` comment line
directly above the bind**. Headers like `# ---- Standard ----` render
as section dividers. Known dispatchers (`view`, `tag`, `zoom`, …) get
built-in friendly names when no comment exists; unknown/raw actions
show verbatim. So: to add or fix a cheatsheet row, add/change the
comment above the bind — keep it under ~30 chars:

```ini
# Editor (vscodium)
bind=SUPER,c,spawn,codium
```

## Hard rules (learned the painful way)

- Comments must start at **column 1**. Never put `#` inline on a bind
  line — mango glues it onto the last argument and breaks the bind.
- `mango -p -c ~/.config/mango/config.conf` must exit 0 with no
  `Unknown dispatch` errors and no conflict warnings. Mango
  hot-reloads, so valid edits apply instantly; invalid ones are
  ignored (running session keeps last-good config).
- Media/volume keys live in `~/.config/mango/media.conf`, **indented
  by one space**, sourced from `config.conf`. Mango executes indented
  binds normally (proven via its conflict detector) but the DMS
  parser only reads `bind=` at column 1 — so they work while staying
  off Super+H. Do not move them back into `config.conf` unindented.
- Do not use `dms/binds.conf` (empty, DMS-managed include slot).
- Installed mango is 0.16.2 (latest release as of writing); the docs
  site tracks dev main, so dispatchers listed there (e.g. Tag 0
  `toggle_special_tag`) may not exist here. Verify every new
  dispatcher against the binary (`mango -p` rejects unknowns).

## Verify a change

1. `mango -p -c ~/.config/mango/config.conf` → exit 0, no output.
2. `dms keybinds show mangowc` → check the row's `key`/`desc`.
3. Visual proof: `dms ipc call keybinds toggle mangowc`, screenshot
   with `grim /tmp/x.png`, read the image, toggle again to close.

## Retired: custom overlay

`~/.config/quickshell/mango-help/shell.qml` is a retired standalone
Quickshell overlay — superseded because text input never receives
focus in its layer-shell surface under mango. Leave it alone.
