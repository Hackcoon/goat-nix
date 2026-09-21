# modules/hardware/lid-switch.nix
#
# Broken hall-effect lid sensor? Random suspends/shutdowns?
# This COMPLETELY disables the lid switch — closing (or ghost-closing)
# the lid does nothing.
#
# USE:
#   1. Add to configuration.nix imports:
#        ./modules/hardware/lid-switch.nix
#   2. Rebuild:
#        sudo nixos-rebuild switch --flake /documents/goat-nix#nixos
#        (or /etc/nixos if that's where your flake lives)
#
# This overrides modules/hardware/laptop.nix which sets:
#   HandleLidSwitch=suspend-then-hibernate
# We use mkForce so this file ALWAYS wins regardless of import order.
{ config, lib, ... }:

{
  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkForce "ignore";
    HandleLidSwitchExternalPower = lib.mkForce "ignore";
    HandleLidSwitchDocked = lib.mkForce "ignore";
  };

  # Tell kernel to assume lid is open at boot.
  # Stops a stuck-closed sensor from suspending you during boot.
  boot.kernelParams = [ "button.lid_init_state=open" ];
}
