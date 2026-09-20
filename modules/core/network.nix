# Networking: hostname, NetworkManager, SSH, Wireshark.
#
# This is the base network layer. Encrypted DNS lives separately in
# modules/core/dns.nix (systemd-resolved + DoT provider switch) — see
# that file if lookups misbehave. Wi-Fi powersave + MAC randomization
# live in modules/hardware/laptop.nix (laptop-only tuning).
{ config, pkgs, lib, ... }:

{
  # Machine name on the LAN (shows in router client lists, `hostname`,
  # SSH prompts). laptop.nix mkForces this to "ronny-nix" when enabled
  # so the laptop copy is distinguishable from the desktop install.
  networking.hostName = "nixos";

  # NetworkManager owns ALL connections (Ethernet + Wi-Fi + VPN).
  # Use `nmtui` (terminal) or the KDE/Mango applet — never edit
  # /etc/wpa_supplicant.conf by hand, NM will overwrite it.
  networking.networkmanager.enable = true;

  # SSH server for remote login / file copy (`ssh goat@<ip>`).
  # Key-only auth is NOT enforced here — add openssh.settings if exposed
  # to the internet.
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
