# ============================================================================
# desktop-extras.nix — optional desktop services, ported from
# LinuxBeginnings/NixOS-Hyprland hosts/nixos/config.nix. All OFF by default;
# flip what you want per host. Keeps your existing KDE/SDDM/qylock modules
# untouched — these are the extra knobs their flake ships.
{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.desktop-extras;
in
{
  options.desktop-extras = {
    # linuxbeginnings-style switches: each mkEnableOption creates a
    # `config.desktop-extras.<name>.enable` boolean (default false).
    # Flip them per host in configuration.nix — e.g.:
    #   desktop-extras = { zram.enable = true; printing.enable = true; };
    flatpak.enable      = mkEnableOption "Flatpak + flathub remote";
    zram.enable          = mkEnableOption "zram swap (no swap partition needed)";
    fstrim.enable         = mkEnableOption "weekly SSD fstrim";
    nfs.enable            = mkEnableOption "NFS server";
    printing.enable        = mkEnableOption "CUPS printing";
    sane.enable            = mkEnableOption "scanner support (sane-airscan)";
    logitech.enable        = mkEnableOption "Logitech wireless + solaar";
    openrgb.enable         = mkEnableOption "OpenRGB (RGB control)";
    plymouth.enable        = mkEnableOption "boot splash animation";
    appimage.enable        = mkEnableOption "AppImage binfmt support";
    ly-greeter.enable      = mkEnableOption "ly TUI login greeter (replaces SDDM!)";
    nh.enable              = mkEnableOption "nh — nixos-rebuild helper";
  };

  config = mkMerge [
    # ── Flatpak ──
    # Flatpak daemon + one-shot service that registers the Flathub app
    # store on first boot. Without the remote, `flatpak install` finds
    # nothing — this is the step that makes the daemon useful.
    (mkIf cfg.flatpak.enable {
      services.flatpak.enable = true;
      systemd.services.flatpak-repo = {
        path = [ pkgs.flatpak ];
        script = ''
          flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
        '';
      };
    })

    # ── zram ──
    # Compressed RAM swap: no swap partition needed, zero SSD wear,
    # faster than disk swap. 30% of RAM at priority 100 (used before any
    # disk swap). zstd = best compression-speed tradeoff.
    (mkIf cfg.zram.enable {
      zramSwap = {
        enable = true;
        priority = 100;
        memoryPercent = 30;
        swapDevices = 1;
        algorithm = "zstd";
      };
    })

    # ── SSD trim ──
    # fstrim = TRIM/discard timer (same as ssd.nix default). Duplicate here
    # so the "extras" host profile can request trimming on its own without
    # importing the SSD module.
    (mkIf cfg.fstrim.enable {
      services.fstrim = {
        enable = true;
        interval = "weekly";
      };
    })

    # ── NFS ──
    # Network File System SERVER (share local dirs to other machines).
    # rpcbind = portmapper NFS clients need to find the server.
    # Client-only mounts need neither — just mount with /etc/fstab.
    (mkIf cfg.nfs.enable {
      services.rpcbind.enable = true;
      services.nfs.server.enable = true;
    })

    # ── Printing ──
    (mkIf cfg.printing.enable {
      services.printing.enable = true;
      # drivers = [ pkgs.hplipWithPlugin ];
    })

    # ── Scanners ──
    # SANE = scanner access API. sane-airscan covers modern network
    # (eSCL/WSD/AirScan) scanners without vendor drivers. The built-in
    # escl backend conflicts with airscan, so it's disabled to avoid
    # duplicate/broken scanner entries.
    (mkIf cfg.sane.enable {
      hardware.sane = {
        enable = true;
        extraBackends = [ pkgs.sane-airscan ];
        disabledDefaultBackends = [ "escl" ];
      };
    })

    # ── Logitech ──
    # Wireless receiver support (Bolt/Unifying) + solaar GUI for pairing,
    # battery, button remapping. hardware.logitech.wireless handles the
    # udev rules so receivers work without root.
    (mkIf cfg.logitech.enable {
      # programs.solaar.enable = true;   # ⚠ solaar is an unfree pkg behind programs.solaar;
                                          # if your nixpkgs lacks the option, install pkgs.solaar instead:
      environment.systemPackages = [ pkgs.solaar ];
      hardware.logitech.wireless.enable = true;
    })

    # ── OpenRGB ──
    # Open-source RGB control (keyboards, mice, RAM, motherboard LEDs).
    # motherboard = which SMBus driver to load ("intel" or "amd") — wrong
    # value just means onboard LEDs aren't found; USB devices still work.
    (mkIf cfg.openrgb.enable {
      services.hardware.openrgb = {
        enable = true;
        motherboard = "intel";   # or "amd"
      };
    })

    # ── Plymouth boot splash ──
    # Graphical boot animation hiding kernel messages. Purely cosmetic —
    # disable if you want to see boot logs scroll by for debugging.
    (mkIf cfg.plymouth.enable {
      boot.plymouth.enable = true;
    })

    # ── AppImage support ──
    #(mkIf cfg.appimage.enable {
      #boot.binfmt.registrations.appimage = {
        #wrapInterpreterInShell = false;
        #interpreter = "${pkgs.appimage-run}/bin/appimage-run";
        #recognitionType = "magic";
        #offset = 0;
        #mask = ''\xff\xff\xff\xff\x00\x00\x00\x00\xff\xff\xff'';
        #magicOrExtension = ''\x7fELF....AI\x02'';
      #};
    #})

    # ── ly greeter — Matrix-style login screen (their theme port) ──
    # ⚠ replaces SDDM's greeter role; disable kde.nix's sddm first if you use it!
    (mkIf cfg.ly-greeter.enable {
      services.displayManager.ly = {
        enable = true;
        settings = {
          animation = "matrix";
          bigclock = true;
          bg = "0x00000000";        # black
          fg = "0x00FFFFFF";        # white (mono! — theirs was cyan/red)
          border_fg = "0x00FFFFFF";
          error_fg = "0x00FF0000";
          clock_color = "0x00FFFFFF";
        };
      };
    })

    # ── nh — friendly nixos-rebuild wrapper ──
    # nh = nicer rebuild CLI (`nh os switch` with diffs + progress).
    # clean.extraArgs auto-trims generations (--keep-since 7d --keep 5).
    # nix-output-monitor + nvd give the pretty build diff output.
    (mkIf cfg.nh.enable {
      programs.nh = {
        enable = true;
        clean = {
          enable = true;
          extraArgs = "--keep-since 7d --keep 5";
        };
        flake = "/etc/nixos";
      };
      environment.systemPackages = [ pkgs.nix-output-monitor pkgs.nvd ];
    })
  ];
}
