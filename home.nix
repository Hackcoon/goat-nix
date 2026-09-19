# Home Manager configuration for user "goat".
#
# This is the NixOS-integrated variant (no standalone `home-manager`
# switch needed — changes apply via nixos-rebuild). The flake wires
# this file in via:
#
#     home-manager.users.goat = import ./home.nix;
#
# MANAGED HERE (user-level things):
#   - git identity + delta pager
#   - EDITOR/VISUAL (vscodium)
#   - kitty terminal (font, pure black bg, scrollback)
#   - btop (imported from the previous hand-managed btop.conf)
#
# DELIBERATELY STILL SYSTEM-LEVEL:
#   - zsh, aliases, oh-my-zsh, zoxide/fzf init (modules/programs/shell.nix)
#     — single-user machine; moving them gains nothing and couples
#     recovery of admin aliases to HM working.
#   - default applications + sioyek dark-mode config
#     (modules/core/default-apps.nix) — KDE apps atomically rewrite
#     ~/.config/mimeapps.list, which de-symlinks any HM-managed
#     user-level file and collides with backups on activation;
#     /etc/xdg (system level) is never touched by user apps, and
#     sioyek reads its prefs from every XDG_CONFIG_DIRS path.
#
# DELIBERATELY NOT MANAGED:
#   - user apps in home.packages (single user — no benefit yet)
#   - vscodium settings.json (app rewrites it at runtime)
#   - okular's okularpartrc (app rewrites it on exit)
#   - app data dirs (obsidian/anytype/opencode own their state)
#   - secrets of any kind (see modules/programs/ai-services.nix
#     header for the sops-nix/agenix pattern)
#
# FLAKE INPUT MODULES: dsearch (danksearch) is passed
# in via home-manager.extraSpecialArgs in flake.nix — see the blocks
# at the bottom of this file.
{ config, pkgs, lib, dsearch, ... }:

