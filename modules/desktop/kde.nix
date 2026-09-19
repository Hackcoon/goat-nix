# KDE Plasma 6 + display manager + power profiles.
#
# Display manager: when the Dank greetd greeter is enabled
# (mango-dms.nix → programs.dms-greeter), greetd owns the seat and
# SDDM MUST be off — NixOS errors if two display managers claim the
# same seat. Plasma sessions remain selectable from the greeter's
# session list (greetd reads wayland-sessions/desktop entries).
{ config, pkgs, lib, ... }:

{
  # X11 windowing base — needed by XWayland apps and the XFCE session
  services.xserver.enable = true;

  # X11 keyboard layout (also drives the SDDM login screen + KDE):
  # Spanish physical keyboard, English system language (locale.nix stays
  # en_US — layout is which key is where, locale is which language apps use).
  services.xserver.xkb = {
    layout = "es";
    variant = "";
  };

  # SDDM display manager — Wayland greeter so Qt6 themes render
  # correctly (required by the qylock themes).
  #
  # Automatically disabled when the Dank greeter (greetd) takes over
  # the seat — see mango-dms.nix programs.dms-greeter.
  services.displayManager.sddm.enable = !config.programs.dms-greeter.enable;
  services.displayManager.sddm.wayland.enable = !config.programs.dms-greeter.enable;

  # Plasma 6 desktop
  services.desktopManager.plasma6.enable = true;

  # power-profiles-daemon stays OFF: laptop.nix force-disables it because
  # TLP owns the governors (the two fight otherwise). KDE's battery widget
  # still works via UPower.

  # XWayland support for legacy apps under Wayland
  programs.xwayland.enable = true;
}
