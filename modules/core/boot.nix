# Bootloader & kernel.
#
# Plain systemd-boot (Lanzaboote/Secure Boot DISABLED for goat — no keys
# enrolled on his laptop yet; see commented block below for re-enabling).
{ config, pkgs, lib, ... }:

{
  # Standard kernel from your nixos-26.05 channel (pkgs.linuxPackages).
  # Alternatives: pkgs.linuxPackages_latest, or an LTS pin.
  boot.kernelPackages = pkgs.linuxPackages;

  # Plain systemd-boot for now. When goat enrolls Secure Boot keys later:
  #   1. re-enable the lanzaboote input + module in flake.nix,
  #   2. mkForce false here again, enable boot.lanzaboote below.
  boot.loader.systemd-boot.enable = true;

  # Allow EFI variables to be modified
  boot.loader.efi.canTouchEfiVariables = true;

  # Laptop power kernel flags:
  #   amd_pstate=active — modern CPPC frequency control for Ryzen (7840HS).
  #     Lets the CPU race-to-idle properly; big battery win vs acpi-cpufreq.
  #   mem_sleep_default=deep — S3-style suspend so sleep sips instead of
  #     gulping (pairs with suspend-then-hibernate in hardware/laptop.nix).
  # NOTE (desktop leftover removed): the old `pcie_aspm=off` was a workaround
  # for a desktop RTL8111 board. It disables PCIe power saving and would
  # noticeably hurt laptop battery — do NOT re-add it here. TLP manages
  # ASPM per power source (see hardware/power-modes.nix).
  boot.kernelParams = [ "amd_pstate=active" "mem_sleep_default=deep" ];

  # Caps the boot menu to the last 20 generations so the ESP doesn't
  # fill up with entries even if you rebuild a lot in a short window.
  boot.loader.systemd-boot.configurationLimit = 20;

  # --- Secure Boot via Lanzaboote (DISABLED — re-enable after key setup) ---
  # boot.loader.systemd-boot.enable = lib.mkForce false; # lanzaboote takes over
  # boot.lanzaboote = {
  #   enable = true;
  #   pkiBundle = "/etc/secureboot"; # sbctl keys live here after enrollment
  # };
}
