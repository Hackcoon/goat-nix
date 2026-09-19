# Gaming: Steam, GameMode, Gamescope, controllers, Proton helpers.
#
# Tuned for an NVIDIA-primary laptop (PRIME sync): Steam offloads nothing
# (dGPU renders everything already), GameMode + MangoHud overlay for
# monitoring, 32-bit + NVIDIA VA-API wired for Proton.
{ config, pkgs, lib, ... }:

{
  # GameMode adjusts CPU scheduling, I/O priority, and other settings
  # while a game is running
  programs.gamemode = {
    enable = true;
    # GameMode's defaults are tuned for Intel; on the 7840HS keep the
    # powersave governor (amd-pstate boosts on demand) and just pin
    # performance-adjacent knobs. Custom settings land in
    # /etc/gamemode.ini via settings below.
    settings.general.renice = 10; # bump game priority, don't starve the DE
  };
  programs.gamescope = {
    enable = true;
    # Gamescope needs real capabilities to nest/microcomposite
    capSysNice = true;
  };

  programs.steam = {
    enable = true;
    # Open firewall for Steam Remote Play / LAN streaming
    remotePlay.openFirewall = true;
    # Friends chat voice + game overlay webviews
    dedicatedServer.openFirewall = false; # NOT a server — keep closed
    extraCompatPackages = with pkgs; [
      proton-ge-bin # community Proton (newer fixes than Valve's)
    ];
  };

  # NVIDIA offload env for the rare native game that still probes the
  # wrong GPU: `steam-run` and Heroic inherit these from the session.
  environment.sessionVariables = lib.mkIf config.hardware-profiles.nvidia-prime.enable {
    # Prefer NVIDIA GL/Vulkan in PRIME (sync already does this, but
    # native SDL/Vulkan apps sometimes need the nudge).
    __NV_PRIME_RENDER_OFFLOAD = "1";
    __VK_LAYER_NV_optimus = "NVIDIA_only";
  };

  # Several Proton games crash without this
  boot.kernel.sysctl."vm.max_map_count" = 2147483647;

  # Xbox controller over Bluetooth
  hardware.xpadneo.enable = true;
  # Sony DualShock/DualSense + Nintendo Pro controllers over USB/BT
  hardware.steam-hardware.enable = true;

  # MangoHud overlay (Shift+F12 in-game): fps, frametimes, temps.
  # Package itself is installed via modules/packages/system-packages.nix —
  # no duplicate needed here.
}
