# CUPS printing.
#
# Enables the CUPS print daemon (IPP on localhost:631). Add printers via
# the KDE Print Manager or `lpadmin`. Most modern printers speak
# driverless IPP/AirPrint — no extra driver package needed. For HP models
# requiring proprietary plugins, uncomment the hplipWithPlugin line in
# system/desktop-extras.nix (printing block).
{ config, pkgs, lib, ... }:

{
  services.printing.enable = true;
}
