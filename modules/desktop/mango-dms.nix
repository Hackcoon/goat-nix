# MangoWC (Wayland compositor) + DankMaterialShell 1.6 (dms)
#
# One desktop module wiring the full MangoWC + DMS stack, per the DMS
# NixOS documentation (danklinux.com/docs/dankmaterialshell/nixos):
#
#  - programs.dank-material-shell — upstream DMS 1.6 module (flake
#    input `dms`, pinned v1.6.0; the old nixpkgs programs.dms-shell
#    module is 1.4.6 and used a different option name). Its user
#    service is bound to a dedicated mango-session.target so DMS
#    only runs inside MangoWC sessions and never alongside
#    KDE/Hyprland/xfce (multi-DE machine).
#  - programs.mangowc    — installs the compositor + `mango` session
#    entry for SDDM (mango.desktop).
#  - programs.dms-greeter — Dank greetd login screen (dank-greeter
#    repo, standalone since DMS 1.6). SDDM is DISABLED in kde.nix
#    side-by-side test below — see the greeter section.
#
# The DMS MangoWC integration docs cover the ~/.config/mango side:
# systemd session target, keybinds, layer/window rules, dms fragments.
# That config is NOT Nix-managed (hot-reloadable by mango itself).
#
# mango-session.target is a drop-in created at
# ~/.config/systemd/user/mango-session.target; mango's exec-once lines
# start it (see ~/.config/mango/config.conf).
{ config, pkgs, lib, unstablePkgs, ... }:

{
  # =========================================================================
  # 1) MANGOWC — the compositor
  # =========================================================================
  # IMPORTANT: DMS 1.6.0's mango integration (bar workspaces/tags, layout
  # awareness, Settings → Compositor) talks to the MANGO_INSTANCE_SIGNATURE
  # IPC socket, which mango only gained in 0.14.0 ("feat: new ipc impl").
  # Stable nixpkgs (26.05) ships 0.12.8 — too old: DMS's MangoService stays
  # disconnected and the dankbar shows NO workspaces. nixos-unstable has
  # 0.16.3, so the module overrides the package with the unstable one.
  programs.mangowc = {
    enable = true;
    # 0.17.0 (2026-09-12 milestone) — not yet in nixpkgs-unstable (still
    # 0.16.3 as of 2026-09-13), so build from upstream tag. Same meson
    # deps (wlroots-0.20, scenefx-0.5), only version+src overridden.
    # TODO: drop overrideAttrs once `unstablePkgs.mangowc.version == "0.17.0"`,
    # then revert to plain `package = unstablePkgs.mangowc;`.
    # Breaking changes checked 2026-09-15: config has no tablet_map_to_mon /
    # touch_map_to_mon (use devicerule if needed).
    package = unstablePkgs.mangowc.overrideAttrs (old: {
      version = "0.17.0";
      src = unstablePkgs.fetchFromGitHub {
        owner = "mangowm";
        repo = "mango";
        tag = "0.17.0";
        hash = "sha256-YbAqwLYaQosrr+NI195BS93w3Fp347ZsmiP97ymwDjM=";
      };
    });
    # package = unstablePkgs.mangowc;   # 0.16.3 — new IPC, DMS-compatible
    # package = pkgs.mangowc;        # stable 0.12.8 — no DMS bar support
  };

  # =========================================================================
  # 2) DANK MATERIAL SHELL 1.6 — the desktop shell
  # =========================================================================
  programs.dank-material-shell = {
    enable = true;
    systemd = {
      enable = true;
      # Bind DMS to the mango session target (created in ~/.config/
      # systemd/user/mango-session.target) instead of graphical-session.
      # DMS then starts when MangoWC starts and stops when it exits.
      target = "mango-session.target";
    };
  };

  # =========================================================================
  # 3) DANK GREETER — greetd login screen (DMS aesthetic)
  # =========================================================================
  # Standalone as of DMS 1.6. Requires greetd; enabling greetd here
  # conflicts with SDDM (only one display manager can own the seat),
  # so SDDM is disabled in kde.nix when the greeter is enabled here.
  # Lockscreen NOTE: the greeter is the *login* screen. In-session
  # locking is DMS's own Lock module (fury-bar calls it via dms CLI);
  # hyprlock/kscreenlocker remain available for Hyprland/KDE sessions.
  programs.dms-greeter = {
    enable = true;
    # Copy goat's DMS config (settings.json, session.json with wallpaperPath,
    # dms-colors.json) into /var/lib/dms-greeter at greetd start so the login
    # screen uses the same wallpaper/theme as the desktop instead of defaults.
    configHome = "/home/goat";
    # Hyprland renders the greeter (it's in our nixpkgs and the
    # machine already runs it — no extra compositor pulled in).
    # NOTE: module expects lowercase "hyprland".
    compositor.name = "hyprland";
    # Cap the greeter at 1080p60: high-refresh panels can glitch at 144Hz (half
    # screen cut off). NOTE: customConfig REPLACES the greeter's default
    # Hyprland config (which is only misc.disable_hyprland_logo), so keep
    # that line. Empty monitor name = applies to all outputs.
    compositor.customConfig = ''
      misc {
          disable_hyprland_logo = true
      }

      monitor=,1920x1080@60,auto,1
    '';
  };

  # greetd owns the seat now; SDDM must be off (done in kde.nix via
  # a mkForce false when dms-greeter.enable is true).

  # =========================================================================
  # 4) SESSION — pick Mango in greetd's session list
  # =========================================================================
  # programs.mangowc already registers the wayland session; nothing extra.

  # =========================================================================
  # 5) EXTRAS — utils DMS/MangoWC expect on PATH
  # =========================================================================
  environment.systemPackages = with pkgs; [
    wl-clipboard               # clipboard + cliphist store (DMS clipboard history)
    cliphist
    pamixer                    # DMS audio widget fallback CLI
    brightnessctl              # DMS brightness widget fallback CLI
    networkmanagerapplet        # fallback tray applet
    wofi                       # xdg-desktop-portal-wlr screencast chooser
    wmenu                      # xdg-desktop-portal-wlr screencast chooser (alt)
  ];

  # =========================================================================
  # 6) PORTAL — screen sharing / file pickers for the mango session
  # =========================================================================
  # wlroots portal already installed in portals.nix; route the mango
  # (DesktopNames=mango;wlroots) session to it. mkForce overrides the
  # nixpkgs mangowc module's plain "gtk" default — wlr implements the
  # ScreenCast interface for wlroots compositors, gtk stays the fallback
  # for file pickers.
  xdg.portal.config.mango.default = lib.mkForce [ "wlr" "gtk" ];

  # UPower: battery status tile (DMS reads UPower over D-Bus).
  # upower.enable is default true when power-profiles-daemon is enabled
  # (dms-shell module enables it via mkDefault) — nothing to add here.
}
