# Laptop support — hybrid iGPU + NVIDIA dGPU (Intel OR AMD).
#
# Enable with: laptop.enable = true; (wired in configuration.nix)
# Pair with hardware-profiles.nvidia-prime.enable = true, plus EITHER:
#   Intel+NVIDIA: hardware-profiles.intel.enable = true (+ intelBusID)
#   AMD+NVIDIA:   hardware-profiles.amdgpu.enable = true (+ amdgpuBusID)
# e.g. Ryzen 7 7840HS + Radeon 780M + RTX dGPU.
#
# WHAT THIS DOES:
#   - Power: upower, powertop auto-tune, power-profiles-daemon OFF
#     (conflicts with TLP). All TLP AC/BAT + powersave/balanced/performance
#     tuning lives in power-modes.nix (laptop.powerMode) — don't set
#     services.tlp.settings here or you'll collide with it.
#     (+ thermald ONLY on Intel — off on AMD)
#   - NVIDIA PRIME tuning (fine-grained power in offload mode, sync flags
#     in sync mode, nvidia-settings GUI)
#   - Input: libinput touchpad (tapping, natural scroll off, disable-while-typing)
#   - Wireless: NetworkManager wifi powersave, bluetooth on, fwupd firmware
#   - Sleep: systemd suspend-then-hibernate, lid-switch handling
#   - Battery niceties: acpi tool, brightnessctl (already in hyprland.nix)
{ config, pkgs, lib, ... }:

with lib;
let
  # Shortcut so we can write cfg.enable instead of config.laptop.enable.
  cfg = config.laptop;
