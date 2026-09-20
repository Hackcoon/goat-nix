# SSD hygiene + swap + sleep fixes (NOT a "bad SSD" workaround).
#
# The SSD here is healthy — this module is standard practice for ANY SSD:
# tmpfs /tmp keeps gigabytes of throwaway build files in RAM instead of
# burning write cycles, zram gives swap without touching the disk, fstrim
# is the weekly TRIM the drive expects, and the journal cap + suspend fix
# are just correctness. Keep all of it.
#
# HIBERNATION NOTES (not currently enabled):
# The kernel hibernates into the swap device with the HIGHEST priority.
# Your zram is priority 5, so hibernation would try to hibernate into
# RAM (nonsense). If you ever want hibernation:
#   1. In hardware-configuration.nix, give the disk swap partition
#      priority 10 (swapDevices is declared there, not here):
#        swapDevices = [
#          { device = "/dev/disk/by-uuid/25c2c9f4-..."; priority = 10; }
#        ];
#   2. Keep zram below it here:  zramSwap.priority = 1;
#   3. Add to boot.kernelParams in core/boot.nix:
#        "resume=UUID=25c2c9f4-..."
#      and set boot.resumeDevice to the same UUID.
# NEVER combine hibernation with randomEncryption on disk swap —
# the key is regenerated at boot, so resume becomes impossible.
{ config, pkgs, lib, ... }:

{
  # Compiling packages / expanding archives / nixos-rebuild generates
  # gigabytes of short-lived temp files. Keeping /tmp in memory
  # eliminates millions of write cycles to disk.
  boot.tmp.useTmpfs = true;
  boot.tmp.tmpfsSize = "20%";   # 20% of RAM (scales with the machine)

  # Swap writes degrade flash storage. Offload swap to compressed
  # RAM and keep the kernel from swapping until absolutely necessary.
  # zramSwap = compressed RAM block device used as swap (no disk wear,
  # much faster than disk swap). swappiness 10 (default 60): kernel
  # avoids swapping until RAM is ~90% full — desktop stays responsive.
  zramSwap.enable = true;
  boot.kernel.sysctl."vm.swappiness" = 10;

  # Weekly TRIM for SSD health (safely maintains lifespan): tells the
  # SSD which blocks are free so its garbage collector doesn't waste
  # write cycles copying dead data. Weekly timer, runs in background.
  services.fstrim.enable = true;

  # smartd — continuous disk health monitoring (near-zero CPU, warns
  # weeks before real failure). Check alerts: journalctl -t smartd
  # services.smartd.enable = true;

  # Cap the systemd journal at 200M — logs are still written exactly
  # the same; older ones are just trimmed automatically. Without a cap,
  # /var/log/journal grows unbounded on a long-lived install.
  services.journald.extraConfig = "SystemMaxUse=200M";

  # Disable cgroup-based user session freezing during sleep —
  # prevents Wayland/Plasma crashes after resume. Upstream freezes all
  # user processes pre-sleep to speed suspend; on compositors with GPU
  # state this races and the session never thaws cleanly.
  systemd.services = {
    "systemd-suspend".environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
    "systemd-hibernate".environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
    "systemd-hybrid-sleep".environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";
  };

  # ------------------------------------------
  # Optional — scx (sched_ext userspace CPU scheduler)
  # ------------------------------------------
  # sched_ext lets CPU scheduling policy run in userspace (the
  # 6.18 kernel supports it). The "scx_lavd" policy is tuned for
  # interactive/gaming responsiveness: foreground apps and games keep
  # snappy frame pacing under heavy load instead of competing equally
  # with background compiles, backups, and browser tabs.
  #
  # HEAT NOTE: a different scheduler changes WHEN CPU work runs,
  # which can shift thermal behavior on a CPU that already runs
  # slightly warm (Ryzen 7 7840HS in a thin chassis). If enabled, compare temps with
  # `btop` before/after under the same workload. If temps or fan
  # noise go UP, comment it back out and rebuild — that's the
  # entire rollback. No package changes needed — the module
  # installs its own tooling.
  # services.scx = {
  #   enable = true;
  #   scheduler = "scx_lavd";
  # };
}
