# Audio (PipeWire) + Bluetooth (BlueZ) — one headset feature unit.
{ config, pkgs, lib, ... }:

{
  # Disable legacy PulseAudio in favor of PipeWire
  services.pulseaudio.enable = false;

  # Realtime Kit scheduling for optimal audio performance
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;       # JACK application support
    wireplumber.enable = true;
  };

  # BlueZ system-wide
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
  # wireplumber
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
