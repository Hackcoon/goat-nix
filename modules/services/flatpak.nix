# Flatpak sandboxed applications.
#
# Enables the Flatpak daemon (apps install per-user into ~/.local/share/
# flatpak or system-wide via `flatpak install flathub <app>`). Sandboxed
# apps get portal-mediated access (see desktop/portals.nix) instead of
# full filesystem rights. The Flathub remote itself is added by the
# desktop-extras.flatpak option — if `flatpak search` finds nothing,
# enable that option (or run the remote-add manually once).
{ config, pkgs, lib, ... }:

{
  services.flatpak.enable = true;
}
