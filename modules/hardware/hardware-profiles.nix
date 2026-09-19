# ============================================================================
# hardware-profiles.nix — PORTABLE hardware toggles for multi-machine NixOS
# Ported from LinuxBeginnings/NixOS-Hyprland (hosts/*/config.nix driver block)
#
# DESIGN: everything here is lib.mkDefault — profiles are DEFAULTS. Your
# existing tuned modules (e.g. modules/hardware/nvidia.nix) always win.
# Safe to enable a profile alongside a dedicated module without conflicts.
{ config, pkgs, lib, ... }:

with lib;
{
  # ───────────────────────── options ─────────────────────────
  options.hardware-profiles = {
    nvidia.enable       = mkEnableOption "NVIDIA proprietary driver";
    nvidia-prime = {
      enable      = mkEnableOption "NVIDIA PRIME (laptop hybrid graphics)";
      mode = mkOption {
        type = types.enum [ "offload" "sync" ];
        default = "offload";
        description = ''
          PRIME mode. "offload": iGPU renders the desktop, dGPU sleeps until
          `nvidia-offload <app>` (best battery). "sync": NVIDIA dGPU renders
          everything, iGPU only displays (best performance, dGPU always on,
          worse battery — pick this when NVIDIA is the primary/gaming GPU).
        '';
      };
      intelBusID  = mkOption { type = types.str; default = "PCI:0:2:0"; description = "Intel iGPU BusID (Intel+NVIDIA hybrids)"; };
      amdgpuBusID = mkOption { type = types.str; default = "PCI:0:2:0"; description = "AMD iGPU BusID (AMD+NVIDIA hybrids, e.g. Ryzen 7840HS + Radeon 780M). Find with `lspci`, convert c5:00.0 -> PCI:197:0:0 (hex->dec)."; };
      nvidiaBusID = mkOption { type = types.str; default = "PCI:1:0:0"; };
    };
    amdgpu.enable       = mkEnableOption "AMD GPU (amdgpu kernel driver)";
    intel.enable        = mkEnableOption "Intel integrated graphics";
    vm-guest.enable     = mkEnableOption "VM guest services (QEMU/KVM boxes)";
    local-hw-clock.enable = mkEnableOption "Local RTC clock (dual-boot machines)";
  };

  # ───────────────────────── implementations (all mkDefault) ─────────────────
  config = mkMerge [
    # ── NVIDIA (your desktop) ──
    (mkIf config.hardware-profiles.nvidia.enable {
      services.xserver.videoDrivers = mkDefault [ "nvidia" ];
      hardware.nvidia = {
        modesetting.enable = mkDefault true;
        powerManagement.enable = mkDefault true;
        open = mkDefault false;              # set true for 50xx-series cards
        nvidiaSettings = mkDefault true;
        package = mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
      };
      hardware.graphics.enable = mkDefault true;
      environment.sessionVariables = {
        LIBVA_DRIVER_NAME = mkDefault "nvidia";
        __GLX_VENDOR_LIBRARY_NAME = mkDefault "nvidia";
      };
    })

    # ── NVIDIA PRIME (laptop: iGPU + dGPU) ──
    # Works for BOTH Intel+NVIDIA and AMD+NVIDIA hybrids. NixOS picks the
    # right BusID field automatically: amdgpuBusId wins when the amdgpu
    # profile is on, intelBusId otherwise.
    # Mode "offload" (default): iGPU renders the desktop, dGPU sleeps until
    #   `nvidia-offload <app>` — best battery.
    # Mode "sync": NVIDIA dGPU renders everything (primary GPU), iGPU only
    #   displays — best performance, dGPU always powered, worse battery.
    #   Required flags: videoDrivers=[ "nvidia" ], sync.enable=true,
    #   finegrained power MUST be off (dGPU never sleeps in sync mode).
    (mkIf config.hardware-profiles.nvidia-prime.enable (let
      syncMode = config.hardware-profiles.nvidia-prime.mode == "sync";
    in {
      services.xserver.videoDrivers = mkDefault (
        if syncMode then [ "nvidia" ]
        else if config.hardware-profiles.amdgpu.enable then [ "amdgpu" "nvidia" ]
        else [ "nvidia" ]
      );
      hardware.graphics.enable = mkDefault true;
      nixpkgs.config.allowUnfree = mkDefault true; # NVIDIA userland is unfree
      hardware.nvidia = {
        modesetting.enable = mkDefault true;
        # PROPRIETARY-FIRST: closed kernel modules for the whole stack.
        # Rationale: on a gaming-first PRIME-sync laptop, the proprietary
        # modules are still the safer pick (fewer GSP/resume quirks, full
        # nvidia-settings/power controls). 40-series runs great closed;
        # 50-series Blackwell CAN run closed for graphics/gaming (open is
        # only mandatory for datacenter cards). If a future driver works
        # better open, flip per-machine: hardware.nvidia.open = true.
        open = mkDefault false;
        # `stable` tracks the tested driver branch — fewer surprises than
        # `latest` on a machine that must Just Boot for its owner.
        # Per-machine escape hatch if a newer driver is ever needed:
        #   hardware.nvidia.package = config.boot.kernelPackages.nvidiaPackages.latest;
        package = mkDefault config.boot.kernelPackages.nvidiaPackages.stable;
        powerManagement = {
          enable = mkDefault true;
          # Sync mode keeps the dGPU powered always — finegrained MUST be
          # off or the display dies. Offload mode may power it down.
          finegrained = mkDefault (!syncMode);
        };
        prime = {
          offload = {
            enable = mkDefault (!syncMode);
            enableOffloadCmd = mkDefault (!syncMode);   # `nvidia-offload <app>`
          };
          # Sync mode: dGPU renders, iGPU displays.
          sync.enable = mkDefault syncMode;
          # AMD+NVIDIA hybrid (e.g. Ryzen 7840HS + 780M): ignored otherwise.
          amdgpuBusId = mkIf config.hardware-profiles.amdgpu.enable
            (mkDefault config.hardware-profiles.nvidia-prime.amdgpuBusID);
          # Intel+NVIDIA hybrid: ignored when amdgpu profile is on.
          intelBusId = mkIf (!config.hardware-profiles.amdgpu.enable)
            (mkDefault config.hardware-profiles.nvidia-prime.intelBusID);
          nvidiaBusId = mkDefault config.hardware-profiles.nvidia-prime.nvidiaBusID;
        };
      };
    }))

    # ── AMD GPU (iGPU/APU like Ryzen 7840HS + Radeon 780M, or discrete) ──
    # Provides the RADV Vulkan + Mesa VAAPI stack, microcode, and firmware
    # for the AMD side. In "offload" PRIME mode the AMD chip renders the
    # desktop and the dGPU sleeps; in "sync" mode (NVIDIA primary) the
    # AMD chip only displays while NVIDIA renders everything.
    (mkIf config.hardware-profiles.amdgpu.enable {
      boot.initrd.kernelModules = [ "amdgpu" ]; # early KMS, avoids flicker
      hardware.enableRedistributableFirmware = mkDefault true; # 780M RDNA3 fw
      hardware.cpu.amd.updateMicrocode = mkDefault config.hardware.enableRedistributableFirmware;
      services.lact.enable = mkDefault true; # daemon for `lact` AMD control GUI
      hardware.graphics = {
        enable = mkDefault true;
        enable32Bit = mkDefault true; # Steam/Proton need 32-bit RADV
        extraPackages = with pkgs; [
          mesa                  # RADV Vulkan + Mesa VAAPI (radeonsi)
          vulkan-loader         # libvulkan.so.1 for Chromium/Brave
          libvdpau-va-gl        # VDPAU-over-VAAPI bridge
          amdvlk                # optional alt Vulkan driver (RADV is default)
          rocmPackages.clr      # OpenCL/HIP compute
        ];
      };
    })

    # ── Intel iGPU ──
    (mkIf config.hardware-profiles.intel.enable {
      services.xserver.videoDrivers = mkDefault [ "modesetting" ];
      hardware.graphics = {
        enable = mkDefault true;
        extraPackages = with pkgs; [
          intel-media-driver       # Broadwell+ VAAPI
          vaapiIntel
          vaapiVdpau
          libvdpau-va-gl
        ];
      };
    })

    # ── VM guest (their vm-guest-services.nix) ──
    (mkIf config.hardware-profiles.vm-guest.enable {
      services.qemuGuest.enable = mkDefault true;
      services.spice-vdagentd.enable = mkDefault false;   # their note: breaks to 1920x1080
      services.spice-webdavd.enable = mkDefault true;
    })

    # ── Local hardware clock (dual-boot with Windows) ──
    (mkIf config.hardware-profiles.local-hw-clock.enable {
      time.hardwareClockInLocalTime = mkDefault true;
    })
  ];
}
