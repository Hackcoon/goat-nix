# /etc/nixos/configuration.nix
#
# Thin entry point. All real configuration lives in ./modules/*.
# The flake (flake.nix) points nixosSystem at this file; this file
# only wires the module tree together and pins stateVersion.
#
# unstablePkgs comes from flake.nix specialArgs — modules that need
# it declare it in their argument set.

{ config, pkgs, lib, ... }:

{
  imports = [
    # --- hardware (goat's machine — generate on first install, see README) ---
    # On first install: sudo nixos-generate-config --show-hardware-config
    #   > hardware-configuration.nix
    # then uncomment the next line:
    # ./hardware-configuration.nix

    # --- core ---
    ./modules/core/boot.nix
    ./modules/core/nix.nix
    ./modules/core/locale.nix
    ./modules/core/network.nix
    ./modules/core/dns.nix
    ./modules/core/default-apps.nix

    # --- hardware ---
    ./modules/hardware/nvidia.nix
    ./modules/hardware/audio.nix
    ./modules/hardware/ssd.nix
    # NOTE: realtek-eee.nix NOT imported — desktop RTL8111 (enp5s0)
    # workaround; on this laptop it would just fail every boot.
    ./modules/hardware/razer.nix
    ./modules/hardware/laptop.nix
    ./modules/hardware/lid-switch.nix   # lid sensor ghosts "closed" -> ignore it (see module header)
    ./modules/hardware/power-modes.nix

    # --- desktop ---
    ./modules/desktop/kde.nix
    # ── Hyprland core (ALWAYS ON — works standalone) ──
    ./modules/desktop/hyprland.nix

    # ── Portable hardware profiles (LinuxBeginnings port) ──
    ./modules/hardware/hardware-profiles.nix

    # ── Optional desktop services (LinuxBeginnings port, all OFF by default) ──
    ./modules/system/desktop-extras.nix

    # ── Btrfs root (OPTIONAL — disabled by default, see modules/system/btrfs.nix) ──
    ./modules/system/btrfs.nix


    ./modules/desktop/mango-dms.nix
    # ./modules/desktop/qylock.nix   # DISABLED for goat — SDDM theme pack not needed (plain SDDM is fine)
    ./modules/desktop/fonts.nix
    ./modules/desktop/themes.nix
    ./modules/desktop/portals.nix

    # --- programs ---
    ./modules/programs/shell.nix
    ./modules/programs/gaming.nix
    ./modules/programs/appimage.nix
    ./modules/programs/virtualisation.nix
    ./modules/programs/thunar.nix
    ./modules/programs/firefox.nix
    # ./modules/programs/ai-services.nix   # DISABLED for goat — Ollama CUDA + open-webui + Hermes agent not needed

    # --- services ---
    ./modules/services/printing.nix
    ./modules/services/flatpak.nix

    # --- users & packages ---
    ./modules/users/users.nix
    ./modules/packages/system-packages.nix
    ./modules/packages/brave-webgpu.nix   # comment out to drop the WebGPU build
    ./modules/packages/apps-fixed.nix
  ];

  # ═══ YOUR HARDWARE PROFILE (this machine) — flip for other hardware ═══
  # DNS flip: "quad9" <-> "cloudflare" <-> "google" <-> "native" (defined in modules/core/dns.nix)
  # "native" = regular DHCP-provided DNS (no DoT, no forced nameservers)
  # then run: sudo nixos-rebuild switch --flake /etc/nixos#nixos
  dns.provider = "google"; # use "quad9", "cloudflare", "google", or "native"
  # --- laptop GPU: hybrid AMD iGPU (780M) + NVIDIA dGPU via PRIME SYNC ---
  # NVIDIA is the PRIMARY GPU: dGPU renders everything, 780M only displays.
  # Tradeoff: best gaming performance, dGPU always powered (worse battery).
  # Flip mode back to "offload" for battery life (iGPU desktop + nvidia-offload).
  hardware-profiles.nvidia.enable = false; # disable desktop-only discrete mode
  hardware-profiles.nvidia-prime.enable = true; # enable hybrid
  hardware-profiles.nvidia-prime.mode = "sync"; # "sync" = NVIDIA primary, "offload" = battery
  # BusIDs from goat's `lspci` (hex bus -> dec: 01:00.0 -> PCI:1:0:0, 05:00.0 -> PCI:5:0:0):
  #   NVIDIA AD107M [RTX 4060 Max-Q / Mobile] at 01:00.0
  #   AMD Phoenix1 (7840HS + 780M) at 05:00.0
  # Re-verify after hardware changes with `lspci | grep -E 'VGA|3D|Display'`.
  hardware-profiles.nvidia-prime.amdgpuBusID = "PCI:5:0:0"; # AMD iGPU (Phoenix1)
  hardware-profiles.nvidia-prime.nvidiaBusID = "PCI:1:0:0"; # NVIDIA dGPU (RTX 4060 Mobile)
  # hardware-profiles.intel.enable = true; # Intel VAAPI/video decode (Intel hybrids only)
  hardware-profiles.amdgpu.enable = true; # AMD RADV/Mesa stack (Ryzen 7840HS + Radeon 780M)
  # hardware-profiles.vm-guest.enable = true;       # QEMU/KVM guest
  # hardware-profiles.local-hw-clock.enable = true; # dual-boot w/ Windows
  # --- laptop master switch (power, touchpad, wifi, bluetooth, sleep) ---
  laptop.enable = true; # turn on modules/hardware/laptop.nix
  laptop.powerMode = "balanced"; # "powersave" = max battery, "performance" = max speed (see hardware/power-modes.nix)

  # ═══ DESKTOP EXTRAS — enable what you want, rest stay off ═══
  desktop-extras = {
    zram.enable = true;        # compressed RAM swap — good default
    fstrim.enable = true;      # weekly SSD trim
# appimage.enable = true; # DISABLED - use programs.appimage.binfmt
    # nh.enable = true;         # friendly rebuild helper (nixos-rebuild alt)
    # flatpak.enable = true;    # flathub(there is already a flatpak.nix)
    # printing.enable = true;   # CUPS
    # sane.enable = true;        # scanners
    # logitech.enable = true;    # Logitech peripherals
    # openrgb.enable = true;     # RGB control
    # plymouth.enable = true;    # boot splash
    # nfs.enable = true;         # NFS server
    # ly-greeter.enable = true;  # ⚠ Matrix login — DISABLES SDDM (kde.nix) first!
  };


  # ═══ BTRFS ROOT (disabled — ext4 in use, see modules/system/btrfs.nix) ═══
  # Migration requires reformat (cannot convert in place).
  # After migration flip enable + declarativeFilesystems to true.
  btrfs-root = {
    enable = false;
    # declarativeFilesystems = true; # set true AFTER subvolumes exist
    # rootDevice = "/dev/disk/by-label/nixos"; # match `blkid` on the real disk
    # snapshots.enable = true;  # hourly snapper snapshots of /home
    # snapshotRoot = false;     # also snapshot / (needs /.snapshots subvol)
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data were taken. Leave this at the release
  # version of your first install. Changing it will NOT upgrade.
  system.stateVersion = "26.05";
}
