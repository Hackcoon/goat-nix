# DNS provider switch — encrypted DNS (DoT) via systemd-resolved + NetworkManager.
#
# WHAT THIS DOES:
#   - Forces NetworkManager to use systemd-resolved instead of pushing
#     whatever DNS the Wi-Fi hotspot / router advertises. That stops
#     captive portals and ISPs from silently redirecting your lookups.
#   - Sets `ignore-auto-dns = true` so DHCP-provided servers are ignored
#     (except in "native" mode) — your chosen provider always wins.
#   - Enables DNS-over-TLS (DoT): queries leave the machine encrypted.
#     DNSSEC stays off because strict validation breaks real domains
#     (e.g. agentrouter.org CNAMEs with no signature).
#
# SWITCHING PROVIDERS (in configuration.nix):
#   dns.provider = "quad9" | "cloudflare" | "google" | "native";
#   - quad9/cloudflare/google: encrypted DoT to that provider, with the
#     other two as fallback if the primary is unreachable.
#   - native: plain DHCP DNS, no encryption — use on networks where DoT
#     is blocked (hotels, corporate Wi-Fi) or for debugging.
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
      # Route ALL lookups through systemd-resolved (127.0.0.53 stub), so
      # per-link DNS + DoT settings below actually apply. Without this,
      # NM writes the router's servers straight into /etc/resolv.conf.
      networking.networkmanager.dns = "systemd-resolved";
      networking.networkmanager.connectionConfig = {
        # Ignore router-advertised DNS — the nameservers set per-provider
        # below always win. (Native mode mkForces these back to false.)
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
