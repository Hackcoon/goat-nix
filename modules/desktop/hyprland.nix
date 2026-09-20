# ============================================================================
# HYPRLAND — core compositor module
#
# This module is self-contained. It enables Hyprland, the launcher stack
# (Vicinae + rofi), and every utility your binds/scripts/waybar need.
# fury-bar (your quickshell pill-bar) is started from hyprland.lua and only
# needs `quickshell` from here.
{ config, pkgs, lib, ... }:

{
  # =========================================================================
  # HYPRLAND — the compositor
  # =========================================================================
  programs.hyprland = {
    enable = true;
    xwayland.enable = true;   # X11 apps (Steam, some games) keep working
  };

  # =========================================================================
  # EVERYTHING YOUR RICE NEEDS (one list — NixOS rejects duplicate
  # environment.systemPackages definitions in the same module)
  # =========================================================================
  environment.systemPackages = with pkgs; [
    # ---- Hyprland first-party ecosystem ----
    hyprsunset       # night light (SUPER+N toggle via Hyprsunset.sh)
    hyprpaper        # simple wallpaper (alternative to awww)
    hypridle         # idle daemon → auto-lock via hyprlock
    hyprlock         # lock screen (LockScreen.sh uses it)
    hyprpicker       # on-screen color picker
    hyprpolkitagent  # password prompts for privileged apps

    # ---- Launchers ----
    vicinae        # native launcher — SUPER+D; black/white theme at
                   # ~/.local/share/vicinae/themes/monochrome-fury.toml
    rofi           # secondary launcher — SUPER+SHIFT+D (drun/filebrowser/run/window)
    rofi-calc      # RofiCalc.sh  (modi: calc — qalculate backend)
    rofi-emoji     # Emoticon.sh  (modi: emoji)

    # ---- Quickshell: runtime for fury-bar (your main shell) ----
    quickshell     # also lets SwitchShell.sh flip to any quickshell config

    # ---- Wallpapers & bar ----
    awww           # swww fork — JaKooLit Wallpaper*.sh use it
    waybar         # status bar (WaybarStyles.sh / WaybarLayout.sh cycle it)
    wlogout        # logout menu (Wlogout.sh)
    wallust        # JaKooLit ThemeChanger.sh — global theme from wallpaper

    # ---- Notifications ----
    swaynotificationcenter   # swaync + swaync-client (SUPER SHIFT+N panel)
    libnotify                # notify-send (all your scripts use it)

    # ---- Screenshots (grim = capture, slurp = region select, satty/swappy = annotate) ----
    grim                   # Wayland screenshot capture (ScreenShot.sh backend)
    slurp                  # interactive region picker (feeds geometry to grim)
    satty          # SUPER+SHIFT+S annotator
    swappy         # ScreenShot.sh --swappy backend (JaKooLit parity)

    # ---- Audio / media / misc (used by scripts + binds + fury-bar) ----
    pamixer                # Volume.sh CLI control
    playerctl              # MediaCtrl.sh MPRIS
    brightnessctl          # backlight/brightness keys for scripts + DMS widget fallback
    pavucontrol            # graphical PulseAudio/PipeWire volume mixer (per-app levels)
    mpv                    # video player backend (RofiBeats.sh streams audio)
    jq                     # JSON parser for scripts (mmsg/dms IPC output)
    wlr-randr              # Wayland display configurator (resolution/refresh CLI)
    lm_sensors             # `sensors` temps readout (fury-bar StatsPill reads it)
    networkmanagerapplet   # nm-applet tray icon (GUI Wi-Fi picker)
    python3                # URL-encoding etc. (scripts percent-encode queries)
    xdg-utils              # xdg-open (SUPER+B browser bind)
    # rfkill: airplane-mode CLI (rfkill list/block) — provided by util-linux
    # (already in system packages), so no separate package entry needed.
    cava                   # audio visualizer backend (waybar cava_mviz + fury-bar)
    bc                     # CLI calculator (WallpaperSelect.sh / Dropterminal.sh math)
    psmisc                 # killall (Refresh.sh, WaybarStyles.sh, WallpaperEffects.sh)
    mpvpaper               # video wallpapers (WallpaperSelect.sh video branch)
  ];

  # UPower: battery/status D-Bus daemon. fury-bar's battery pill and
  # `upower -d` read from here. Harmless on desktop (no battery found).
  services.upower.enable = lib.mkDefault true;
}
