# Razer peripherals via OpenRazer + Polychromatic frontend.
#
# OpenRazer = open-source kernel driver + daemon for Razer keyboards,
# mice, headsets (lighting, DPI, polling rate). Polychromatic =
# graphical frontend to control it (effects, per-device settings).
# `users = [ "goat" ]` grants that user access to the daemon socket —
# without it the GUI launches but can't talk to the hardware.
{ config, pkgs, lib, ... }:

{
  hardware.openrazer = {
    enable = true;
    users = [ "goat" ];
  };

  environment.systemPackages = with pkgs; [
    polychromatic
  ];
}
