# Users, groups, default shell.
{ config, pkgs, lib, ... }:

{
  users.users."goat" = {
    isNormalUser = true;
    description = "Goat";
    extraGroups = [
      "networkmanager"  # manage network connections without a password prompt
      "wheel"           # sudo access
      "libvirtd"        # access VMs in virt-manager without "access denied"
      "wireshark"       # packet capture without sudo — programs.wireshark is
                        # enabled in core/network.nix; this group membership
                        # was missing in the old config (fix #3)
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Default shell (zsh itself is configured in programs/shell.nix)
  users.defaultUserShell = pkgs.zsh;
}
