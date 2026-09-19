# XDG desktop portals — KDE Plasma and Hyprland have native portals,
# GTK is the general fallback. The wlroots portal stays installed for
# possible future MangoWC use but is not a default for any session.
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
