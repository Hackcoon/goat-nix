# Perf changes 2026-09-11 (game-mode + idle drain)

## 1. Game-mode chord — `Super+Shift+G`

File: `~/.config/mango/config.conf` (System section)

```ini
# Game mode (hide bar for direct scanout)
bind=SUPER+SHIFT,g,spawn_shell,~/.config/mango/toggle-dms-bar.sh
```

Reuses the existing DMS-bar toggle (same script as
`Ctrl+Alt+Super+B`). Fullscreen game + hidden bars lets wlroots
direct-scanout. `mango -p` clean, Super+H row verified.

### Revert

Delete those two lines. No restart needed (mango hot-reloads).

## 2. ollama + open-webui gated to manual start

File: `/etc/nixos/modules/programs/ai-services.nix`

```nix
systemd.services.ollama.wantedBy = lib.mkForce [];
systemd.services.open-webui.wantedBy = lib.mkForce [];
```

Both were `active`+`enabled` (ollama-cuda idles on the NVIDIA GPU).
They no longer autostart; start manually when needed:

```sh
sudo systemctl start ollama open-webui
```

Applied with: `sudo nixos-rebuild switch --flake /etc/nixos#nixos`
(hermes-agent untouched, still always-on).

### Revert

Delete the two `wantedBy` lines (keep the comment or not), then:

```sh
sudo nixos-rebuild switch --flake /etc/nixos#nixos
sudo systemctl start ollama open-webui
```
