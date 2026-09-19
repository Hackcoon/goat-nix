# NVIDIA proprietary driver — DESKTOP discrete-only (e.g. TU116 card).
#
# Gated behind hardware-profiles.nvidia.enable so AMD+NVIDIA hybrid laptops
# (Ryzen 7840HS + 780M + RTX) never pick up these desktop-only settings.
# Hybrids get their NVIDIA config from modules/hardware/hardware-profiles.nix
# (nvidia-prime block) + modules/hardware/laptop.nix (finegrained power).
{ config, pkgs, lib, ... }:

with lib;
{
  config = mkIf config.hardware-profiles.nvidia.enable {
  # Required for the proprietary NVIDIA driver
  nixpkgs.config.allowUnfree = true;

  # Load the proprietary NVIDIA driver for both X11 and Wayland
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    # Saves VRAM contents to disk before sleep and restores on wake —
    # prevents KWin/Plasma from losing display buffers and crashing
    # on resume.
    powerManagement.enable = true;

    # Kernel Mode Setting — required for proper display mode
    # restoration on wake and mandatory for Wayland compositors.
    modesetting.enable = true;

    open = false;            # proprietary userspace (best for TU116)
    nvidiaSettings = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  environment.sessionVariables = {
    # Direct GLX apps to NVIDIA driver
    __GLX_VENDOR_LIBRARY_NAME = "nvidia";

    # Hardware acceleration — keep disabled for now (breaks vesktop).
    # LIBVA_DRIVER_NAME = "nvidia";

    # Forces Electron/Chromium apps native Wayland — breaks upscayl
    # and vesktop, which is why packages/apps-fixed.nix wraps them
    # back to X11.
    # NIXOS_OZONE_WL = "1";
  };

  # OpenGL/graphics support, including 32-bit for gaming
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    # vulkan-loader: Brave (and other Chromium browsers with the Vulkan
    # feature) needs libvulkan.so.1 at runtime. make-brave.nix only adds
    # the ICD search path (XDG_DATA_DIRS), not the loader itself, so we
    # provide it via the driver runpath.
    extraPackages = [ pkgs.vulkan-loader ];
    };
  }; # <- closes mkIf config.hardware-profiles.nvidia.enable
}
