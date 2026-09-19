# Networking: NetworkManager, SSH, Wireshark.
{ config, pkgs, lib, ... }:

{
  networking.hostName = "nixos";

  # Enable NetworkManager for wired and wireless connections
  networking.networkmanager.enable = true;

  services.openssh.enable = true;

  # Packet capture without sudo — requires the user to be in the
  # `wireshark` group (done in modules/users/users.nix; this was a
  # missing piece in the old config).
  programs.wireshark.enable = true;

  # OLD DNS BLOCK (moved to modules/core/dns.nix — kept for rollback):
  # networking.networkmanager.dns = "systemd-resolved";
  # networking.networkmanager.connectionConfig = {
  #   "ipv4.ignore-auto-dns" = true;
  #   "ipv6.ignore-auto-dns" = true;
  # };
  # networking.nameservers = [
  #   "9.9.9.9#dns.quad9.net"
  #   "149.112.112.112#dns.quad9.net"
  # ];
  # services.resolved = {
  #   enable = true;
  #   settings.Resolve = {
  #     DNSOverTLS = "true";
  #     DNSSEC = "allow-downgrade";
  #     FallbackDNS = [ "1.1.1.1" "1.0.0.1" ];
  #   };
  # };
}
