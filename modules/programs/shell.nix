# Zsh + Oh My Zsh + aliases + direnv. The whole terminal experience.
#
# LAYERS (all three active at once):
#   - programs.zsh + ohMyZsh: system-wide zsh, completion, theme, plugins.
#     STAYS SYSTEM-LEVEL (not home.nix): single-user machine, and admin
#     recovery aliases must work even if Home Manager breaks.
#   - shellAliases below: the alias catalog (~100 entries: eza/bat/fd
#     replacements, nix rebuild shortcuts, git helpers). First place to
#     look when a terminal command "does something weird".
#   - programs.direnv + nix-direnv: per-project dev shells — entering a
#     directory with .envrc auto-loads its flake/nix shell.
{ config, pkgs, lib, ... }:

{
  programs.zsh = {
    enable = true;

    # Links /share/zsh (all package completions) into fpath and
    # installs nix-zsh-completions. Setting false breaks completions.
    enableCompletion = true;

    # Removes ONLY the duplicate compinit call from /etc/zshrc —
    # Oh My Zsh runs its own compinit anyway.
    enableGlobalCompInit = false;

    # Flat option (NOT history = { ... }) — sets both HISTSIZE and
    # SAVEHIST to 10000 commands. histFile already defaults to
    # ~/.zsh_history, so history persists across sessions.
    histSize = 10000;

    autosuggestions.enable = true;      # gray suggestions from history
    syntaxHighlighting.enable = true;   # red invalid, green valid

    ohMyZsh = {
      enable = true;
      theme = "af-magic";   # prompt theme (git branch, exit codes, cwd)
      plugins = [
        # "git"     # git aliases (gst, gco, gcmsg, gp, ...)
        "sudo"      # ESC twice = prepend sudo to current command line
        # "docker"  # tab-completion for docker commands
      ];
    };

    # Custom (non-bundled) themes like powerlevel10k go here instead
    # of theme = "...". Remember to comment out `theme` above:
    # ohMyZsh.plugins = [
    #   {
    #     name = "powerlevel10k";
    #     src = pkgs.zsh-powerlevel10k;
    #     file = "share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    #   }
    # ];

    shellAliases = {
      # ---------- Everyday commands ----------
      ls   = "eza --icons";                 # modern ls with icons
      ll   = "eza -lah --icons";            # detailed + hidden + readable sizes
      lsd  = "eza -l --icons --only-dirs";  # directories only
      cat  = "bat";                         # syntax-highlighted cat
      man  = "batman";                      # colourized manpages
      ".." = "cd ..";                       # up one directory
      duh  = "du -sh ./*";                  # size of every item in cwd
      c    = "clear";                       # clear the screen
      restart-gui = "sudo systemctl restart display-manager";
      sudo = "sudo ";                     # trailing space: aliases expand after sudo
      tree = "eza --tree --icons";        # directory tree (no real tree pkg installed)
      f = "fd";                           # fast find
      tl = "tldr";                        # cheat sheets (tealdeer client)
      mkdir = "mkdir -pv";                # verbose, no error if exists
      cp = "cp -iv";                      # confirm overwrites
      mv = "mv -iv";                      # confirm overwrites
      rm = "rm -Iv";                      # prompt once for recursive / 3+ files
      path = "echo $PATH | tr ':' '\n'";  # one dir per line
      h = "history";                      # shell history
      ports = "ss -tulpn";                # what's listening (sudo for pids)
      pubip = "curl -s https://icanhazip.com";  # public IP
      weather = "curl -s 'wttr.in?format=3'";   # one-line weather, auto-locates
      serve = "python3 -m http.server 8000";    # file server in cwd
      drives = "lsblk -f";                # disks + filesystems
      temp = "sensors";                   # CPU/GPU temps
      wifi = "nmcli device wifi list";    # nearby Wi-Fi networks
      logs-err = "journalctl -p 3 -xb";   # this boot's errors only
      flog = "journalctl -f";             # follow logs live

      # ---------- Browsers ----------
      bwg  = "brave-webgpu";              # WebGPU/Vulkan build (grainrad)

      # ---------- Quality of life ----------
      open = "xdg-open";                  # open files/URLs with default app
      sz = "exec zsh";                    # reload shell (new aliases, etc.)
      cden = "cd /etc/nixos";             # jump to NixOS config
      scu = "systemctl --user";           # user services (dms, portals…)
      scus = "systemctl --user status";   # + unit name, e.g. scus dms
      sc = "systemctl";                   # base command
      scs = "systemctl status";           # + unit, e.g. scs dms
      scstart = "sudo systemctl start";   # + unit
      scstop = "sudo systemctl stop";     # + unit
      screstart = "sudo systemctl restart"; # + unit
      screload = "sudo systemctl reload"; # + unit
      scenable = "sudo systemctl enable"; # + unit
      scdisable = "sudo systemctl disable"; # + unit
      sclogs = "journalctl -u";           # + unit, all boots, e.g. sclogs dms
      sclogsb = "journalctl -b -u";       # + unit, this boot only
      ju = "journalctl --user -b";        # user logs this boot (+ -u unit)
      dmsi = "dms ipc call";              # prefix, e.g. dmsi spotlight toggle
      pscpu = "ps aux --sort=-%cpu | head -n 12";  # top CPU hogs
      gpu = "nvidia-smi";                 # GPU status at a glance

      # ---------- NixOS rebuild commands ----------
      # Each classic command notes its nh equivalent below (nh-os etc.).
      # nix-test: temporarily activate WITHOUT making it the permanent
      # boot generation — use first after editing config files.
      # nh equivalent: nh-test
      nix-test = "sudo nixos-rebuild test --flake /etc/nixos#nixos";
      # nix-switch: activate permanently — use once nix-test looks good.
      # nh equivalent: nh-os
      nix-switch = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      # Short alias for a normal permanent rebuild (same as nix-switch).
      # nh equivalent: nh-os
      nix-rebuild = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      # Build the system without activating it.
      # nh equivalent: nh-build
      nix-build-system = "sudo nixos-rebuild build --flake /etc/nixos#nixos";
      # Check the system can build — changes nothing on the running system.
      # nh equivalent: nh os build /etc/nixos -n (prints actions only)
      nix-build-dry = "sudo nixos-rebuild dry-build --flake /etc/nixos#nixos";
      # Track new/modified files so flakes can see them — run before any
      # rebuild after adding files (untracked files are invisible to Nix).
      # Still needed for nh builds too (no nh equivalent).
      nix-track = "git -C /etc/nixos add -A";
      nix-boot = "sudo nixos-rebuild boot --flake /etc/nixos#nixos";  # stage for next boot, don't activate now. nh equivalent: nh-boot
      nix-search = "nix search nixpkgs";  # nix-search firefox (1st run slow). nh equivalent: nh-search
      nrun = "nix run nixpkgs#";          # try apps: nrun cowsay (no nh equivalent)
      nshell = "nix shell nixpkgs#";      # one-off env: nshell hello (no nh equivalent)
      why = "nix why-depends /run/current-system";  # why is this store path kept? (no nh equivalent)
      nix-big = "nix path-info -Sh /run/current-system | sort -k2 -h | tail -n 20";  # biggest system closures (no nh equivalent)
      da = "direnv allow";                # trust this dir's .envrc (no nh equivalent)
      nh-os = "nh os switch /etc/nixos";  # rebuild via nh helper
      nh-test = "nh os test /etc/nixos";  # test via nh helper
      nh-upgrade = "nh os switch /etc/nixos --update";  # update inputs + switch (like nix-upgrade)
      nh-up-input = "nh os switch /etc/nixos --update-input";  # + input name, e.g. nh-up-input nixpkgs
      nh-boot = "nh os boot /etc/nixos";  # stage for next boot via nh
      nh-build = "nh os build /etc/nixos";  # build only, don't activate
      nh-info = "nh os info";             # list system generations
      nh-rollback = "nh os rollback";     # roll back to previous generation
      nh-search = "nh search";            # packages/options search
      nh-clean = "nh clean all";          # nh garbage collection
      nix-gc-all = "sudo nix-collect-garbage -d";  # wipe ALL old generations (careful)

      # ---------- Flake update commands ----------
      # nix-upgrade: intentionally update flake inputs and rebuild —
      # this changes /etc/nixos/flake.lock.
      # nh equivalent: nh-upgrade
      nix-upgrade = "cd /etc/nixos && sudo nix flake update && sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      # Update flake.lock without rebuilding or activating yet.
      # No nh equivalent (nh always rebuilds with --update).
      flake-update = "cd /etc/nixos && sudo nix flake update";
      # Rebuild using the exact versions already recorded in flake.lock.
      # nh equivalent: nh-os
      nix-upgrade-locked = "sudo nixos-rebuild switch --flake /etc/nixos#nixos";
      # Check whether the flake structure and outputs are valid.
      # No nh equivalent.
      nix-check = "sudo nix flake check /etc/nixos";
      # Show the exact versions of your flake inputs.
      # No nh equivalent.
      nix-inputs = "nix flake metadata /etc/nixos";

      # ---------- Generations & rollback ----------
      # See older system versions available for rollback.
      # nh equivalent: nh-info
      nix-generations = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
      # nix-keep-10: trim the profile to the last 10 generations, GC
      # anything now-unreachable, regenerate the boot menu to match.
      nix-keep-10 = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +10 && sudo nix-collect-garbage && sudo nixos-rebuild boot --flake /etc/nixos#nixos";
      # Same as nix-keep-10 but keeps 20 — more rollback headroom.
      nix-keep-20 = "sudo nix-env --profile /nix/var/nix/profiles/system --delete-generations +20 && sudo nix-collect-garbage && sudo nixos-rebuild boot --flake /etc/nixos#nixos";
      # nix-rollback: return to the previous generation when the
      # current one causes a problem.
      # nh equivalent: nh-rollback
      nix-rollback = "sudo nixos-rebuild switch --rollback";
      # Show the system generation currently in use.
      # No nh equivalent (nh-info lists generations, not the current link).
      nix-current = "readlink /nix/var/nix/profiles/system";

      # ---------- Nix store cleanup ----------
      # nixdelete: normal cleanup — removes generations older than 30
      # days while preserving recent rollback options.
      # nh equivalent: nh-clean (broader: cleans all profiles + store)
      nixdelete = "sudo nix-collect-garbage --delete-older-than 30d";
      # Shorter alias for the same normal garbage collection.
      # nh equivalent: nh-clean
      nix-gc = "sudo nix-collect-garbage --delete-older-than 30d";
      # WARNING: removes ALL old generations — only when you're certain
      # you no longer need any rollback.
      # nh equivalent: nh-clean
      nix-delete-all-old = "sudo nix-collect-garbage --delete-old";
      # Show how much space the Nix store is using.
      # No nh equivalent.
      nix-store-size = "sudo du -sh /nix/store";
      # Manually deduplicate identical files in the Nix store.
      # No nh equivalent.
      nix-optimize = "sudo nix-store --optimise";

      # ---------- Nix file commands ----------
      # Keep formatting consistent after editing configuration.nix or
      # flake.nix. Requires nixfmt in systemPackages.
      nix-format = "sudo nixfmt /etc/nixos/configuration.nix /etc/nixos/flake.nix";

      # ---------- Configuration Git commands ----------
      # Review changes to your configuration.
      config-diff = "cd /etc/nixos && sudo git diff";
      # Show changed and untracked files.
      config-status = "cd /etc/nixos && sudo git status";
      # Show your ten most recent configuration commits.
      config-log = "cd /etc/nixos && sudo git log --oneline --decorate -10";
      # Save the current configuration in a Git commit (prompts for message).
      config-save = "cd /etc/nixos && sudo git add . && sudo git commit";
      # Save everything with an inline message: config-savem "message".
      config-savem = "cd /etc/nixos && sudo git add -A && sudo git commit -m";
      # Stage only chosen files: config-stage <paths...>, then config-commitm "message".
      config-stage = "cd /etc/nixos && sudo git add";
      config-commitm = "cd /etc/nixos && sudo git commit -m";

      # ---------- Compositor config Git commands ----------
      # MangoWC status / save (prompts for message).
      mango-status = "git -C ~/.config/mango status";
      mango-save = "git -C ~/.config/mango add -A && git -C ~/.config/mango commit";
      # dwm/suckless status / save (prompts for message).
      dwm-status = "git -C ~/.config/suckless status";
      dwm-save = "git -C ~/.config/suckless add -A && git -C ~/.config/suckless commit";
      # Hyprland status / save (prompts for message).
      hypr-status = "git -C ~/.config/hypr status";
      hypr-save = "git -C ~/.config/hypr add -A && git -C ~/.config/hypr commit";

      # ---------- Everyday Git commands (any repo) ----------
      gst = "git status --short --branch";   # compact status
      glog = "git log --oneline --graph --decorate -15";  # recent history
      gd = "git diff";                       # unstaged changes
      gds = "git diff --staged";             # staged changes
      ga = "git add -p";                     # interactive staging
      gcmsg = "git commit -m";               # commit with message arg
      gco = "git switch";                    # change/create branch
      gb = "git branch";                     # list branches
      gunstage = "git restore --staged .";   # unstage everything, keep work
      gstash = "git stash push -m";          # shelve with message arg
      gpop = "git stash pop";                # bring back last stash

      # ---------- System information ----------
      # Show system, CPU, GPU, memory, and kernel information.
      ff = "fastfetch";
      # Open an interactive resource monitor.
      bt = "btop";
      # Open the dank interactive resource monitor.
      dg = "dgop";
      # Show disk space usage.
      disks = "df -h";
      # Show memory and swap usage.
      memory = "free -h";
      # Show network interfaces and IP addresses.
      myip = "ip -brief address";
      # Show failed systemd services.
      boot-status = "systemctl --failed";
      # Show Secure Boot status.
      sb-status = "sbctl status";
      # Verify Secure Boot.
      sb-verify = "sbctl verify";
    };

    # Initialize Zsh tools when an interactive shell opens.
    # zoxide = `z` jump-to-frequent-dirs (replaces reliance on full paths).
    # fzf --zsh = fuzzy history/file completion (Ctrl-R, Ctrl-T).
    interactiveShellInit = ''
      eval "$(zoxide init zsh)"
      eval "$(fzf --zsh)"
    '';
  };

  # Automatically load per-project development environments:
  # entering a dir with .envrc auto-loads its nix shell (direnv), and
  # nix-direnv caches the environment so it starts instantly on re-entry.
  # First visit: `direnv allow` to trust the .envrc (see `da` alias).
  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };
}
