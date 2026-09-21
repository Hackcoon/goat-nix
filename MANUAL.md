# 🐐 goat-nix — Complete System Manual

> **Ryzen 7 7840HS + Radeon 780M + RTX 4060 Max-Q/Mobile · Dubai (Asia/Dubai) · Spanish keyboard, English system · NVIDIA primary via PRIME sync**
>
> Flake: `nixosConfigurations.nixos` · Stable `nixos-26.05` + `nixos-unstable` · Home Manager integrated · Hostname `ronny-nix` (when `laptop.enable = true`)

This is the **operator's manual** for this machine. If `README.md` is the quick-start card, this is the whole handbook: how to boot it, log in, rebuild it, update it, use Nix, flip hardware switches, game, print, virtualize, recover it when it breaks, and push changes to GitHub.

Config lives at **`/etc/nixos`** on the machine (a git clone of `https://github.com/Hackcoon/goat-nix.git`). Edit it there. This repo you are reading is that same content.

---
## Table of contents

- [1. System at a glance](#1-system-at-a-glance)
- [2. First install on a fresh machine](#2-first-install-on-a-fresh-machine)
- [3. The edit → test → switch loop (read this first)](#3-the-edit--test--switch-loop-read-this-first)
- [4. Updating the system](#4-updating-the-system)
- [5. Generations, rollback, boot menu](#5-generations-rollback-boot-menu)
- [6. Nix command survival guide](#6-nix-command-survival-guide)
- [7. Flakes: inputs, lock file, unstable](#7-flakes-inputs-lock-file-unstable)
- [8. Config layout map (where is what)](#8-config-layout-map-where-is-what)
- [9. Hardware switches you will actually flip](#9-hardware-switches-you-will-actually-flip)
- [10. Desktops: MangoWC + DMS, Plasma, Hyprland](#10-desktops-mangowc--dms-plasma-hyprland)
- [11. Home Manager (user `goat`)](#11-home-manager-user-goat)
- [12. Shell + alias reference](#12-shell--alias-reference)
- [13. Network, DNS, Bluetooth, SSH](#13-network-dns-bluetooth-ssh)
- [14. Audio (PipeWire)](#14-audio-pipewire)
- [15. Gaming, VMs, Flatpak, printing, AppImage](#15-gaming-vms-flatpak-printing-appimage)
- [16. Browsers: Brave, Brave WebGPU, Firefox](#16-browsers-brave-brave-webgpu-firefox)
- [17. Maintenance: cleanup, disk, logs, firmware](#17-maintenance-cleanup-disk-logs-firmware)
- [18. Git + GitHub workflow for /etc/nixos](#18-git--github-workflow-for-etcnixos)
- [19. Troubleshooting](#19-troubleshooting)
- [20. Re-enable later: Secure Boot, qylock, Btrfs](#20-re-enable-later-secure-boot-qylock-btrfs)
- [Appendix A: verification checklist](#appendix-a-verification-checklist)
- [Appendix B: file index](#appendix-b-file-index)

---

## 1. System at a glance

| Item | Value |
|---|---|
| Machine | Laptop: Ryzen 7 7840HS + Radeon 780M (iGPU) + RTX 4060 Max-Q/Mobile (dGPU) |
| GPU mode | **PRIME sync** — NVIDIA renders everything, AMD displays. Best fps, dGPU always on |
| OS | NixOS 26.05 (flake), `nixosConfigurations.nixos`, `system.stateVersion = "26.05"` |
| Hostname | `ronny-nix` (forced by `modules/hardware/laptop.nix`; base is `nixos` when laptop module off) |
| User | `goat` — groups `wheel`, `networkmanager`, `libvirtd`, `wireshark`; default shell `zsh` |
| Time/locale/keys | `Asia/Dubai` (UTC+4, no DST) · `en_US.UTF-8` everywhere (never Arabic) · Spanish (`es`) physical keyboard: console + X11/SDDM/KDE. Hyprland `~/.config/hypr` is hand-managed — add `kb_layout = es` yourself |
| Boot | systemd-boot, EFI writable, 20 boot entries max. Secure Boot / lanzaboote **disabled** for now |
| Kernel | Stable `pkgs.linuxPackages` + `amd_pstate=active` + `mem_sleep_default=deep` |
| Login | greetd + **dms-greeter** (Hyprland-rendered, DMS wallpaper/theme, capped 1080p60). SDDM auto-disables when greeter is on. Sessions: **mango**, **Plasma**, **Hyprland** |
| Shell | MangoWC 0.17.0 (unstable override, DMS-compatible IPC) + DankMaterialShell 1.6.0 + danksearch (`dsearch`) |
| Sound | PipeWire + WirePlumber + ALSA/32-bit + Pulse/JACK shims, rtkit, BlueZ SBC-XQ/mSBC |
| Power | TLP (power-profiles-daemon forced off) + `laptop.powerMode` presets + upower + suspend-then-hibernate + 80% charge cap |
| DNS | systemd-resolved + DoT. Switch with `dns.provider = "quad9"|"cloudflare"|"google"|"native"` (current: `google`) |
| Nix | Flakes + `nix-command` on, `auto-optimise-store`, CUDA cache, `cudaSupport = true`, nix-ld, `nh` with weekly `nh clean --keep-since 30d --keep 10 --keep-one` as the ONLY GC |
| Config path | `/etc/nixos` (git repo). Flake target everywhere: `/etc/nixos#nixos` |

> Rule #1 of this system: **NixOS is declarative.** You don't "install stuff" — you declare it in `/etc/nixos`, rebuild, and the system converges. To remove something, delete the line and rebuild.

---

## 2. First install on a fresh machine

You need: a NixOS 26.05 USB installer, internet, and this repo.

```bash
# 1. Boot the installer. Partition + install a minimal NixOS first
#    (or use nixos-install directly with this flake — either way you
#    need a hardware-configuration.nix from YOUR disk).

# 2. Clone and enter
 git clone https://github.com/Hackcoon/goat-nix.git ~/goat-nix
cd ~/goat-nix

# 3. Generate YOUR hardware config (disk UUIDs, kernel modules)
sudo nixos-generate-config --show-hardware-config > hardware-configuration.nix

# 4. Uncomment the hardware import in configuration.nix:
#      # ./hardware-configuration.nix
#   ->   ./hardware-configuration.nix

# 5. Copy to /etc/nixos and switch
sudo cp -r ~/goat-nix /etc/nixos   # or symlink it
cd /etc/nixos
sudo nixos-rebuild switch --flake .#nixos
```

`hardware-configuration.nix` is **git-ignored on purpose** — disk UUIDs must never be committed.

After first boot:

```bash
sudo passwd goat          # set the login password
nvidia-smi                # dGPU alive?
glxinfo | grep NVIDIA     # GL vendor = NVIDIA (needs mesa-demos pkg)
dmesg | grep -E 'amdgpu|nvidia'
```

- Login screen: pick `mango` (MangoWC + DMS), Plasma, or Hyprland.
- Hyprland keyboard: `~/.config/hypr` is hand-managed — add `kb_layout = es` to its `input { }` block.
- Battery life: flip PRIME to `offload` + `laptop.powerMode = "powersave"` (sync keeps the dGPU always on).
- Charge cap is 80% for longevity; raise to 100% before trips (see §9).
- Firefox: check `about:policies` — profile persists across rebuilds (`MOZ_LEGACY_PROFILES=1`), session restores, English UI.

---

## 3. The edit → test → switch loop (read this first)

Every change follows the same 6 steps. Use the zsh aliases (defined in `modules/programs/shell.nix`):

```zsh
cden               # cd /etc/nixos

# 1. edit files...  (configuration.nix, modules/..., home.nix)

# 2. track new files — FLAKES IGNORE UNTRACKED FILES!
nix-track          # = git -C /etc/nixos add -A (also needed for nh builds)

# 3. review
config-status      # changed + untracked
config-diff        # what changed

# 4. validate — pick one
nix-test           # temp activate, safe first try (no boot entry)
nix-build-system   # build only, activate nothing
nix-build-dry      # dry-build: print what WOULD happen
nix-check          # nix flake check (validates flake outputs)

# 5. save + publish (NO sudo for git — see §18)
config-savem "Short imperative msg, e.g. Enable Blocky NSFW group"
git push

# 6. activate permanently (needs sudo; alias handles it)
nix-switch         # = nix-rebuild = sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

What each rebuild mode does:

| Alias | Command | Effect |
|---|---|---|
| `nix-test` / `nh-test` | `nixos-rebuild test` | Activates now, **no boot entry**. Reboot reverts. Safest first try |
| `nix-switch` / `nix-rebuild` / `nh-os` | `nixos-rebuild switch` | Activates now **+ makes a boot entry**. The normal path |
| `nix-boot` / `nh-boot` | `nixos-rebuild boot` | Stages for **next boot only**, does not touch the running system |
| `nix-build-system` / `nh-build` | `nixos-rebuild build` | Builds `./result` symlink, activates nothing |
| `nix-build-dry` | `nixos-rebuild dry-build` | Prints actions, changes nothing |
| `nix-rollback` / `nh-rollback` | `switch --rollback` | Boots previous generation immediately |

> If `nixos-rebuild` says `Path X is not tracked by Git`, you forgot `nix-track`. New files must be `git add`ed before the flake can see them.

---

## 4. Updating the system

There are TWO different "updates". Don't confuse them:

### 4a. Normal rebuild (locked versions — daily use)

Rebuilds using the exact versions pinned in `flake.lock`. Nothing upgrades. This is what you want 95% of the time:

```bash
nix-switch                 # classic
# or
nh-os                      # nh variant: nicer diff + progress
nix-upgrade-locked         # explicit alias, same thing
```

### 4b. Full input update (actually upgrades packages)

Pulls every flake input (`nixpkgs`, `nixpkgs-unstable`, DMS, Home Manager…) to latest, rewrites `flake.lock`, then rebuilds:

```bash
nix-upgrade                # = nix flake update + switch
nh-upgrade                 # nh equivalent: nh os switch /etc/nixos --update
```

More surgical options:

```bash
flake-update               # update flake.lock WITHOUT rebuilding (review first!)
nh-up-input nixpkgs        # update ONE input only, e.g. nixpkgs  (append the input name)
nix-inputs                 # show exact pinned revisions (nix flake metadata)
```

Recommended cadence:

1. `flake-update` (or `nix flake update`), then `config-diff` / `git diff flake.lock` to see what moved.
2. `nix-test` — run the new versions without committing to them.
3. If good: `config-savem "Bump flake inputs YYYY-MM-DD" && git push`, then `nix-switch`.
4. If bad: reboot (test never wrote a boot entry) or `nix-rollback`.

> Kernel + NVIDIA driver upgrade together: stable `linuxPackages` is paired with `nvidiaPackages.stable` in `hardware-profiles.nix`. After a big `nixpkgs` bump, verify with `nvidia-smi` before calling it done.

---

## 5. Generations, rollback, boot menu

Every `switch`/`boot` creates a **generation** — a complete bootable system entry. Old ones stay until garbage-collected. systemd-boot keeps the last 20 (`configurationLimit = 20`).

```bash
nix-generations            # list all generations
nh-info                    # nh view of generations
nix-current                # which generation is live now (readlink .../system)

# Roll back RIGHT NOW to the previous generation:
nix-rollback               # sudo nixos-rebuild switch --rollback
nh-rollback                # nh variant

# Or pick at boot: reboot → systemd-boot menu → older generation
# (keyboard: arrow keys + Enter; 20 entries max)
```

Trimming old generations (frees gigabytes in /nix/store):

```bash
nix-keep-10                # keep last 10, GC the rest, refresh boot menu
nix-keep-20                # keep last 20 (more rollback headroom)
nix-gc / nixdelete         # normal GC: delete store paths older than 30d
nix-delete-all-old         # delete ALL old generations (only when certain!)
nh-clean                   # = nh clean all (broader: all profiles + store)
```

Automatic GC is handled by **weekly `nh clean --keep-since 30d --keep 10 --keep-one`** (`modules/core/nix.nix`). Do NOT also enable `nix.gc` — the two timers race on the store lock.

---

## 6. Nix command survival guide

The aliases below all exist on this system (`modules/programs/shell.nix`). Plain commands shown so you learn what the alias does.

### Rebuilds (see §3 for the loop)

| Alias | Expands to | When |
|---|---|---|
| `nix-test` | `sudo nixos-rebuild test --flake /etc/nixos#nixos` | First try after any edit |
| `nix-switch`, `nix-rebuild` | `sudo nixos-rebuild switch --flake /etc/nixos#nixos` | Commit to it permanently |
| `nix-boot` | `... boot ...` | Stage for next reboot |
| `nix-build-system` | `... build ...` | Build `./result` only |
| `nix-build-dry` | `... dry-build ...` | Preview actions |
| `nh-os`, `nh-test`, `nh-boot`, `nh-build` | `nh os switch/test/boot/build /etc/nixos` | Friendlier nh variants |
| `nh-upgrade` | `nh os switch /etc/nixos --update` | Update inputs + switch |
| `nh-up-input <name>` | `nh os switch /etc/nixos --update-input <name>` | Update one input |

### Searching, trying, and inspecting packages

```bash
nix-search firefox          # search stable nixpkgs (first run is slow — builds index)
nh-search firefox           # nh search (packages AND NixOS options)
nrun cowsay                 # try an app once without installing (nix run nixpkgs#cowsay)
nshell hello ripgrep        # one-off shell with packages (nix shell nixpkgs#hello ...)
manix <option>              # fast local search of NixOS options (installed pkg `manix`)
nix-big                     # 20 biggest closures in the live system
why /nix/store/xyz...      # why is this store path kept? (nix why-depends /run/current-system ...)
```

### Store health

```bash
nix-store-size              # du -sh /nix/store
nix-optimize                # dedupe identical files (also automatic via auto-optimise-store)
nix-format                  # nixfmt configuration.nix + flake.nix (keep style consistent)
```

### Everyday shell aliases on this box

```bash
ls / ll / lsd / tree       # eza with icons (tree = eza --tree)
cat                        # = bat (syntax highlighting)
man                        # = batman (colorized manpages)
tl                         # = tldr cheat sheets
f                          # = fd (fast find)
..                         # cd ..
duh                        # du -sh ./*
c / h / path               # clear / history / PATH one-per-line
ports                      # ss -tulpn (what is listening)
pubip / myip               # public IP via icanhazip / local addrs via ip -brief
weather                    # wttr.in one-liner
serve                      # python http server on :8000 in cwd
drives / disks / memory    # lsblk -f / df -h / free -h
ff / bt / dg              # fastfetch / btop / dgop (GPU monitor)
temp                       # sensors (CPU/GPU temps)
gpu                        # nvidia-smi
wifi                       # nmcli nearby networks
open <file|url>            # xdg-open
sz                         # exec zsh (reload aliases after editing shell.nix + rebuild)
restart-gui                # sudo systemctl restart display-manager
```

### systemd shortcuts

```bash
sc / scs / scus            # systemctl / system status / user status
scstart/scstop/screstart/screload/scenable/scdisable  # + unit (sudo)
sclogs <unit>               # journalctl -u <unit> (all boots)
sclogsb <unit>              # this boot only
ju [-u <unit>]             # journalctl --user -b (user services)
flog / logs-err            # follow live / this boot errors only
boot-status                # systemctl --failed
scu                        # systemctl --user (user services: dms, kanshi, dsearch…)
```

### direnv (per-project dev shells)

`programs.direnv + nix-direnv` is on: entering a directory with `.envrc` auto-loads its flake. First visit: `da` (`direnv allow`) to trust it.

---

## 7. Flakes: inputs, lock file, unstable

`flake.nix` declares every external dependency ("inputs"); `flake.lock` pins their exact git revisions so rebuilds are reproducible.

Current inputs (`flake.nix`):

| Input | URL | Role |
|---|---|---|
| `nixpkgs` | `github:NixOS/nixpkgs/nixos-26.05` | Stable base: kernel, NVIDIA driver, Plasma, PipeWire, services. Keep core here |
| `nixpkgs-unstable` | `github:NixOS/nixpkgs/nixos-unstable` | Fresher single apps via `unstablePkgs.<pkg>` (mangowc, opencode, llmfit, lmstudio-bionic…). Does NOT destabilize the system |
| `dms` | `github:AvengeMedia/DankMaterialShell/v1.6.0` | DankMaterialShell 1.6 NixOS module |
| `dank-greeter` | `github:AvengeMedia/dank-greeter` | dms-greeter login screen module |
| `dsearch` | `github:AvengeMedia/danksearch` | Indexed fuzzy file search (HM module + user service) |
| `hermes-agent` | `github:NousResearch/hermes-agent` | AI agent NixOS module (wired, enable per docs in flake when needed) |
| `home-manager` | `github:nix-community/home-manager/release-26.05` | User dotfiles (release matches nixpkgs 26.05) |
| ~~`lanzaboote`~~ | disabled | Secure Boot — re-enable after `sbctl` key enrollment |
| ~~`qylock`~~ | disabled | SDDM/Quickshell lockscreen themes — re-enable when wanted |

Key mechanics:

- `outputs.nixosConfigurations.nixos` is the ONE system. All commands address it as `--flake /etc/nixos#nixos`.
- `unstablePkgs` is built in `flake.nix` (`allowUnfree = true`) and passed via `specialArgs` — any module needing it declares `{ ..., unstablePkgs, ... }:` (see `system-packages.nix`, `mango-dms.nix`).
- Most `...inputs.nixpkgs.follows` point at stable, EXCEPT `dms`, `dank-greeter`, `dsearch` which follow `nixpkgs-unstable` (Quickshell-era deps aren't in stable yet).
- `nixpkgs.config.allowUnfree = true` is set in the desktop-gated `nvidia.nix`; `cudaSupport = true` is global (`nix.nix`) with the `cache.nixos-cuda.org` substituter so CUDA builds download instead of compiling.
- `permittedInsecurePackages` allows a few pinned EOL builds (electron/pnpm). Long-term fix: find the dependent and update it, then drop the entry.

---

## 8. Config layout map (where is what)

```
configuration.nix          entry point: imports + per-machine switches
flake.nix / flake.lock     inputs + nixosConfigurations.nixos wiring
MANUAL.md                  this file (operator handbook)
home.nix                   Home Manager for user goat
modules/core/              boot, nix, locale (Dubai/en_US/es keys),
                           network, dns, default-apps
modules/hardware/          nvidia (desktop-gated), hardware-profiles
                           (PRIME sync, BusIDs), laptop, amdgpu bits,
                           power-modes, audio, ssd, razer
modules/desktop/           kde, hyprland, mango-dms (MangoWC + DMS 1.6),
                           fonts, themes, portals (qylock DISABLED)
modules/programs/          shell, gaming (Steam/GameMode), firefox,
                           appimage, virtualisation, thunar
                           (ai-services DISABLED)
modules/services/          printing, flatpak
modules/system/            btrfs (opt-in), desktop-extras (mostly off)
modules/users/             user goat
modules/packages/          system packages, brave-webgpu, apps-fixed
docs/                      daily-loop.md, github-workflow.md, brave-fix-nixOS.md
dotfiles/mango/            MangoWC + DMS user config (hotkeys, setup guide)
```

- **Per-machine switches** (GPU mode, DNS, power, extras, Btrfs) live in `configuration.nix` — start there.
- **Tuned modules always beat portable profiles**: `hardware-profiles.nix` is all `mkDefault`; dedicated modules (e.g. `nvidia.nix`, `laptop.nix`) win on conflict.
- Every module header explains itself — read the top comment of any file before editing it.

---

## 9. Hardware switches you will actually flip

All in `configuration.nix` unless noted. Rebuild (`nix-test` → `nix-switch`) after changing.

### PRIME mode (battery vs performance) — the big one

```nix
hardware-profiles.nvidia-prime.mode = "sync";    # NVIDIA primary: best fps, dGPU always on
# hardware-profiles.nvidia-prime.mode = "offload"; # iGPU desktop, dGPU sleeps until `nvidia-offload <app>`
```

- `sync` (current): max gaming performance, worse battery.
- `offload`: max battery. Launch heavy apps with `nvidia-offload <app>` (wrapper installed when offload is on; `laptop.nix` enables `offloadCmd` automatically).
- BusIDs are baked in: AMD iGPU `PCI:5:0:0` (05:00.0), NVIDIA `PCI:1:0:0` (01:00.0). Re-verify with `lspci | grep -E 'VGA|3D|Display'` after hardware changes (hex bus → decimal!).
- Profiles: `hardware-profiles.amdgpu.enable = true` (780M Mesa/RADV stack — leave on), `nvidia-prime.enable = true`, desktop-only `nvidia.enable = false`.

### Power mode

**Short answer: yes — changing `laptop.powerMode` requires a rebuild.** It is a NixOS option, not a runtime toggle. NixOS builds the TLP config files from it at build time, so editing the line alone does nothing until you activate a new generation:

```zsh
# in /etc/nixos/configuration.nix:
laptop.powerMode = "powersave";   # or "balanced" | "performance"
nix-track && nix-test && nix-switch   # rebuild required — no way around it
```

Takes ~30s. `nix-test` first is safe (no boot entry); `nix-switch` commits it.

**But for RIGHT NOW (no rebuild), you have live controls:**

| What you want | Command (instant, no rebuild) | Notes |
|---|---|---|
| Cycle power profile in MangoWC | `SUPER+P` (or `dms ipc call powerprofile cycle`) | DMS cycles perf/balanced/saver live via D-Bus. **Caveat:** `power-profiles-daemon` is force-disabled on this box (TLP owns governors, see `laptop.nix`), so this talks to UPower/TLP state, not the classic PPD profiles — treat it as a quick nudge, not the real preset |
| Apply TLP battery vs AC profile now | `sudo tlp bat` / `sudo tlp ac` | Forces TLP's battery/AC table immediately (TLP auto-switches on plug/unplug anyway) |
| Check what TLP is doing | `sudo tlp-stat -s` | Status, active profile, charge thresholds |
| One-shot kernel tunables | `sudo powertop --auto-tune` | Applies powertop suggestions until next reboot |
| Monitor drain/thermals | `temp` (`sensors`) · `upower -d` · `acpi -b` · `bt` (`btop`) | Watch before/after |

**Rule of thumb:** live commands = temporary (gone after reboot or TLP re-applies). `laptop.powerMode` + rebuild = permanent (survives reboots, is the declared state, gets committed to git).

```nix
laptop.powerMode = "balanced";  # | "powersave" (flights/lectures) | "performance" (gaming/compiles, charger on)
```

Details in `modules/hardware/power-modes.nix`: TLP AC/BAT tables per preset. All modes cap charge at 80% (start 75%) for longevity. Before a trip:

```nix
services.tlp.settings.STOP_CHARGE_THRESH_BAT0 = 100;  # temporary 100% charge
```

Useful power commands:

```bash
temp            # sensors — watch thermals when trying performance mode
upower -d       # battery detail
acpi -b         # quick battery status
sudo powertop --auto-tune   # one-shot tunables
tlp-stat -s     # TLP status (if tlp CLI present)
```

### Other toggles

```nix
dns.provider = "google";   # | "quad9" | "cloudflare" | "native" (hotels/captive portals — plain DHCP DNS, no DoT)
laptop.enable = true;       # master laptop switch (power, touchpad, wifi, BT, sleep) — leave on

desktop-extras = {
  zram.enable = true;    # compressed RAM swap — leave on
  fstrim.enable = true;   # weekly SSD trim — leave on
  # nh.enable = true;     # friendly rebuild helper (already on via modules/core/nix.nix programs.nh — no need)
  # printing/sane/logitech/openrgb/plymouth/nfs/ly-greeter — enable only what you need
  # ly-greeter REPLACES SDDM/greetd — disable the other display manager first!
};
```

- Touchpad (libinput): tapping on, natural scroll off, disable-while-typing — `modules/hardware/laptop.nix`.
- Sleep: suspend-then-hibernate (2h → hibernate), lid close sleeps, battery warnings at 15/8%, hibernate at 5% via upower.
- Wi-Fi powersave + randomized scan MAC are on; if SSH drops on battery, set `services.tlp.settings.WIFI_PWR_ON_BAT = "off"`.
- GPUs: verify with `nvidia-smi`, `radeontop` (780M side), `nvitop`/`dgop` (NVIDIA side), `vulkaninfo`/`vkcube`, `glxinfo | grep -i vendor`.

---

## 10. Desktops: MangoWC + DMS, Plasma, Hyprland

Pick at the login screen. All three are installed simultaneously; the greeter lists `mango`, `Plasma`, `Hyprland`.

### MangoWC + DankMaterialShell 1.6 (daily driver)

- System side (`modules/desktop/mango-dms.nix`): MangoWC 0.17.0 (unstable override — stable 0.12.8 lacks the `MANGO_INSTANCE_SIGNATURE` IPC, so the DMS bar shows NO workspaces), DMS 1.6 bound to `mango-session.target` (never KDE/Hyprland), dms-greeter via greetd + Hyprland renderer, portals forced to `[ "wlr" "gtk" ]` for the `mango` session.
- User side (NOT Nix-managed — mango hot-reloads it): `~/.config/mango/config.conf` + `media.conf` + `*.sh` + `dms/` fragments + `~/.config/DankMaterialShell/` + `~/.config/systemd/user/mango-session.target`. A versioned copy lives in `dotfiles/mango/`.
- Validate edits: `mango -p -c ~/.config/mango/config.conf` (must exit 0; bad edits are ignored live).
- Cheatsheet in-session: `SUPER+H`. Full hotkey table: `dotfiles/mango/mango-dms-hotkeys.md`. Setup/porting guide: `dotfiles/mango/mango-dms-nixos-guide.md`.
- Key binds (essentials): `SUPER+Return` kitty · `SUPER+D/E` Dolphin/Thunar · `SUPER+B` Brave · `SUPER+F` Firefox · `SUPER+Space` spotlight · `SUPER+V` clipboard · `SUPER+O` control center · `SUPER+W` wallpaper · `SUPER+Q` close · `SUPER+1..9` tags · `SUPER+L/A` layouts · `SUPER+S` screenshot→satty · `SUPER+P` power profile · `CTRL+Alt+P`/`SUPER+X` power menu · media keys = volume/brightness.
- DMS CLI: `dmsi <cmd>` (= `dms ipc call <cmd>`), `dms restart`. Compositor CLI: `mmsg get all-monitors`.
- Displays: kanshi (HM service) auto-switches `undocked`/`docked-hdmi` profiles (`home.nix`). Calibrate with `wlr-randr` / `hyprctl monitors` / `mmsg get all-monitors`, watch `journalctl --user -u kanshi -f`.

### KDE Plasma 6

- Full session (`modules/desktop/kde.nix`): `plasma6`, X11 base + XWayland, Spanish XKB (drives SDDM + KDE), Wayland SDDM greeter — **auto-disabled while dms-greeter owns the seat** (two display managers = black screen).
- power-profiles-daemon stays OFF (TLP owns governors); battery widget reads UPower.
- GTK apps pinned to `Breeze-Dark` + `GoogleDot-Black` cursor (`themes.nix`); defaults: Okular PDFs/ePubs, Brave web, Mailspring mail (`default-apps.nix` — system-level `/etc/xdg/mimeapps.list` because KDE rewrites the user file).

### Hyprland

- Standalone compositor (`modules/desktop/hyprland.nix`): hyprlock/hypridle/hyprpaper/hyprsunset/hyprpicker/polkit-agent, Vicinae + rofi launchers, quickshell, waybar, swaync, grim/slurp/satty/swappy, pamixer/playerctl/pavucontrol, wlr-randr.
- Its `~/.config/hypr` is hand-managed: remember `kb_layout = es`.
- Portal routing: `hyprland → [hyprland, gtk]`; Plasma → `[kde, gtk]`; fallback `[gtk]` (`portals.nix`).

### Fonts

JetBrainsMono Nerd Font is the default monospace (kitty/bar/waybar); broad Noto/Arabic/CJK/emoji coverage so mixed-language pages never tofu. See `modules/desktop/fonts.nix`.

---

## 11. Home Manager (user `goat`)

Integrated mode: `home.nix` applies on every `nixos-rebuild` — there is NO separate `home-manager switch` step. (`programs.home-manager.enable = true` just installs the CLI for `home-manager news`/generations.)

Managed here: git identity (`furynix` + noreply email, `main` default, merge-on-pull), `EDITOR/VISUAL = codium --wait`, kitty (Google Sans Code 11, Catppuccin-Mocha on pure black `#000000`, 100k scrollback), btop (imported settings), YouTube Brave `--app` launcher, `~/.local/bin` on PATH, dsearch service (`dsearch search "name"`), kanshi display profiles.

Deliberately NOT in HM: zsh/aliases/zoxide/fzf (system `shell.nix` — admin recovery must not depend on HM), mime defaults/sioyek (system `default-apps.nix` — KDE rewrites user files), `home.packages` (single user, no benefit), vscodium/okular live settings (apps rewrite them), secrets (use sops-nix/agenix `environmentFiles`, never store plaintext).

If HM complains a file exists: `home-manager.backupFileExtension = "bak"` moves it aside automatically.

---

## 12. Shell + alias reference

zsh + Oh My Zsh (`af-magic`, `sudo` plugin — ESC twice prepends sudo) + autosuggestions + syntax highlighting + zoxide (`z`) + fzf (Ctrl-R/Ctrl-T) + direnv. Full catalog: `modules/programs/shell.nix`.

### Config git helpers (`/etc/nixos`)

| Alias | Meaning |
|---|---|
| `cden` | `cd /etc/nixos` |
| `nix-track` | `git -C /etc/nixos add -A` — REQUIRED before rebuild with new files |
| `config-status` / `config-diff` / `config-log` | status / diff / last-10 commits |
| `config-save` | `git add . && git commit` (prompts for message) |
| `config-savem "msg"` | same with inline message |
| `config-stage <paths>` + `config-commitm "msg"` | selective staging + commit |

### Compositor dotfile repos (Mango/Hyprland configs are separate git repos)

`mango-status` / `mango-save`, `hypr-status` / `hypr-save`, `dwm-status` / `dwm-save` (each: status / add+commit in `~/.config/<name>`).

### Everyday git (any repo)

`gst` status · `glog` graph · `gd`/`gds` diff unstaged/staged · `ga -p` interactive stage · `gcmsg "m"` commit · `gco` switch · `gb` branches · `gunstage` · `gstash "m"`/`gpop`.

### GitHub CLI

`gh` is installed: `gh auth login` → `gh repo create/clone` → `gh pr create` without leaving the terminal (see §18).

---

## 13. Network, DNS, Bluetooth, SSH

- **NetworkManager** owns everything (`network.nix`): use `nmtui`, the tray applet, or KDE settings — never hand-edit wpa_supplicant. Hostname `ronny-nix` (laptop module forces it).
- **DNS** (`dns.nix`): all lookups route via systemd-resolved stub `127.0.0.53` with DoT. Check: `resolvectl status`. Providers: `quad9` (9.9.9.9), `cloudflare` (1.1.1.1), `google` (8.8.8.8, current), `native` (plain DHCP — use on hotels/corporate Wi-Fi where DoT is blocked). Flip `dns.provider` in `configuration.nix` + rebuild.
- **Wi-Fi**: powersave + randomized scan MAC on (`laptop.nix`). Debug: `wifi` (scan list), `nmcli device status`, `nmcli connection show`.
- **Bluetooth**: on at boot, A2DP + experimental (headset battery). Pair via Blueman applet or `bluetoothctl`. Audio tweaks (SBC-XQ, mSBC) in `audio.nix`.
- **SSH**: server on (`ssh goat@<ip>`; find IP with `myip`). Not hardened for internet exposure — add key-only settings before opening firewall ports.
- **Wireshark**: `programs.wireshark` on + user in `wireshark` group = capture without sudo.
- Quick tools: `pubip`, `myip`, `ports` (`ss -tulpn`), `dig`, `nmap`, `traceroute`, `whois`, `iperf3` — all installed.

---

## 14. Audio (PipeWire)

One server only: PipeWire graph + WirePlumber policy + ALSA (+32-bit for Proton/Wine) + Pulse shim + JACK shim. Legacy `pulseaudio` daemon OFF, `rtkit` on (no crackling under load).

```bash
pavucontrol        # per-app levels (GUI)
pamixer ...        # CLI volume (DMS widget fallback)
playerctl ...      # media keys / MPRIS
wpctl status       # WirePlumber devices
systemctl --user status pipewire pipewire-pulse wireplumber
```

Bluetooth headset tweaks (SBC-XQ/mSBC) apply automatically; wired/USB audio untouched.

---

## 15. Gaming, VMs, Flatpak, printing, AppImage

### Gaming (`gaming.nix` + packages)

- Steam (Remote Play firewall open) + `proton-ge-bin` compat + GameMode (`renice 10`) + Gamescope (`capSysNice`) + `vm.max_map_count` for Proton + xpadneo (Xbox BT) + steam-hardware (Sony/Nintendo).
- Overlay: MangoHud `Shift+F12` (fps/frametimes/temps). Verify GPUs: `vulkaninfo`, `vkcube`, `glxinfo`.
- Extra launchers/tools: Heroic (GOG/Epic/Amazon), Bottles, PrismLauncher (Minecraft), `protontricks`, `protonup-qt`, `winetricks`, Wine 32+64-bit, en-croissant/pawn-appetit (chess), winboat (Windows apps via podman socket).
- NVIDIA session vars (`__NV_PRIME_RENDER_OFFLOAD=1`, `__VK_LAYER_NV_optimus=NVIDIA_only`) are set automatically in PRIME mode.

### Virtualisation (`virtualisation.nix`)

- **VMs**: libvirtd/QEMU-KVM (`qemu_kvm`, runAsRoot, swtpm for Win11 TPM) + virt-manager GUI + Spice USB passthrough. User `goat` is in `libvirtd` — no access-denied on the socket.
- **Containers**: Podman with `dockerCompat` + on-demand docker socket (zero idle cost). `docker` CLI works; need the real daemon? Replace with `virtualisation.docker.enable = true`. Plus `distrobox` and `devenv`.

### Flatpak (`flatpak.nix` + `desktop-extras.flatpak`)

Daemon is on. Flathub remote registers via `desktop-extras.flatpak.enable = true` (or once manually):

```bash
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub <app>
flatpak list / flatpak update / flatpak uninstall <app>
```

Portals (`portals.nix`) mediate sandboxed file/screen access — if a Flatpak can't share screen or open pickers, check portal routing (§10).

### Printing / scanning

CUPS on (`printing.nix`; add printers at `localhost:631` or KDE Print Manager; driverless IPP/AirPrint needs nothing). `desktop-extras.printing` is the alt switch (+ optional `hplipWithPlugin` for HP). Scanners: `desktop-extras.sane.enable` (sane-airscan, escl disabled to avoid dupes).

### AppImage (`appimage.nix` — binfmt on)

```bash
chmod +x ./SomeApp.AppImage && ./SomeApp.AppImage   # direct run
nix-shell -p appimage-run --run "appimage-run ./SomeApp.AppImage"  # fallback
```

`gearlever` manages AppImages + launchers like AppImageLauncher. For constant use, package it properly with `appimageTools.wrapType2` (recipe in the module header) and reference from `system-packages.nix`. If it errors on a missing `libXXX`, uncomment ONLY that lib in the module's `extraPkgs` override.

### Thunar

Thunar + archive/volman/media-tags/shares plugins, gvfs (USB/MTP/SMB/trash), tumbler (thumbnails), xfconf (settings) — `thunar.nix`.

---

## 16. Browsers: Brave, Brave WebGPU, Firefox

### Default Brave (daily driver)

Native Wayland build with `--password-store=gnome-libsecret` so logins survive WM switches. Set as default for http/https/html (`default-apps.nix`).

### Brave WebGPU (`brave-webgpu.nix` — the `bwg` command)

Separate `brave-webgpu` binary + launcher (Mango `SUPER+Shift+G`) for WebGPU/Vulkan sites (e.g. grainrad). Vulkan needs X11 ozone (Chromium Vulkan is incompatible with ozone/wayland) + `libvulkan.so.1` on `LD_LIBRARY_PATH` — both wired ONLY into this build so the daily browser stays smooth.

```bash
bwg                    # launch the WebGPU build
pkill -f 'opt/brave'   # kill old sessions first after a rebuild, or new launches reuse the old process!
```

Verify: `brave://gpu` → Vulkan Enabled + WebGPU hardware-accelerated; DevTools: `await navigator.gpu.requestAdapter()` must NOT be SwiftShader. Full root-cause writeup: `docs/brave-fix-nixOS.md`. Toggle: comment/uncomment the import in `configuration.nix`.

### Firefox (`firefox.nix`)

System module install with stay-logged-in policies: `MOZ_LEGACY_PROFILES=1` (one stable `~/.mozilla` profile across rebuilds), session restore, refresh-block, no clear-on-exit, password manager + autofill on, `en-US` UI. Verify at `about:policies`. Pywalfox native host is wired declaratively (never run `pywalfox install` — the store is read-only).

Also installed: Librewolf (privacy fork), qutebrowser (vim keys), Mailspring (default `mailto:` app).

### Defaults

`modules/core/default-apps.nix` pins: PDFs/ePubs → Okular (sioyek stays in Open-With), web → Brave, mail → Mailspring, plus deep-link schemes (discord/obsidian/notion/heroic/lmstudio/logseq/mailspring/opencode/cherrystudio). System-level `/etc/xdg/mimeapps.list` so KDE can't clobber it. Sioyek launches dark/black by default (`/etc/xdg/sioyek/prefs_user.config`).

---

## 17. Maintenance: cleanup, disk, logs, firmware

Automatic: weekly `nh clean --keep-since 30d --keep 10 --keep-one` (only GC — see §5), weekly fstrim (SSD TRIM), `/tmp` on tmpfs (20% RAM, saves SSD writes), zram swap (no disk wear, `swappiness 10`), journal capped at 200M, `auto-optimise-store` dedupes.

```bash
# Space
nix-store-size            # du -sh /nix/store
disks / drives / duh      # df -h / lsblk -f / dir sizes
nix-big                   # biggest live closures
gdu / mission-center      # interactive disk / GUI resource monitor

# Cleanup (escalating)
nix-gc                    # normal: delete store older than 30d
nh-clean                  # broader: all profiles + store
nix-keep-10 / nix-keep-20 # trim generations + GC + refresh boot menu
nix-gc-all                # NUKE all old generations (careful!)

# Logs & health
boot-status               # systemctl --failed
logs-err / flog           # this-boot errors / follow live
sclogs <unit> / ju -u <unit>  # system / user unit logs
temp / bt / ff            # sensors / btop / fastfetch
journalctl -t smartd      # disk health alerts (smartd block ready to enable in ssd.nix)
fwupdmgr get-updates      # firmware (fwupd daemon on)
```

Hibernation note: zram alone can't hibernate (needs disk swap with higher priority + `resume=` kernel param) — suspend works, hibernate fails gracefully. Recipe in `modules/hardware/ssd.nix` header.

---

## 18. Git + GitHub workflow for /etc/nixos

> **NO sudo for git/gh.** Only `nixos-rebuild` needs sudo. `sudo git` breaks HTTPS auth (root can't see your token). Full guide: `docs/github-workflow.md`; cheat sheet: `docs/daily-loop.md`.

### One-time setup (per machine)

```bash
gh auth login              # GitHub.com -> HTTPS -> Yes (paste TOKEN, not password), no sudo
gh auth status && gh auth setup-git
git config --global user.name "furynix"
git config --global user.email "235014707+Hackcoon@users.noreply.github.com"
git config --global init.defaultBranch main
```

(This box already sets identity via Home Manager `programs.git` — the above is for NEW machines.)

### Daily loop (aliases)

```zsh
cden
# edit...
nix-track                  # flakes ignore untracked files!
config-status; config-diff
nix-test                   # or nix-build-system
config-savem "Imperative msg"
git push
nix-switch
```

History: `config-log`, `glog`. Generations: `nix-generations`. Undo a bad commit but keep work: `gunstage`, `gstash "msg"`/`gpop`.

### New local folder → new GitHub repo

```bash
cd /path/to/project
git init -b main
cat > .gitignore <<'EOG'
result
result-*
*.bak*
*.tar.gz
node_modules/
dist/
build/
.env
EOG
git add -A && git commit -m "Initial commit"
gh repo create REPO-NAME --private --source=. --push
git push -u origin main
```

### Before first PUBLIC push (secrets + junk check)

```bash
cden
grep -rniE "password|api[_-]?key|secret|token|BEGIN.*PRIVATE" --exclude-dir=.git --exclude=flake.lock . | head
git ls-files | grep -E "^(result|.*\.bak|.*\.tar\.gz)$"
# if found: git rm --cached result config-backup-*.tar.gz <file>.bak
# ensure .gitignore has: result, result-*, *.bak*, *.tar.gz, hardware-configuration.nix
config-savem "Cleanup before public push"
```

Safe to publish: `hardware-configuration.nix` UUIDs (everyone publishes these — but keep it git-ignored anyway), `flake.lock` (pins versions — good). NEVER publish: API keys in `settings`/`environment` (use sops-nix/agenix `environmentFiles`), `/var/lib/searx/searx.env`, `/etc/secureboot` keys (move via USB, never git).

### New machine: clone down

```bash
gh repo clone Hackcoon/goat-nix /etc/nixos   # or: git clone https://github.com/Hackcoon/goat-nix.git
cd /etc/nixos
# generate hardware-configuration.nix, uncomment its import, then:
sudo nixos-rebuild switch --flake .#nixos
```

---

## 19. Troubleshooting

| Symptom | Cause | Fix |
|---|---|---|
| `Path X is not tracked by Git` on rebuild | New file not staged; flakes only see tracked files | `nix-track` before every rebuild |
| `Invalid username or token. Password auth not supported` | `sudo git push` (root has no token) or typed password not token | Push WITHOUT sudo; `gh auth login` (no sudo) + `gh auth setup-git` |
| `src refspec master does not match any` | Local branch is `main`, pushed `master` | `git branch -a`, then `git push -u origin main` |
| `Failed to start transient service unit` on dry-activate | Ran rebuild without sudo / non-interactive | Use `nix-test` (with sudo) or `nixos-rebuild build` |
| Black screen at boot after GPU/BusID change | Wrong PRIME BusIDs | Boot previous generation, re-run `lspci`, fix hex→dec IDs, rebuild |
| Bar shows NO workspaces (DMS) | MangoWC 0.12.8 (stable) lacks new IPC | Must use unstable/0.17.0 override (`mango-dms.nix`) |
| DMS runs in KDE/Hyprland too | Wrong systemd target | Must be `mango-session.target`, not `graphical-session.target` |
| Binds don't apply | Config error | `mango -p -c ~/.config/mango/config.conf` shows it; mango keeps last-good |
| Greeter conflict / black login | Two display managers own the seat | dms-greeter (greetd) XOR SDDM — `kde.nix` auto-disables SDDM when greeter is on |
| High-refresh panel glitches in greeter | 144Hz greeter bug | Greeter capped 1080p60 in `mango-dms.nix` — leave it |
| Brave fix "didn't work" | Old Brave process still running | `pkill -f 'opt/brave'` first, then relaunch |
| `navigator.gpu` null / SwiftShader | WebGPU on CPU fallback | Use `bwg` build; check `brave://gpu` + `requestAdapterInfo()` |
| Firefox logged out after rebuild | Dedicated-profile-per-install | `MOZ_LEGACY_PROFILES=1` is set — verify `about:policies`; still logged out = site-side expiry |
| No screen share / frozen file picker | Wrong portal backend | Check `portals.nix` routing per session; Flatpak needs portals running |
| AppImage `libXXX.so` missing | Minimal appimage-run | Uncomment ONLY that lib in `appimage.nix` `extraPkgs` |
| Wi-Fi drops / SSH stalls on battery | Wi-Fi powersave | `services.tlp.settings.WIFI_PWR_ON_BAT = "off"` |
| Mouse stutters on battery | USB autosuspend | `services.tlp.settings.USB_AUTOSUSPEND = 0` (performance mode already 0) |
| Dolphin/drkonqi light-grey in Mango/Hyprland | Empty xsettings GTK theme (DMS matugen reset) | Fixed via `kdedefaults/kdeglobals` in `themes.nix` — don't delete that block |
| Vesktop/upscayl/sioyek broken on Wayland | Need X11 ozone / xcb | Fixed wrappers in `apps-fixed.nix` — never add the raw pkgs alongside |
| Hotel/captive-portal Wi-Fi broken | DoT ignores portal DNS | Flip `dns.provider = "native"`, rebuild (or temporarily), flip back after |

General recovery ladder: `nix-test` failure → read error → fix → `nix-track` → retry. Bad switch → `nix-rollback` (or boot-menu previous generation) → fix → `nix-switch`. Still broken → `git log`/`config-diff` to find the offending commit → revert it.

---

## 20. Re-enable later: Secure Boot, qylock, Btrfs

### Secure Boot (lanzaboote)

1. `sbctl create-keys && sbctl enroll-keys --microsoft` (keys → `/etc/secureboot`, never git).
2. Check: `sb-status`, `sb-verify`.
3. Uncomment lanzaboote input + `inputs.nixpkgs.follows` in `flake.nix`, module in outputs, `boot.lanzaboote` block in `modules/core/boot.nix`; `mkForce false` the systemd-boot enable. Rebuild.

### qylock (SDDM/Quickshell lockscreen themes)

Uncomment qylock input + `follows` in `flake.nix`, module wiring in outputs, import in `configuration.nix` (`modules/desktop/qylock.nix`). Note: SDDM is currently auto-off under dms-greeter — decide which login screen owns the seat first.

### Btrfs root (opt-in, currently ext4)

Cannot convert in place — backup → reformat with `@/@home/@nix/@snapshots` subvolumes → `nixos-install --flake ...#nixos` with `btrfs-root.enable = true` + `declarativeFilesystems = true` → restore. Full steps + snapper usage (`snapper -c home list`, `undochange`) in `modules/system/btrfs.nix` header.

Other dormant switches: `ai-services.nix` (Ollama CUDA + open-webui + Hermes — secrets via sops-nix/agenix `environmentFiles`), `desktop-extras` options (plymouth, openrgb, logitech, sane, nfs, ly-greeter…), optional `scx_lavd` scheduler (`ssd.nix`), Syncthing user service (`system-packages.nix`).

---

## Appendix A: verification checklist

Run after install or any big update:

```bash
nvidia-smi                                  # dGPU driver alive
glxinfo | grep -i nvidia                    # GL on NVIDIA
vulkaninfo | head; vkcube                   # Vulkan per GPU
dmesg | grep -E 'amdgpu|nvidia'             # both GPUs probed
resolvectl status                           # DNS provider + DoT active
upower -d; acpi -b                          # battery backend
systemctl --failed                          # no failed services
systemctl --user status dms dsearch kanshi  # user services (in Mango session)
flatpak list                                # sandboxed apps
fwupdmgr get-devices                        # firmware visibility
# Firefox: about:policies (session restore, no clear-on-exit, en-US)
# Brave WebGPU: brave://gpu → Vulkan Enabled, WebGPU HW; DevTools requestAdapter != swiftshader
```

---

## Appendix B: file index

| Path | What |
|---|---|
| `configuration.nix` | Entry point + machine switches (PRIME, DNS, power, extras, Btrfs) |
| `flake.nix` / `flake.lock` | Inputs + `nixosConfigurations.nixos` + `unstablePkgs` + HM wiring |
| `home.nix` | HM user config (git, kitty, btop, dsearch, kanshi, YouTube launcher) |
| `MANUAL.md` | This handbook |
| `modules/core/boot.nix` | systemd-boot, stable kernel, amd_pstate + deep-sleep flags |
| `modules/core/nix.nix` | Flakes, caches/CUDA, `nh clean` weekly GC, nix-ld |
| `modules/core/locale.nix` | Asia/Dubai, en_US, es console keys |
| `modules/core/network.nix` | Hostname, NetworkManager, SSH, Wireshark |
| `modules/core/dns.nix` | DoT provider switch (quad9/cloudflare/google/native) |
| `modules/core/default-apps.nix` | System mime defaults + sioyek dark config |
| `modules/hardware/hardware-profiles.nix` | Portable mkDefault profiles (nvidia/PRIME/amdgpu/intel/vm/clock) |
| `modules/hardware/laptop.nix` | TLP on, upower, libinput, wifi/BT, sleep, PRIME power tuning |
| `modules/hardware/power-modes.nix` | powersave/balanced/performance TLP tables + 80% cap |
| `modules/hardware/nvidia.nix` | Desktop-only discrete NVIDIA (gated — hybrids skip) |
| `modules/hardware/audio.nix` | PipeWire stack + BlueZ |
| `modules/hardware/ssd.nix` | tmpfs /tmp, zram, fstrim, journal cap, sleep fix |
| `modules/hardware/razer.nix` | OpenRazer + Polychromatic |
| `modules/desktop/kde.nix` | Plasma 6, X11/XWayland, es XKB, SDDM (auto-off under greetd) |
| `modules/desktop/hyprland.nix` | Hyprland + launchers, quickshell, bar, screenshots, media |
| `modules/desktop/mango-dms.nix` | MangoWC 0.17.0 + DMS 1.6 + dms-greeter + mango portals |
| `modules/desktop/fonts.nix` | JetBrainsMono NF default + Noto/Arabic/CJK/emoji |
| `modules/desktop/themes.nix` | Cursor/GTK pins + kdeglobals GTK fix |
| `modules/desktop/portals.nix` | Per-session portal backends |
| `modules/programs/shell.nix` | zsh + OMZ + ALL aliases + direnv |
| `modules/programs/gaming.nix` | Steam/Proton-GE, GameMode, Gamescope, controllers |
| `modules/programs/firefox.nix` | Stay-logged-in policies + pywalfox host |
| `modules/programs/appimage.nix` | binfmt + packaging recipe |
| `modules/programs/virtualisation.nix` | libvirt/KVM + virt-manager + Podman |
| `modules/programs/thunar.nix` | Thunar + gvfs/tumbler/xfconf |
| `modules/services/printing.nix` | CUPS |
| `modules/services/flatpak.nix` | Flatpak daemon |
| `modules/system/desktop-extras.nix` | Optional toggles (zram/fstrim on, rest off) |
| `modules/system/btrfs.nix` | Opt-in Btrfs + snapper + scrub |
| `modules/users/users.nix` | User `goat` + groups |
| `modules/packages/system-packages.nix` | The big package list (commented per entry) |
| `modules/packages/brave-webgpu.nix` | Separate WebGPU Brave build |
| `modules/packages/apps-fixed.nix` | X11/xcb wrappers (sioyek/upscayl/vesktop) |
| `docs/daily-loop.md` | 6-step cheat sheet |
| `docs/github-workflow.md` | GitHub + secrets + error table |
| `docs/brave-fix-nixOS.md` | WebGPU root-cause deep dive |
| `dotfiles/mango/*` | MangoWC/DMS user config + hotkeys + setup guide |

---

*End of manual. Keep it with the config: edit `MANUAL.md` when the system changes, commit it like code.*
