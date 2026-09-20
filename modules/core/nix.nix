# Nix-the-package-manager configuration: settings, caches, gc, helpers.
#
# WHAT THIS FILE OWNS:
#   - Build parallelism (cores/max-jobs) — how hard `nixos-rebuild` pushes CPU.
#   - Binary caches (substituters) + trust keys — where prebuilt binaries come from.
#   - Housekeeping: auto-optimise (dedup store), nh-based garbage collection.
#   - Compatibility shims: nix-ld (unpatched binaries), insecure-package allows.
{ config, pkgs, lib, ... }:

{
  # Full build parallelism: the 7840HS has 8c/16t, let Nix use all of it.
  # Tradeoff: heavy compiles (CUDA etc.) run hot + loud and drain battery —
  # plug in for big builds. (The old soft cap, cores=2/max-jobs=1, was to
  # keep a desktop CPU cool; wrong tradeoff for a laptop that wants speed.)
  nix.settings.cores = 0;         # 0 = all threads per build
  nix.settings.max-jobs = "auto"; # one build job per core

  nix.settings = {
    # Modern Nix commands and Flakes
    experimental-features = [ "nix-command" "flakes" ];

    # Automatically optimize the Nix store to save disk space
    auto-optimise-store = true;

    # Additional binary cache hosting pre-built CUDA packages.
    # Without this, anything built with cudaSupport = true compiles
    # from source locally (cache.nixos.org doesn't build CUDA).
    # Note: the official cache is merged in automatically alongside
    # this list — verified in your live /etc/nix/nix.conf.
    substituters = [ "https://cache.nixos-cuda.org" ];

    # Public key used to verify packages fetched from the cache above.
    trusted-public-keys = [
      "cache.nixos-cuda.org:74DUi4Ye579gUqzH4ziL9IyiJBlDpMRn9MBN8oNan9M="
    ];

    # Adds you to nix's trusted-users list: `nix profile install`,
    # `nh os switch`, and later Home Manager can operate without sudo.
    # On a single-user desktop with wheel/sudo this is a convenience,
    # not a security boundary change.
    trusted-users = [ "root" "goat" ];
  };

  # Globally enables CUDA support for packages in nixpkgs that support
  # it (blender, ffmpeg, ML libs...). Combined with the CUDA cache
  # above, those packages are fetched pre-built instead of compiled.
  nixpkgs.config.cudaSupport = true;

  # EOL Electron/pnpm versions that some apps still need. The better
  # long-term fix is finding which app pulls each one in and updating
  # that app.
  nixpkgs.config.permittedInsecurePackages = [
    "electron-40.10.5"
    "electron-39.8.10"
    "pnpm-10.29.2"
  ];

  # Automated garbage collection now runs via `nh clean` below —
  # do NOT re-enable both: each creates its own weekly GC timer
  # and they race on the store lock (nixpkgs emits a warning for
  # exactly this combination).
  # `nh clean` is a superset of nix-collect-garbage (retention by
  # count AND age, gcroot cleanup) and its timer is Persistent=true,
  # so missed weekly runs catch up after boot — nix.gc's timer
  # doesn't, so runs are simply lost when the machine is off.
  # nix.gc = {
  #   automatic = true;
  #   dates = "weekly";
  #   options = "--delete-older-than 30d";
  # };

  # nh — friendlier nixos-rebuild wrapper: `nh os switch` shows a
  # colored diff, `nh clean keep 5` prunes generations in a TUI.
  # Pointed at this flake, it uses /etc/nixos#nixos automatically.
  programs.nh = {
    enable = true;
    flake = "/etc/nixos";
    clean = {
      enable = true;      # enables the `nh clean` command
      dates = "weekly";   # weekly; timer is Persistent (catches up after downtime)

      # The ONLY garbage collector now — replaces the commented
      # nix.gc block above. Without extraArgs, nh defaults to
      # --keep 1 --keep-since 0h (current generation only!), which
      # would silently kill rollback safety. This restores the old
      # policy plus a floor:
      #   --keep-since 30d : keep everything from the last 30 days
      #                       (same as the old nix.gc options)
      #   --keep 10        : always keep at least 10 generations,
      #                       even if older (rollback floor)
      #   --keep-one       : keep one gcroot per direnv project so
      #                       active dev shells (nix-direnv in
      #                       programs/shell.nix) survive GC
      extraArgs = "--keep-since 30d --keep 10 --keep-one";
    };
  };

  # nix-ld: shim that lets *unpatched* binaries run on NixOS.
  # NixOS doesn't put libraries in /lib or /usr/lib, so downloaded
  # binaries (VS Code extensions, npm packages, AppImages, game mods)
  # fail with "No such file or directory" for ld-linux. nix-ld provides
  # that loader and resolves libs from the system. Zero cost when unused.
  programs.nix-ld.enable = true;
}
