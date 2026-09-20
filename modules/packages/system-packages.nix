# System-wide packages. Wrapped/patched apps live in apps-fixed.nix.
# Unstable packages use unstablePkgs (from flake.nix specialArgs).
#
# CONVENTION: every entry carries an end-of-line comment saying what it
# IS, because bare nixpkgs names (dgop, gdu, solaar...) are opaque.
# Sections group by job: hardware utils first, then monitoring, desktop,
# CLI, dev, browsers, files, media, KDE extras, theming, thumbnails.
{ config, pkgs, lib, unstablePkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # === SYSTEM & HARDWARE UTILITIES ===
    sbctl                   # Secure Boot key manager
    solaar                  # Logitech device manager
    lshw                    # Hardware configuration list tool
    pciutils                # PCI bus utilities (lspci)
    usbutils                # USB device utilities (lsusb)
    smartmontools           # S.M.A.R.T. disk monitoring
    gsmartcontrol           # GUI for smartmontools
    winboat                 # Run Windows apps on Linux with seamless integration

    # === SYSTEM MONITORING ===
    topgrade                # System upgrade utility
    fastfetch               # System information fetcher
    btop                    # Command-line resource monitor
    mission-center          # GUI system resource monitor
    cpu-x                   # System profiler (CPU-Z alternative)
    hardinfo2               # Hardware analyzer and benchmark tool
    nvitop                  # Interactive NVIDIA GPU resource monitor (dGPU side)
    radeontop               # AMD GPU monitor (780M iGPU side, needs video group)
    lact                    # AMD GPU controls (fan curves, clocks, power)
    dgop                    # terminal GPU monitor (dank-flavored nvtop alternative)
    gdu                     # fast disk-usage analyzer (what's eating the SSD)

    # === WAYLAND & DESKTOP UTILITIES ===
    kitty                   # GPU-based terminal
    wl-clipboard            # wl-copy / wl-paste
    cliphist                # Clipboard history for Wayland
    flameshot               # Screenshot with annotation
    qalculate-qt            # Multi-purpose desktop calculator
    hyprcursor              # New cursor theme format
    cmatrix                 # Matrix rain in terminal

    # === CLI UTILITIES & REPLACEMENTS ===
    ripgrep                 # Faster grep (rg)
    bat-extras.batman       # man pages via bat
    zsh-completions         # Additional zsh completions
    util-linux              # System utilities (keep for batman)
    fd                      # Faster find
    bat                     # Better cat with syntax highlighting
    eza                     # Better ls with icons (works with Nerd Font)
    fzf                     # Fuzzy finder
    zoxide                  # Smarter cd
    tealdeer                # Simplified man pages
    manix                   # Fast Nix option/docs searcher
    wikiman                 # Offline manual search engine
    micro                   # Terminal text editor
    fresh-editor            # Terminal text editor / IDE
    jq                      # JSON processor
    yq                      # YAML processor

    # === DEVELOPMENT & IT TOOLS ===
    vscodium                # Open source VS Code binaries
    antigravity-fhs         # Agentic development platform
    home-manager            # home-manager CLI for nix files
    nixfmt                  # Nix formatter
    nil                     # Nix language server (mainly for fresh editor)
    nixd                    # Feature-rich Nix language server
    git                     # Version control
    gh                      # GitHub CLI (`gh repo clone`, `gh pr create` from terminal)
    gitkraken               # Git GUI (requires allowUnfree)

    # === AI TOOLS ===
    lmstudio                # Local LLM desktop app
    cherry-studio           # Multi-provider LLM desktop client
    # opencode                # AI coding agent for the terminal (stable - switched to unstable 2026-09-13)
    # opencode-desktop        # AI coding agent desktop client (stable - switched to unstable 2026-09-13)

    # === BROWSER THEMING (DMS Pywalfox path) ===
    # `pywalfox` CLI (use `update`, NEVER `install` on NixOS).
    # Manifest wiring lives in modules/programs/firefox.nix (Firefox).
    # Needs the AMO extension
    # + ln -sf ~/.cache/wal/dank-pywalfox.json ~/.cache/wal/colors.json
    pywalfox-native

    # === LANGUAGE TOOLCHAINS & COMPILERS ===
    gcc                     # C/C++ compiler
    gdb                     # C/C++ debugger
    gnumake                 # Build automation
    cmake                   # Cross-platform build generator
    go                      # Go toolchain
    rustup                  # Rust toolchain manager (rustc & cargo)
    python3                 # Python runtime
    nodejs_22               # Node.js runtime
    python3Packages.pip     # Python package installer
    lua                     # Lua interpreter
    luarocks                # Lua package manager

    # === ENVIRONMENTS & CONTAINERS ===
    distrobox               # Linux distros in containers
    bruno                   # Offline Postman alternative
    devenv                  # Per-project dev environments (pairs with flakes)

    # === NETWORK & SECURITY ===
    openssl                 # TLS toolkit (rand, certs)
    ethtool                 # Ethernet checker (also used by realtek-eee.nix)
    nmap                    # Network scanner
    dig                     # DNS lookup
    whois                   # Domain info
    traceroute              # Network path tool
    iperf3                  # Network speed testing
    remmina                 # Remote desktop client (RDP, VNC, SSH)
    kdePackages.kleopatra   # Certificate manager, GnuPG GUI
    gnupg                   # GNU Privacy Guard

    # === INTERNET & COMMUNICATION ===
    # Default Brave = smooth native build (Wayland via NIXOS_OZONE_WL hint,
    # HW video decode flags from make-brave). Only the shared password
    # store is forced, so logins survive window-manager switches.
    # WebGPU lives separately in modules/packages/brave-webgpu.nix.
    (brave.override {
      commandLineArgs = "--password-store=gnome-libsecret";
    })
    librewolf               # Privacy-focused Firefox fork
    qutebrowser             # Keyboard-driven browser (vim bindings, Super+K in mango)
    mailspring              # Email client

    # === FILE MANAGEMENT, SYNC & ARCHIVING ===
    yazi                    # Terminal file manager (SUPER+Y in mango)
    superfile               # Terminal file manager (SUPER+SHIFT+Y in mango)
    wget                    # File downloader
    curl                    # HTTP swiss army knife
    aria2                   # Multi-connection downloader
    qbittorrent             # Torrent client with GUI
    filezilla               # FTP/SFTP GUI client
    syncthing               # P2P file syncing (manual/GUI use — see
                            # commented service block below)
    localsend               # AirDrop equivalent for local network

    # Backend engines ark needs to handle all formats (without these,
    # Dolphin's Ark extracts ZIP but errors on RAR/7z).
    unzip                  # Extract ZIP archives
    unrar                  # Extract RAR archives
    p7zip                  # Extract 7z archives
    zip                    # Create ZIP archives
    gzip                   # GNU zip compression
    xz                     # XZ compression
    zstd                   # Zstandard real-time compression
    bzip2                  # Block-sorting file compressor

    # === OFFICE & PRODUCTIVITY ===
    obsidian                # Knowledge base / markdown notes
    logseq                  # Open-source obsidian
    anytype                 # Offline-first encrypted knowledge base
    appflowy                # Open-source Notion
    onlyoffice-desktopeditors  # Office suite
    pdfarranger             # Merge, split, rotate PDFs

    # === GRAPHICS & DESIGN ===
    gimp                    # Image manipulation
    inkscape                # Vector graphics editor
    krita                   # Digital painting / 2D animation
    darktable               # RAW developer / photo workflow

    # === GAMING & CHESS ===
    en-croissant            # Ultimate Chess Toolkit
    pawn-appetit            # Chess toolkit (en-croissant fork)
    prismlauncher           # Minecraft launcher
    heroic                  # GOG / Epic / Amazon Games launcher
    bottles                 # Wine prefix manager

    # Gaming performance overlay + GPU API test tools
    mangohud                # fps/frametime overlay (Shift+F12, see gaming.nix)
    vulkan-tools            # vkcube/vulkaninfo — verify Vulkan works on each GPU
    mesa-demos              # glxinfo/glxgears — verify GLX + Mesa (used in README checks)

    # Wine/Proton helpers (Windows games outside Steam)
    protontricks            # winetricks wrapper for Proton prefixes
    protonup-qt             # installs community Proton-GE builds for Steam
    winetricks              # per-game DLL/dependency installer for Wine prefixes
    wineWow64Packages.stable  # 32+64-bit Wine (runs .exe directly, non-Steam)

    # === MEDIA, AUDIO & VIDEO ===
    mpv                     # Highly configurable video player
    haruna                  # Qt/QML video player built on libmpv
    vlc                     # Versatile media player
    nomacs                  # Image viewer
    kdePackages.kdenlive    # Non-linear video editor
    ffmpeg-full             # Record / convert / stream audio+video
    mediainfo               # Media file info CLI
    mediainfo-gui           # GUI for mediainfo
    easyeffects             # Audio effects for PipeWire apps

    # === KDE EXTRAS ===
    kdePackages.sddm-kcm    # Login screen manager (configure SDDM theme/users in System Settings)
    kdePackages.kcalc       # Scientific calculator (KDE default)

    # === THEMES & CURSORS ===
    papirus-icon-theme      # Papirus-Dark icons (Dolphin, see desktop/themes.nix)
    google-cursor           # Cursor theme (provides GoogleDot-* used in
                            # desktop/themes.nix — keep in sync)
    bibata-cursors          # Modern triangular cursor (alt to GoogleDot, pick in nwg-look)
    sox                     # `play` command for event sounds (notification chimes in scripts)

    # === THUMBNAIL SUPPORT (Dolphin previews — without these, files show generic icons) ===
    kdePackages.kdegraphics-thumbnailers   # PDFs, EPS
    kdePackages.ffmpegthumbs               # videos
    kdePackages.kimageformats              # WebP, RAW, etc.
    kdePackages.kio-extras                 # network shares, extra formats
    epub-thumbnailer                       # EPub thumbnails

    # === FROM UNSTABLE (nixos-unstable via flake input) ===
    # These ride `unstablePkgs` (flake.nix specialArgs) for fresher builds
    # than stable 26.05 carries — AI tools move fast, stale = broken APIs.
    unstablePkgs.llmfit     # LLM model size finder
    unstablePkgs.opencode   # AI coding agent for the terminal (unstable = newer)
    unstablePkgs.opencode-desktop  # AI coding agent desktop client (unstable)
    unstablePkgs.lmstudio-bionic  # LM Studio Bionic — agent for open models
  ];

  # Syncthing as a user service (run at login, auto-restart) — enable
  # when you want background sync instead of launching it manually:
  # services.syncthing = {
  #   enable = true;
  #   user = "goat";
  #   openDefaultPorts = false;   # local-network syncing needs no ports
  # };
  # Check with: systemctl --user status syncthing

  # Neovim terminal editor (provides vi/vim aliases).
  # defaultEditor off while learning — micro stays the default.
  programs.neovim = {
    enable = true;
    defaultEditor = false;
  };
}
