# MangoWC + DMS on NixOS — Full Setup Guide

Your setup is split in 2. This is why it's confusing:

- **System (Nix-managed)** = compositor + shell + greeter, in `/etc/nixos/`
- **User config (plain files)** = keybinds, bar, theme, plugins, in `~/`

`modules/desktop/mango-dms.nix` deliberately does NOT manage `~/.config/mango` — mango hot-reloads it itself.

---

## 1. System part (Nix)

You need this on the new machine in `/etc/nixos/modules/desktop/mango-dms.nix`:

```nix
programs.mangowc = {
  enable = true;
  package = unstablePkgs.mangowc; # 0.16.x — new IPC, DMS-compatible
  # don't use stable 0.12.8 — DMS bar shows NO workspaces
};

programs.dank-material-shell = {
  enable = true;
  systemd.target = "mango-session.target"; # DMS only runs inside Mango
};

programs.dms-greeter = {
  enable = true;
  configHome = "/home/fury";
  compositor.name = "hyprland";
};

environment.systemPackages = with pkgs; [
  wl-clipboard cliphist pamixer brightnessctl networkmanagerapplet
];

xdg.portal.config.mango.default = lib.mkForce [ "wlr" "gtk" ];
```

Flake inputs required (`/etc/nixos/flake.nix`):

- `dms.url = "github:AvengeMedia/DankMaterialShell/v1.6.0"`
- `dank-greeter.url = "github:AvengeMedia/dank-greeter"`
- `dsearch.url = "github:AvengeMedia/danksearch"`
- `nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixos-unstable"`
- all with `inputs.nixpkgs.follows = "nixpkgs-unstable"` (except HM)

Rebuild:

```bash
sudo nixos-rebuild test --flake /etc/nixos#nixos
# log in to Mango, check bar + workspaces, then:
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

## 2. User config part (just copy files)

Backup on old machine:

```bash
tar -czf mango-dms-backup.tar.gz -C ~ \
  .config/mango \
  .config/DankMaterialShell/settings.json \
  .config/DankMaterialShell/plugins/mangoWmLayoutManager \
  .config/DankMaterialShell/themes/amoledBlack \
  .config/systemd/user/mango-session.target
```

Restore on new machine to the same paths, then:

```bash
tar -xzf mango-dms-backup.tar.gz -C ~
chmod +x ~/.config/mango/*.sh
mango -p -c ~/.config/mango/config.conf
# must exit 0 with no output — invalid edits are ignored live
systemctl --user daemon-reload
```

What each file is:

- `~/.config/mango/config.conf` — all binds (`SUPER+X` powermenu, `SUPER+T` theme, `SUPER+O` control-center, `SUPER+SHIFT+N` DND, `SUPER+P` power-profile, `SUPER+SHIFT+P` play/pause, `SUPER+ALT+L` lock, etc.)
- `~/.config/mango/media.conf` — volume/brightness keys (indented so they stay off `SUPER+H`)
- `~/.config/mango/*.sh` — `cycle-fav-layouts.sh`, `cycle-tag.sh`, `toggle-dms-bar.sh`, `kill-focused.sh`
- `~/.config/mango/dms/` — leave `colors.conf` / `layout.conf` / `outputs.conf` empty, DMS rewrites them from Settings > Compositor
- `~/.config/systemd/user/mango-session.target`:
  ```ini
  [Unit]
  Description=MangoWC Session Target
  Requires=graphical-session.target
  After=graphical-session.target
  ```
  Started by mango's `exec-once=systemctl --user start mango-session.target`
- `~/.config/DankMaterialShell/settings.json`, `plugins/`, `themes/` — bar layout, widgets, amoledBlack theme

## 3. First login

1. In greeter pick `Mango` session, log in
2. `dms ipc call settings focusOrToggle` > Plugins > Scan > enable `mangoWmLayoutManager` > DankBar > add widget
3. Requires `mmsg` + `jq` on PATH (already in your mango install)
4. `SUPER+H` to verify binds, `dms restart` if bar misses anything

## 4. Troubleshooting

- No workspaces in bar: you installed mangowc 0.12.8, need unstable 0.16.x for `MANGO_INSTANCE_SIGNATURE` IPC
- DMS runs in KDE/Hyprland too: `systemd.target` is wrong, must be `mango-session.target` not `graphical-session.target`
- Binds don't apply: `mango -p -c ~/.config/mango/config.conf` shows the error, mango keeps last-good config
- Cheatsheet row missing/wrong: description comes from the last `#` comment directly above the `bind=` line, must start at column 1, never inline
- Greeter conflict: only one display manager can own the seat — `dms-greeter` (greetd) vs SDDM, disable SDDM when greeter is on
