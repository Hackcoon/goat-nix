# Realtek RTL8111 Energy Efficient Ethernet disconnect workaround.
#
# EEE causes intermittent link renegotiation disconnects on this
# board. This oneshot service runs after NetworkManager so the
# interface has initialized before ethtool changes its settings.
#
# DESKTOP-ONLY: enp5s0 is the desktop's NIC name — on the laptop this
# unit fails harmlessly every boot, which is why configuration.nix does
# NOT import this module for goat (see the NOTE there). Re-enable only
# if `ip link` shows enp5s0 AND `dmesg | grep r8169` shows link flaps.
{ config, pkgs, lib, ... }:

{
  systemd.services."disable-realtek-eee" = {
    description =
      "Disable Energy Efficient Ethernet on the Realtek Ethernet interface";

    wantedBy = [ "multi-user.target" ];   # start during normal boot
    after = [ "NetworkManager.service" ];  # wait until the NIC exists...
    wants = [ "NetworkManager.service" ];  # ...and pull NM up if not started yet

    serviceConfig = {
      Type = "oneshot";            # run once during boot
      RemainAfterExit = true;      # complete after success
      ExecStart =
        "${pkgs.ethtool}/bin/ethtool --set-eee enp5s0 eee off";  # EEE off = NIC never sleeps the link (costs ~0.5W, kills the flaps)
    };
  };
}