{
  home.username = "goat";
  home.homeDirectory = "/home/goat";
  # Matches system.stateVersion — do not change.
  home.stateVersion = "26.05";

  # Let HM manage itself inside your user profile.
  programs.home-manager.enable = true;

  # ----------------------------------------------------------------
  # Editor (vscodium)
  # ----------------------------------------------------------------
  # --wait: CLI integrations (git commit, sudoedit, gh) block until
  # you close the editor window, instead of committing immediately.
  home.sessionVariables = {
    EDITOR = "codium --wait";
    VISUAL = "codium --wait";
  };

  # ~/.local/bin on PATH (nixos-doctor symlink lives here).
  home.sessionPath = [ "$HOME/.local/bin" ];

  # ----------------------------------------------------------------
  # XDG + web apps (Brave --app launchers)
  # ----------------------------------------------------------------
  # Main Brave profile (extensions, logins). Isolated per-app
  # profiles would lose both — see guides/web-apps-on-nixos.md.
  xdg.enable = true;

  xdg.desktopEntries.youtube = {
    name = "YouTube";
    exec = "brave --app=https://www.youtube.com --class=YouTube";
    icon = "/home/goat/.local/share/icons/youtube.svg";
    terminal = false;
    categories = [ "AudioVideo" "Video" ];
    settings.StartupWMClass = "YouTube";
  };

  # ----------------------------------------------------------------
  # git (identity + settings) and delta (nicer diffs)
  # ----------------------------------------------------------------
  programs.git = {
    enable = true;

    settings = {
      user.name  = "furynix";
      user.email = "235014707+Hackcoon@users.noreply.github.com";

      init.defaultBranch = "main";
      pull.rebase = false;
      push.autoSetupRemote = true;
      diff.colorMoved = "default";
    };
  };

  # On HM 26.05 this is a top-level option (not programs.git.delta).
  # It wires itself into git automatically (interactive diff/pager).
  programs.delta = {
    enable = true;
    enableGitIntegration = true;
  };

  # ----------------------------------------------------------------
  # kitty terminal
  # ----------------------------------------------------------------
  # Previously ~/.config/kitty/ was EMPTY (100% defaults), so this
  # is a pure upgrade, not a takeover. Font matches the system
  # default monospace (fonts.nix); background forced pure black.
  programs.kitty = {
    enable = true;

    font = {
      # name = "JetBrainsMono Nerd Font";
      name = "Google Sans Code";
      size = 11.0;
    };

    # Dark theme as the color base; individual settings below
    # override its background to pure black. (Valid themeFile names:
    # `ls $(nix build --print-out-paths --no-link nixpkgs#kitty-themes)/share/kitty-themes/themes/`)
    themeFile = "Catppuccin-Mocha";

    settings = {
      background = "#000000";          # pure black (your requirement)
      scrollback_lines = 100000;        # generous history
      confirm_os_window_close = 0;      # don't nag on close
      enable_audio_bell = false;        # no beeps
      copy_on_select = "clipboard";     # selection → clipboard
      strip_trailing_space = "smart";  # clean copy/paste
    };

    # shell integration gives cwd-following + jump marks in zsh
    shellIntegration.enableZshIntegration = true;
  };

  # ----------------------------------------------------------------
  # btop (imported as-is from the previous hand-managed btop.conf)
  # ----------------------------------------------------------------
  # Every non-default value from ~/.config/btop/btop.conf on
  # 2026-09-06. Your custom ~/.config/btop/themes/ directory is NOT
  # managed by HM and stays untouched. btop normally rewrites its
  # conf on exit (save_config_on_exit) — under HM the file is a
  # read-only store symlink, so runtime tweaks live in memory for
  # the session only. Make tweaks permanent by editing here.
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "Default";
      theme_background = true;
      truecolor = true;
      force_tty = false;

      # Layout & drawing
      rounded_corners = true;
      graph_symbol = "braille";
      shown_boxes = "cpu mem net proc";
      update_ms = 2000;

      # Process list
      proc_sorting = "cpu lazy";
      proc_reversed = false;
      proc_tree = false;
      proc_colors = true;
      proc_gradient = true;
      proc_per_core = false;
      proc_mem_bytes = true;
      proc_cpu_graphs = true;
      proc_info_smaps = false;
      proc_left = false;
      proc_filter_kernel = false;
      proc_follow_detailed = true;
      proc_aggregate = false;
      keep_dead_proc_usage = false;

      # CPU box
      cpu_graph_upper = "Auto";
      cpu_graph_lower = "Auto";
      show_gpu_info = "Auto";
      cpu_invert_lower = true;
      cpu_single_graph = false;
      cpu_bottom = false;
      show_cpu_watts = true;
      check_temp = true;
      cpu_sensor = "Auto";
      show_coretemp = true;
      temp_scale = "celsius";
      show_cpu_freq = true;
      freq_mode = "first";

      # Memory / disks
      mem_graphs = true;
      mem_below_net = false;
      zfs_arc_cached = true;
      show_swap = true;
      swap_disk = true;
      show_disks = true;
      only_physical = true;
      use_fstab = true;
      show_io_stat = true;
      io_mode = false;
      io_graph_combined = false;

      # Network
      net_download = 100;
      net_upload = 100;
      net_auto = true;
      net_sync = true;
      base_10_bitrate = "Auto";

      # Misc
      show_battery = true;
      show_battery_watts = true;
      selected_battery = "Auto";
      clock_format = "%X";
      show_uptime = true;
      background_update = true;
      vim_keys = false;
      disable_mouse = false;
      terminal_sync = true;
      log_level = "WARNING";
      save_config_on_exit = true;
      gpu_mirror_graph = true;
      nvml_measure_pcie_speeds = true;
      rsmi_measure_pcie_speeds = true;
      shown_gpus = "nvidia amd intel apple";
    };
  };

  # ----------------------------------------------------------------
  # dsearch (danksearch) — indexed fuzzy filesystem search
  # ----------------------------------------------------------------
  # Flake input module (github:AvengeMedia/danksearch). Runs a user
  # service (`systemctl --user status dsearch`) that indexes files
  # and serves queries via the `dsearch` CLI:
  #
  #   dsearch search "leblanc"        # fuzzy filename search
  #   dsearch search "config" --json  # scripting output
  #
  # Index paths/exclusions can be set via `programs.dsearch.config`
  # (TOML); leaving it null lets dsearch generate runtime defaults.
  # NOTE: Nix lists are whitespace-separated — NO commas here. Do NOT
  # add a trailing comma after `dsearch.homeModules.default` below: the
  # Nix parser rejects `.default,` (grammar quirk) and eval will fail.
  imports = [
    # dsearch (github:AvengeMedia/danksearch) — indexed fuzzy file search.
    # Runs a user service (`systemctl --user status dsearch`) that indexes
    # files and serves queries via the `dsearch` CLI:
    #
    #   dsearch search "leblanc"        # fuzzy filename search
    #   dsearch search "config" --json  # scripting output
    dsearch.homeModules.default
  ];
  programs.dsearch = {
    enable = true;
    # Example (defaults are fine to start):
    # config = { paths = [ "/home/goat" ]; };
  };
}
