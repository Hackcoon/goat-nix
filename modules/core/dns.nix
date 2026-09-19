{ config, pkgs, lib, ... }:
with lib;
let
  cfg = config.dns;
in
{
  options.dns.provider = mkOption {
    type = types.enum [ "quad9" "cloudflare" "google" "native" ];
    default = "quad9";
    description = "DNS provider selection. Use native for regular DHCP-provided DNS (no DoT, no forced nameservers).";
  };
  config = mkMerge [
    {
      networking.networkmanager.dns = "systemd-resolved";
      networking.networkmanager.connectionConfig = {
        "ipv4.ignore-auto-dns" = true;
        "ipv6.ignore-auto-dns" = true;
      };
      services.resolved = {
        enable = true;
        settings.Resolve = {
          DNSOverTLS = "true";
          # DNSSEC=no: DoT encryption stays, authenticity validation off.
          # allow-downgrade broke unsigned domains (agentrouter.org -> Alibaba CNAME, no-signature).
          # Re-enable ("allow-downgrade") for stricter validation if you don't need those domains.
          DNSSEC = "no";
        };
      };
    }
    (mkIf (cfg.provider == "quad9") {
      networking.nameservers = [
        "9.9.9.9#dns.quad9.net"
        "149.112.112.112#dns.quad9.net"
      ];
      services.resolved.settings.Resolve.FallbackDNS = [ "1.1.1.1" "1.0.0.1" ];
    })
    (mkIf (cfg.provider == "cloudflare") {
      networking.nameservers = [
        "1.1.1.1#cloudflare-dns.com"
        "1.0.0.1#cloudflare-dns.com"
      ];
      services.resolved.settings.Resolve.FallbackDNS = [ "9.9.9.9" "149.112.112.112" ];
    })
    (mkIf (cfg.provider == "google") {
      networking.nameservers = [
        "8.8.8.8#dns.google"
        "8.8.4.4#dns.google"
      ];
      services.resolved.settings.Resolve.FallbackDNS = [ "1.1.1.1" "9.9.9.9" ];
    })
    (mkIf (cfg.provider == "native") {
      # Regular DNS: use DHCP-provided servers, no DoT, no forced nameservers.
      networking.nameservers = mkForce [ ];
      networking.networkmanager.connectionConfig = {
        "ipv4.ignore-auto-dns" = mkForce false;
        "ipv6.ignore-auto-dns" = mkForce false;
      };
      services.resolved.settings.Resolve = {
        DNSOverTLS = mkForce "no";
        FallbackDNS = mkForce [ ];
      };
    })
  ];
}
