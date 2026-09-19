# btrfs-root.nix — Btrfs root filesystem support for ronny-nix.
#
# STATUS: opt-in. Imported but DISABLED by default (btrfs-root.enable = false).
# The current install is ext4 (see hardware-configuration.nix). Btrfs cannot
# be converted in place — back up, reformat, restore. Steps in MIGRATION below.
#
# WHY BTRFS OVER ZFS HERE:
#   - In-kernel (no DKMS/out-of-tree builds, no kernel-version lag, no hostId).
#   - Snapshots + compression + scrub cover the laptop use case (rollback a
#     bad rebuild, save SSD space, detect bitrot).
#   - ZFS's strengths (ARC cache tuning, send/recv fleets, dedup) matter on
#     servers/desktops, not on a single-NVMe laptop.
#
# MIGRATION (single NVMe, UEFI, keep existing /boot ESP):
#   1. BACKUP /home externally. Record: lsblk -f, blkid, hardware-configuration.nix
#   2. Boot NixOS installer USB. Partition (KEEP ESP!):
#        mkfs.btrfs -L nixos /dev/nvme0n1pX
#        mount /dev/nvme0n1pX /mnt
#        btrfs subvolume create /mnt/@ && btrfs subvolume create /mnt/@home
#        btrfs subvolume create /mnt/@nix && btrfs subvolume create /mnt/@snapshots
#        umount /mnt
#        mount -o subvol=@,compress=zstd,noatime,ssd,space_cache=v2 /dev/nvme0n1pX /mnt
#        mkdir -p /mnt/{home,nix,.snapshots,boot}
#        mount -o subvol=@home,compress=zstd,noatime /dev/nvme0n1pX /mnt/home
#        mount -o subvol=@nix,compress=zstd,noatime /dev/nvme0n1pX /mnt/nix
#        mount -o subvol=@snapshots /dev/nvme0n1pX /mnt/.snapshots
#        mount /dev/nvme0n1pY /mnt/boot   # the existing ESP, do NOT reformat
#   3. nixos-install --flake /path/to/ronny-nix#nixos with
#      btrfs-root.enable = true (+ declarativeFilesystems = true)
#   4. After first boot: `sudo snapper -c home list` should show timeline
#      snapshots appearing hourly.
#
# ROLLBACK USAGE:
#   list:      sudo snapper -c home list
#   undo file: sudo snapper -c home undochange <N>..<M> -- /home/user/file
{ config, pkgs, lib, ... }:

with lib;
let
  cfg = config.btrfs-root;
  # Shared mount options for SSD/NVMe subvolumes.
  ssdOpts = [ "compress=zstd" "noatime" "ssd" "space_cache=v2" ];
in
{
  options.btrfs-root = {
    enable = mkEnableOption "Btrfs root support (mount opts, scrub, snapper snapshots)";

    declarativeFilesystems = mkOption {
      type = types.bool;
      default = false;
      description = "Mount / + /home + /nix from subvolumes. Set true AFTER the filesystem exists (post-migration).";
    };

    rootDevice = mkOption {
      type = types.str;
      default = "/dev/disk/by-label/nixos";
      description = "Btrfs device (by-label or by-uuid). Must exist before enabling declarativeFilesystems.";
    };

    scrubInterval = mkOption {
      type = types.str;
      default = "monthly";
      description = "systemd calendar interval for btrfs scrub (bitrot check).";
    };

    snapshots.enable = mkOption {
      type = types.bool;
      default = true;
      description = "Hourly snapper timeline snapshots of /home (and / if snapshotRoot).";
    };

    snapshotRoot = mkOption {
      type = types.bool;
      default = false;
      description = "Also snapshot / (root subvolume). Needs /.snapshots subvolume. /nix excluded (reproducible store).";
    };
  };

  config = mkMerge [
    (mkIf cfg.enable {
      boot.supportedFilesystems = [ "btrfs" ];

      # Userspace tools for manual snapshot/scrub work.
      environment.systemPackages = with pkgs; [ btrfs-progs snapper ];

      # Scrub: reads everything, verifies checksums. Single disk detects +
      # reports bitrot (can't self-heal without a mirror — still worth it).
      services.btrfs.autoScrub = {
        enable = true;
        interval = cfg.scrubInterval;
        fileSystems = [ "/" ];
      };
    })

    # --- declarative mounts (enable post-migration) ---
    (mkIf (cfg.enable && cfg.declarativeFilesystems) {
      fileSystems."/" = {
        device = cfg.rootDevice;
        fsType = "btrfs";
        options = [ "subvol=@" ] ++ ssdOpts;
      };
      fileSystems."/home" = {
        device = cfg.rootDevice;
        fsType = "btrfs";
        options = [ "subvol=@home" ] ++ ssdOpts;
      };
      fileSystems."/nix" = {
        device = cfg.rootDevice;
        fsType = "btrfs";
        options = [ "subvol=@nix" "compress=zstd" "noatime" ];
        neededForBoot = true; # /nix holds the store — mount before stage 2
      };
      # ESP stays vfat — do NOT convert /boot to Btrfs.
    })

    # --- snapper timeline snapshots ---
    (mkIf (cfg.enable && cfg.snapshots.enable) {
      services.snapper = {
        snapshotInterval = "hourly";
        cleanupInterval = "daily";
        persistentTimer = true; # catch up missed snapshots after sleep
        configs = {
          home = {
            SUBVOLUME = "/home";
            TIMELINE_CREATE = true;
            TIMELINE_CLEANUP = true;
            TIMELINE_LIMIT_HOURLY = 24;
            TIMELINE_LIMIT_DAILY = 7;
            TIMELINE_LIMIT_WEEKLY = 4;
            TIMELINE_LIMIT_MONTHLY = 3;
            TIMELINE_LIMIT_YEARLY = 0;
          };
        } // optionalAttrs cfg.snapshotRoot {
          root = {
            SUBVOLUME = "/";
            TIMELINE_CREATE = true;
            TIMELINE_CLEANUP = true;
            TIMELINE_LIMIT_HOURLY = 12;
            TIMELINE_LIMIT_DAILY = 7;
            TIMELINE_LIMIT_WEEKLY = 2;
            TIMELINE_LIMIT_MONTHLY = 0;
            TIMELINE_LIMIT_YEARLY = 0;
          };
        };
      };
    })
  ];
}