in
{
  # Master switch for this whole module. Off by default (mkEnableOption
  # defaults to false), so importing the file does nothing until you set
  # laptop.enable = true in configuration.nix.
  options.laptop.enable = mkEnableOption "laptop power, input and wireless tuning";

  # Everything below only applies when laptop.enable = true.
  config = mkIf cfg.enable {
    # Rename host so the laptop copy is distinguishable from the desktop.
    # network.nix sets "nixos"; mkForce overrides it here.
    networking.hostName = mkForce "ronny-nix";

    # Kernel power management + powertop auto-tuning support.
    powerManagement = {
      enable = true; # enable /sys power knobs
      powertop.enable = true; # install powertop --auto-tune service
    };

    # power-profiles-daemon conflicts with TLP (both fight over governors),
    # so force it off. GNOME/KDE enable it by default, hence mkForce.
    # TLP itself is tuned in modules/hardware/power-modes.nix
    # (laptop.powerMode) — just turn the daemon on here.
    services.power-profiles-daemon.enable = mkForce false;
    services.tlp.enable = true; # daemon on; profiles come from power-modes.nix

    # Intel thermal daemon: keeps thin Intel laptops from throttling badly.
    # Intel-only — off on AMD (Ryzen handles thermals via firmware/k10temp).
    services.thermald.enable = lib.mkDefault config.hardware-profiles.intel.enable;

    # UPower: battery status backend for bars + `upower -d`.
    # Thresholds trigger warnings and hibernate at 5 percent.
    services.upower = {
      enable = true; # battery daemon
      percentageLow = 15; # warn at 15 percent
      percentageCritical = 8; # urgent warn at 8 percent
      percentageAction = 5; # act at 5 percent
      criticalPowerAction = "Hibernate"; # hibernate instead of dying
    };

    # ACPI event daemon: handles power-button / lid / charger events.
    services.acpid.enable = true;
    # Firmware updater daemon: `fwupdmgr get-updates` for BIOS/SSD/etc.
    services.fwupd.enable = true;

    # Suspend-then-hibernate: sleep 2h on battery, then hibernate to disk.
    # Needs disk swap for hibernate (zram alone cannot hibernate).
    # Without disk swap, suspend still works, hibernate fails gracefully.
    systemd.sleep.settings.Sleep = {
      HibernateDelaySec = "2h"; # stay in light sleep 2h, then hibernate to disk
      SuspendState = "mem"; # plain RAM sleep (not standby) — lowest idle draw
    };
    # Lid + idle behavior: close lid = sleep, docked = ignore (external monitor).
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate"; # lid close on battery
      HandleLidSwitchExternalPower = "suspend"; # lid close on charger (faster wake than hibernate)
      HandleLidSwitchDocked = "ignore"; # lid close when docked (external monitor stays on)
      IdleAction = "suspend-then-hibernate"; # idle 30min = sleep
      IdleActionSec = "30min"; # idle timeout
    };

    # Touchpad tuning via libinput (works for Hyprland/KDE/Wayland).
    # tappingButtonMap "lrm": 1-finger = left, 2-finger = right,
    # 3-finger = middle click. middleEmulation: two-finger click also
    # pastes (X middle-click) for terminal workflows.
    services.libinput = {
      enable = true; # enable libinput driver
      touchpad = {
        tapping = true; # tap-to-click on
        tappingButtonMap = "lrm"; # 1/2/3 finger = left/right/middle
        naturalScrolling = false; # classic scroll direction
        disableWhileTyping = true; # avoid palm clicks while typing
        middleEmulation = true; # two-finger click = middle click
        scrollMethod = "twofinger"; # two-finger scroll
      };
    };

    # Wifi: powersave + randomized scan MAC (privacy, anti-tracking).
    # backend wpa_supplicant = standard Linux Wi-Fi stack (not iwd —
    # iwd breaks some enterprise/EAP campus networks).
    networking.networkmanager.wifi = {
      backend = "wpa_supplicant"; # standard wifi backend
      powersave = true; # save battery on wifi
      scanRandMacAddress = true; # randomize MAC when scanning
    };
    # Bluetooth: on at boot, media + audio profiles enabled.
    hardware.bluetooth = {
      enable = true; # bluetooth stack
      powerOnBoot = true; # radio on after boot
      settings.General = {
        Enable = "Source,Sink,Media,Socket"; # A2DP audio + file transfer
        Experimental = true; # battery reporting for headsets
      };
    };
    # Blueman: tray applet + pairing GUI for bluetooth.
    services.blueman.enable = true;

    # NVIDIA PRIME hybrid tuning: only applies when nvidia-prime profile is on.
    # Offload mode: fine-grained power lets the dGPU sleep at ~0W on iGPU work.
    # Sync mode (NVIDIA primary): dGPU is always on — finegrained MUST stay
    # off or the display dies. Values mirror hardware-profiles.nix (equal
    # mkDefaults merge cleanly).
    hardware.nvidia = mkIf config.hardware-profiles.nvidia-prime.enable (let
      syncMode = config.hardware-profiles.nvidia-prime.mode == "sync";
    in {
      powerManagement = {
        enable = mkDefault true; # suspend/resume VRAM handling
        finegrained = mkDefault (!syncMode); # full dGPU power-off at idle (offload only)
      };
      prime.offload.enableOffloadCmd = mkDefault (!syncMode); # `nvidia-offload <app>` wrapper
      prime.sync.enable = mkDefault syncMode;
      nvidiaSettings = mkDefault true; # nvidia-settings GUI
    });

    # iGPU video-decode drivers: cheap battery video playback.
    # Intel path only on Intel hybrids; AMD decode comes via Mesa/RADV
    # from the amdgpu profile (no extra packages needed here).
    hardware.graphics.extraPackages = lib.mkIf config.hardware-profiles.intel.enable (with pkgs; [
      intel-media-driver # Broadwell+ VAAPI decode
      vaapiIntel # older Intel VAAPI
      libvdpau-va-gl # VDPAU over VAAPI bridge
    ]);

    # Laptop helper tools on PATH.
    environment.systemPackages = with pkgs; [
      acpi # `acpi -b` battery status
      powertop # `sudo powertop --auto-tune` tunables
      brightnessctl # backlight keys (also used by hyprland.nix)
      fwupd # `fwupdmgr` firmware CLI
      pciutils # `lspci` to find PRIME BusIDs
    ];

    # Find PRIME BusIDs after install with:
    #   nix-shell -p pciutils --run "lspci | grep -E 'VGA|3D|Display'"
    # Convert 01:00.0 -> PCI:1:0:0 (hex digits to decimal! c5:00.0 -> PCI:197:0:0),
    # then set:
    #   Intel+NVIDIA: hardware-profiles.nvidia-prime.intelBusID / nvidiaBusID
    #   AMD+NVIDIA:   hardware-profiles.nvidia-prime.amdgpuBusID / nvidiaBusID
  };
}