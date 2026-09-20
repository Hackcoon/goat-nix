# XDG desktop portals — per-desktop screen-share / file-picker backends.
#
# WHAT A PORTAL IS: a D-Bus broker between sandboxed apps (Flatpak,
# browsers, Electron) and the compositor. When an app asks "share my
# screen" or "open a file picker", the portal routes that request to
# the compositor-specific backend. Wrong backend = black screenshare
# or frozen file dialogs.
#
# BACKENDS INSTALLED HERE:
#   - gtk:      generic fallback (file chooser, print, settings). Used by
#               every session as last resort via common.default.
#   - hyprland: Hyprland's screencast + global shortcuts (hyprland.default).
#   - kde:      Plasma's screencast + remote desktop (kde.default).
#   - wlr:      generic wlroots screencast. Kept installed for a future
#               MangoWC session, but NOT a default for any session here —
#               the mango routing lives in mango-dms.nix (wlr + gtk).
# KDE Plasma and Hyprland each get their native portal first, gtk second.
{ config, pkgs, lib, ... }:

{
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gtk      # GTK dialogs, file pickers, fallback
      pkgs.xdg-desktop-portal-hyprland # Hyprland screen sharing / Wayland
      pkgs.xdg-desktop-portal-wlr      # generic wlroots (future MangoWC)
      pkgs.kdePackages.xdg-desktop-portal-kde  # Plasma screen sharing
    ];
    config = {
      hyprland.default = [ "hyprland" "gtk" ];
      kde.default      = [ "kde" "gtk" ];
      xfce.default     = [ "xapp" "gtk" ];
      common.default   = [ "gtk" ];   # fallback for unidentified DEs
    };
  };

  # MangoWC session portal routing now lives in mango-dms.nix
  # (xdg.portal.config.mango.default = [ "wlr" "gtk" ]).
}
