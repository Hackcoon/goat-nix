# power-modes.nix — powersave / balanced / performance presets for laptops.
#
# Switch with: laptop.powerMode = "powersave" | "balanced" | "performance";
# (in configuration.nix, then rebuild). Default: "balanced".
#
# HOW IT WORKS:
#   TLP already switches AC vs BAT automatically by power source. This module
#   layers a *mode* on top: it rewrites the TLP AC/BAT tables per preset so
#   one rebuild flips the whole machine's behavior.
#
#   - powersave:   max battery. Boost off everywhere, low-power platform
#                  profile, most aggressive PCIe/USB/disk savings. Pick for
#                  lectures, flights, long days away from a charger.
#   - balanced:    the sane default. Full speed on AC (boost on), aggressive
#                  savings on battery (boost off, ASPM powersupersave).
#   - performance: max speed. Performance governor + boost on AC, platform
#                  "performance", ASPM performance. Battery drains fast —
#                  pair with the charger (and PRIME sync mode for gaming).
#
# BATTERY LONGEVITY (charge limits):
#   All modes cap charging at 80% (start 75%) via TLP thresholds. Lithium
#   batteries degrade fast when pinned at 100% — 80% roughly doubles cycle
#   life. Only works on laptops with a supported EC (ThinkPad/Legion/Dell/
#   ASUS...). Harmless no-op elsewhere. For a trip, raise it temporarily:
#     services.tlp.settings.STOP_CHARGE_THRESH_BAT0 = 100;
#
# NVIDIA NOTE (sync mode):
#   With PRIME "sync" (NVIDIA primary) the dGPU is ALWAYS powered — no CPU
#   preset can fix that; it's the cost of max fps. For true battery life,
#   flip PRIME to offload: hardware-profiles.nvidia-prime.mode = "offload".
#
# AMD NOTE (7840HS):
#   Governors stay "powersave" on battery in every mode — with amd_pstate
#   active (see core/boot.nix) the CPU still boosts when needed; "powersave"
#   just lets it clock down aggressively at idle, which is where battery
#   goes to die. Boost on/off (CPU_BOOST_*) is the real lever.
{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.laptop;
  isIntel = config.hardware-profiles.intel.enable;
in
{
  options.laptop.powerMode = mkOption {
    type = types.enum [ "powersave" "balanced" "performance" ];
    default = "balanced";
    description = "Laptop power preset: max battery, sane default, or max speed.";
  };

  config = mkIf cfg.enable (mkMerge [
    # ── Common to all modes ──
    {
      # Battery widget backend (KDE/GNOME read this). Harmless headless.
      services.upower.enable = true;

      # Kill the NMI watchdog everywhere — small idle saving, ~zero cost.
      # Charge caps for longevity (see header). BAT1 covers 2-battery laptops.
      services.tlp.settings = {
        NMI_WATCHDOG = 0;
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
        START_CHARGE_THRESH_BAT1 = 75;
        STOP_CHARGE_THRESH_BAT1 = 80;
        # WiFi cards that hate powersave drop SSH/scans — if that happens,
        # override with WIFI_PWR_ON_BAT = "off" in configuration.nix.
        WIFI_PWR_ON_BAT = "on";
      };
    }

    # ── POWERSAVE: every watt counts ──
    (mkIf (cfg.powerMode == "powersave") {
      services.tlp.settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "powersave";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_BOOST_ON_AC = 0; # no turbo even on charger — cool + quiet
        CPU_BOOST_ON_BAT = 0;
        PLATFORM_PROFILE_ON_AC = "low-power";
        PLATFORM_PROFILE_ON_BAT = "low-power";
        PCIE_ASPM_ON_AC = "powersave";
        PCIE_ASPM_ON_BAT = "powersupersave"; # deepest link power saving
        RADEON_POWER_PROFILE_ON_AC = "low";
        RADEON_POWER_PROFILE_ON_BAT = "low";
        RADEON_DPM_STATE_ON_AC = "battery";
        RADEON_DPM_STATE_ON_BAT = "battery";
        WIFI_PWR_ON_AC = "on";
        SOUND_POWER_SAVE_ON_AC = 1;
        SOUND_POWER_SAVE_ON_BAT = 1;
        DISK_APM_LEVEL_ON_AC = "128";
        DISK_APM_LEVEL_ON_BAT = "128";
        SATA_LINKPWR_ON_AC = "med_power_with_dipm";
        SATA_LINKPWR_ON_BAT = "min_power";
        RUNTIME_PM_ON_AC = "auto";
        RUNTIME_PM_ON_BAT = "auto";
        USB_AUTOSUSPEND = 1;
      } // optionalAttrs isIntel {
        CPU_HWP_DYN_BOOST_ON_AC = 0;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;
      };
    })

    # ── BALANCED: fast on AC, frugal on battery (default) ──
    (mkIf (cfg.powerMode == "balanced") {
      services.tlp.settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "powersave"; # amd-pstate scales via EPP; boost does the work
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
        CPU_BOOST_ON_AC = 1; # full turbo when plugged in
        CPU_BOOST_ON_BAT = 0; # no turbo unplugged — biggest battery lever
        PLATFORM_PROFILE_ON_AC = "balanced";
        PLATFORM_PROFILE_ON_BAT = "low-power";
        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";
        RADEON_POWER_PROFILE_ON_AC = "auto";
        RADEON_POWER_PROFILE_ON_BAT = "low";
        RADEON_DPM_STATE_ON_AC = "balanced";
        RADEON_DPM_STATE_ON_BAT = "battery";
        WIFI_PWR_ON_AC = "off"; # full wifi speed on charger
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 1;
        DISK_APM_LEVEL_ON_AC = "254"; # max perf on charger
        DISK_APM_LEVEL_ON_BAT = "128";
        SATA_LINKPWR_ON_AC = "med_power_with_dipm";
        SATA_LINKPWR_ON_BAT = "min_power";
        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";
        USB_AUTOSUSPEND = 1; # set 0 if the mouse stutters on battery
      } // optionalAttrs isIntel {
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;
      };
    })

    # ── PERFORMANCE: wall power go brrr ──
    (mkIf (cfg.powerMode == "performance") {
      services.tlp.settings = {
        CPU_SCALING_GOVERNOR_ON_AC = "performance";
        CPU_SCALING_GOVERNOR_ON_BAT = "powersave"; # still clock down at idle unplugged
        CPU_BOOST_ON_AC = 1;
        CPU_BOOST_ON_BAT = 1; # turbo even on battery — drains fast, your call
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "balanced";
        PCIE_ASPM_ON_AC = "performance";
        PCIE_ASPM_ON_BAT = "powersave";
        RADEON_POWER_PROFILE_ON_AC = "high";
        RADEON_POWER_PROFILE_ON_BAT = "auto";
        RADEON_DPM_STATE_ON_AC = "performance";
        RADEON_DPM_STATE_ON_BAT = "balanced";
        WIFI_PWR_ON_AC = "off";
        SOUND_POWER_SAVE_ON_AC = 0;
        SOUND_POWER_SAVE_ON_BAT = 0;
        DISK_APM_LEVEL_ON_AC = "254";
        DISK_APM_LEVEL_ON_BAT = "254";
        SATA_LINKPWR_ON_AC = "max_performance";
        SATA_LINKPWR_ON_BAT = "med_power_with_dipm";
        RUNTIME_PM_ON_AC = "on";
        RUNTIME_PM_ON_BAT = "auto";
        USB_AUTOSUSPEND = 0; # no USB latency for gaming mice/controllers
      } // optionalAttrs isIntel {
        CPU_HWP_DYN_BOOST_ON_AC = 1;
        CPU_HWP_DYN_BOOST_ON_BAT = 1;
      };
    })
  ]);
}
