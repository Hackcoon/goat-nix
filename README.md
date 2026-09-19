# goat-nix — Goat's NixOS laptop config

Ryzen 7 7840HS + Radeon 780M + RTX 4060 Max-Q/Mobile, Dubai (Asia/Dubai),
Spanish keyboard, everything in English. NVIDIA is the primary GPU
(PRIME sync). Forked from a desktop config and re-tuned for this laptop.

Desktops: **MangoWC + DankMaterialShell 1.6** (greetd login, `mango`
session), **KDE Plasma 6** (SDDM), **Hyprland**. Pick at login.

Power: `laptop.powerMode = "powersave" | "balanced" | "performance"`
in `configuration.nix` (default `balanced`). TLP handles AC vs battery
automatically underneath.

## First install (fresh NixOS)

You need: a NixOS 26.05 installer USB, internet, and this repo.

```bash
# 1. Boot the installer, partition + install minimal NixOS first
#    (or use nixos-install directly with this flake — either way you
#    need a hardware-configuration.nix from YOUR disk):

# 2. Clone this repo and enter it
git clone <this-repo-url> ~/goat-nix
cd ~/goat-nix

# 3. Generate YOUR hardware config (disk UUIDs, kernel modules)
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# 4. Uncomment the hardware import in configuration.nix:
#      # ./hardware-configuration.nix
#    ->  ./hardware-configuration.nix

# 5. Copy to /etc/nixos and switch
sudo cp -r ~/goat-nix /etc/nixos   # or symlink it
cd /etc/nixos
sudo nixos-rebuild switch --flake .#nixos
```

`hardware-configuration.nix` is git-ignored on purpose — it contains your
disk UUIDs and must never be committed.

## After install

- Log in as `goat` (set the password on first boot:
  `sudo passwd goat`).
- Session list at login: `mango` (MangoWC + DMS), Plasma, Hyprland.
- Hyprland keyboard: `~/.config/hypr` is hand-managed — add
  `kb_layout = es` to its `input { }` block (KDE/SDDM/TTY are already
  Spanish via the flake).
- Verify GPUs: `nvidia-smi`, `glxinfo | grep NVIDIA`,
  `dmesg | grep -E 'amdgpu|nvidia'`.
- Battery life: `hardware-profiles.nvidia-prime.mode = "offload"` +
  `laptop.powerMode = "powersave"` (sync keeps the dGPU always on).
- Charge cap is 80% for longevity; raise to 100% before trips:
  `services.tlp.settings.STOP_CHARGE_THRESH_BAT0 = 100`.
- Firefox: check `about:policies` — profile persists across rebuilds
  (`MOZ_LEGACY_PROFILES=1`), session restores, English UI.

## Layout

```
configuration.nix          entry point: imports + per-machine switches
flake.nix                  inputs (nixpkgs 26.05 + unstable, DMS, Home
                           Manager...). lanzaboote + qylock DISABLED.
home.nix                   Home Manager for user goat
modules/core/              boot, nix, locale (Dubai/en_US/es keys),
                           network, dns, default-apps
modules/hardware/          nvidia (desktop-gated), hardware-profiles
                           (PRIME sync, BusIDs baked in), laptop, amdgpu
                           bits, power-modes, audio, ssd, razer
modules/desktop/           kde, hyprland, mango-dms (MangoWC + DMS 1.6),
                           fonts, themes, portals (qylock DISABLED)
modules/programs/          shell, gaming (Steam/GameMode), firefox,
                           appimage, virtualisation, thunar
                           (ai-services DISABLED)
modules/services/          printing, flatpak
modules/system/            btrfs (opt-in), desktop-extras (all off)
modules/users/             user goat
modules/packages/          system packages, brave-webgpu, apps-fixed
```

## Re-enable later

- **qylock**: uncomment input + module in `flake.nix`, import in
  `configuration.nix`.
- **Secure Boot**: enroll keys with `sbctl`, uncomment lanzaboote input
  + module in `flake.nix`, enable `boot.lanzaboote` in
  `modules/core/boot.nix`.
- **Btrfs**: reformat with subvolumes, set `btrfs-root.enable = true`
  (see `modules/system/btrfs.nix` header for steps).
