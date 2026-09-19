# Realtek RTL8111 Energy Efficient Ethernet disconnect workaround.
#
# EEE causes intermittent link renegotiation disconnects on this
# board. This oneshot service runs after NetworkManager so the
# interface has initialized before ethtool changes its settings.
{ config, pkgs, lib, ... }:

{
  systemd.services."disable-realtek-eee" = {
    description =
      "Disable Energy Efficient Ethernet on the Realtek Ethernet interface";

    wantedBy = [ "multi-user.target" ];
    after = [ "NetworkManager.service" ];
    wants = [ "NetworkManager.service" ];

    serviceConfig = {
      Type = "oneshot";            # run once during boot
      RemainAfterExit = true;      # complete after success
      ExecStart =
        "${pkgs.ethtool}/bin/ethtool --set-eee enp5s0 eee off";
    };
  };
}
