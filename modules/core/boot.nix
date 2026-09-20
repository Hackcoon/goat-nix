# Bootloader & kernel.
#
# Plain systemd-boot (Lanzaboote/Secure Boot DISABLED for goat — no keys
# enrolled on his laptop yet; see commented block below for re-enabling).
# Kernel params here are LAPTOP-specific (Ryzen power + deep sleep);
# do not copy blindly to a desktop (see pcie_aspm note below).
{ config, pkgs, lib, ... }:

{
  # Standard kernel from your nixos-26.05 channel (pkgs.linuxPackages).
  # Alternatives: pkgs.linuxPackages_latest (newer hw support, less tested),
  # or an LTS pin (maximum stability). Matched to the nvidiaPackages.stable
  # driver in hardware-profiles.nix — kernel + driver upgrade together.
  boot.kernelPackages = pkgs.linuxPackages;

  # Plain systemd-boot for now. When goat enrolls Secure Boot keys later:
  #   1. re-enable the lanzaboote input + module in flake.nix,
  #   2. mkForce false here again, enable boot.lanzaboote below.
  # canTouchEfiVariables = allow writing boot entries into EFI NVRAM
  # (needed for `bootctl` / new generations to appear in firmware boot menu).
  boot.loader.systemd-boot.enable = true;

  # Allow EFI variables to be modified (lets systemd-boot register itself
  # in firmware NVRAM; without this new generations may not appear in
  # the UEFI boot menu after `nixos-rebuild boot`).
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
  # Lanzaboote REPLACES systemd-boot (both can't own the ESP at once, hence
  # mkForce false above). pkiBundle = dir where `sbctl create-keys` drops
  # the Platform/KEK/db keys after `sbctl enroll-keys --microsoft`.
  # boot.loader.systemd-boot.enable = lib.mkForce false; # lanzaboote takes over
  # boot.lanzaboote = {
  #   enable = true;
  #   pkiBundle = "/etc/secureboot"; # sbctl keys live here after enrollment
  # };
}
