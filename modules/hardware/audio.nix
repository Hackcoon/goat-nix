# Audio (PipeWire) + Bluetooth (BlueZ) — one headset feature unit.
#
# STACK (top to bottom):
#   PipeWire (media graph) -> WirePlumber (session/policy manager) ->
#   ALSA (kernel sound) + PulseAudio-compat + JACK-compat shims.
# Legacy PulseAudio daemon is OFF — anything speaking Pulse goes through
# PipeWire's pulse shim instead, so there is exactly one sound server.
# rtkit lets PipeWire request realtime scheduling without running as root
# (prevents crackling under CPU load).
{ config, pkgs, lib, ... }:

{
  # Disable legacy PulseAudio in favor of PipeWire
  services.pulseaudio.enable = false;

  # Realtime Kit scheduling for optimal audio performance
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    # ALSA backend (kernel sound devices) + 32-bit compat so old games /
    # Proton / Wine (32-bit) still produce sound on a 64-bit system.
    alsa.enable = true;
    alsa.support32Bit = true;
    # PulseAudio shim: apps written for Pulse (browsers, Discord, Zoom)
    # connect to PipeWire transparently — no per-app reconfiguration.
    pulse.enable = true;
    # JACK shim: pro-audio apps (Ardour, Carla) connect without a
    # separate JACK server running.
    jack.enable = true;       # JACK application support
    # WirePlumber: the session manager that routes streams, remembers
    # default devices, and applies the bluetooth-config tweaks below.
    wireplumber.enable = true;
  };

  # BlueZ system-wide (kernel Bluetooth stack + D-Bus service).
  hardware.bluetooth = {
    enable = true;

    # Turn Bluetooth on automatically at boot
    powerOnBoot = true;

    settings = {
      General = {
        Experimental = true;   # e.g. reading headset battery levels
      };
    };
  };

  # Bluetooth audio codec tweaks, applied via the BlueZ monitor in
  # wireplumber. These only take effect for Bluetooth headsets/speakers —
  # wired and USB audio are untouched.
  services.pipewire.wireplumber.extraConfig."bluetooth-config" = {
    "monitor.bluez.properties" = {
      # SBC-XQ: higher-quality variant of the standard SBC codec
      "bluez5.enable-sbc-xq" = true;

      # mSBC: wideband speech codec for better headset mic audio
      "bluez5.enable-msbc" = true;

      # Let the device control its own hardware volume — can cause
      # volume-sync issues with some headphones, hence left off.
      # "bluez5.enable-hw-volume" = true;
    };
  };
}
