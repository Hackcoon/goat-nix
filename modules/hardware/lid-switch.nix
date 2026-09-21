# modules/hardware/lid-switch.nix
#
# Broken hall-effect lid sensor? Ghost lid-close blanking the screen?
# This makes the lid do LITERALLY NOTHING, at every layer:
#
#   1. logind — HandleLidSwitch* = ignore (no suspend/hibernate/off,
#      whether the lid reads open or closed, on AC/battery/docked).
#   2. kernel — button.lid_init_state=open, so a stuck-closed sensor
#      can't suspend you during boot either.
#   3. libinput/compositors (MangoWC, KWin, Hyprland) — udev rule tags
#      every lid-switch input device LIBINPUT_IGNORE_DEVICE, so the
#      compositor never even receives lid open/close events. This is
#      the layer that blanks the screen even when logind is already
#      set to ignore.
#
# USE:
#   1. Add to configuration.nix imports:
#        ./modules/hardware/lid-switch.nix
#   2. Rebuild:
#        nix-track && nix-test && nix-switch
#   3. Reboot once (kernel param + udev need it; or at minimum
#        sudo udevadm trigger --subsystem-match=input --action=change)
#
# This overrides modules/hardware/laptop.nix which sets:
#   HandleLidSwitch=suspend-then-hibernate
# We use mkForce so this file ALWAYS wins regardless of import order.
#
# NOTE: deliberately closing the lid no longer suspends either.
# Sleep via power button / power menu instead. Idle suspend
# (IdleAction, 30min in laptop.nix) is untouched — time-based, not lid.
#
# PLASMA SESSIONS: PowerDevil reads the lid itself and acts on its own
# config, so ALSO set System Settings → Power Management → "When laptop
# lid closed" → Do nothing (AC + Battery + Low battery), i.e.
# lidAction=0 in every [HandleButtonEvents] section of
# ~/.config/powermanagementprofilesrc. Not managed by Home Manager on
# purpose — KDE rewrites that file, a read-only store symlink breaks it.
#
# HONEST CAVEAT: on some laptops the embedded controller cuts panel
# power on lid-close below the OS level — no software can stop that
# blanking. With everything above ignored, the worst case is a
# momentary black that recovers by itself instead of a stuck
# suspend/lock.
{ config, lib, ... }:

{
  services.logind.settings.Login = {
    HandleLidSwitch = lib.mkForce "ignore";
    HandleLidSwitchExternalPower = lib.mkForce "ignore";
    HandleLidSwitchDocked = lib.mkForce "ignore";
  };

  # Tell kernel to assume lid is open at boot.
  # Stops a stuck-closed sensor from suspending you during boot.
  boot.kernelParams = [ "button.lid_init_state=open" ];

  # Hide lid-switch devices from libinput, so MangoWC/KDE/Hyprland
  # never see lid events at all. logind opens the devices directly
  # (not via libinput), so the ignore-rules above apply independently.
  services.udev.extraRules = ''
    ACTION=="add|change", SUBSYSTEM=="input", ENV{ID_INPUT_SWITCH}=="1", ENV{LIBINPUT_IGNORE_DEVICE}="1"
  '';
}
