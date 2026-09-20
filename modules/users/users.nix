# Users, groups, default shell.
#
# Single-user machine: one human account ("goat") + system services.
# GROUP CHEAT SHEET (why each exists):
#   - wheel          = sudo access. Without this, `sudo` says "not in sudoers".
#   - networkmanager = edit Wi-Fi/VPN connections without a root password.
#   - libvirtd       = create/start VMs in virt-manager (else "access denied"
#                      on /run/libvirt/libvirt-sock).
#   - wireshark      = capture packets without sudo (pairs with
#                      programs.wireshark in core/network.nix).
# `packages` here are user-profile extras (kate editor) — the bulk of apps
# live in modules/packages/system-packages.nix instead.
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
