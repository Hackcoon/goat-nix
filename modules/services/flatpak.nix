# Flatpak sandboxed applications.
{ config, pkgs, lib, ... }:

{
  services.flatpak.enable = true;
}
