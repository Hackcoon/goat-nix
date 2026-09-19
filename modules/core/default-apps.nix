# Default applications (system-level) — /etc/xdg/mimeapps.list.
#
# WHY A SYSTEM MODULE, NOT HOME MANAGER:
# KDE apps periodically rewrite ~/.config/mimeapps.list (KConfig
# atomic-save replaces the file, silently discarding any symlink).
# HM-managed user-level mimeapps therefore breaks on collision or
# gets de-symlinked. /etc/xdg is never touched by user apps — this
# file is a stable, conflict-free location for defaults.
#
# XDG precedence note: a USER-level mimeapps.list OVERRIDES this
# file. ~/.config/mimeapps.list currently exists as a leftover
# (KDE-replaced copy of an old HM generation, no unique content) —
# it must be deleted so these system defaults take effect. If you
# later change a default via KDE's GUI, that choice (written to the
# user file) simply wins until you delete the file again — no
# breakage either way.
#
# Desktop-file names verified against the installed packages in
# /run/current-system/sw/share/applications/ (2026-09-06):
#   okularApplication_pdf.desktop / okularApplication_epub.desktop
#   com.brave.Browser.desktop (brave-browser.desktop is a compat
#   alias shipped in the same package) / Mailspring.desktop
{ config, pkgs, lib, ... }:

{
  xdg.mime = {
    # enable defaults to true in NixOS; explicit for clarity
    enable = true;

    # "Open with this by default" per file type / URL scheme.
    defaultApplications = {
      # PDFs + EPub: okular (changed from sioyek 2026-09-06;
      # sioyek remains in Open With lists below)
      "application/pdf" = "okularApplication_pdf.desktop";
      "application/epub+zip" = "okularApplication_epub.desktop";

      # Browser: brave
      "x-scheme-handler/http" = "com.brave.Browser.desktop";
      "x-scheme-handler/https" = "com.brave.Browser.desktop";
      "text/html" = "com.brave.Browser.desktop";

      # Mail client: mailspring
      "x-scheme-handler/mailto" = "Mailspring.desktop";

      # --- URL-scheme handlers migrated from the old hand-managed
      #     user file (kept so electron deep-links keep working) ---
      "x-scheme-handler/cherrystudio" = "cherry-studio.desktop";
      "x-scheme-handler/discord" = "vesktop.desktop";
      "x-scheme-handler/notion" = "notion-app-enhanced.desktop";
      "x-scheme-handler/obsidian" = "obsidian.desktop";
      "x-scheme-handler/opencode" = "opencode-desktop.desktop";
      "x-scheme-handler/heroic" = "com.heroicgameslauncher.hgl.desktop";
      "x-scheme-handler/lmstudio" = "lm-studio.desktop";
      "x-scheme-handler/logseq" = "Logseq.desktop";
      "x-scheme-handler/mailspring" = "Mailspring.desktop";
    };

    # "Show in the Open With menu" lists.
    addedAssociations = {
      # sioyek stays available in Open With for pdf/epub even
      # though okular is the default.
      "application/pdf" = [
        "okularApplication_pdf.desktop"
        "sioyek.desktop"
      ];
      "application/epub+zip" = [
        "okularApplication_epub.desktop"
        "sioyek.desktop"
        "onlyoffice-desktopeditors.desktop"
      ];
    };

    # Apps deliberately hidden from "Open With" for a type
    # (migrated from the old hand file).
    removedAssociations = {
      "application/epub+zip" = [
        "org.kde.ark.desktop"
        "org.prismlauncher.PrismLauncher.desktop"
      ];
    };
  };

  # ----------------------------------------------------------------
  # sioyek — dark mode, pure black (system-level, same rationale:
  # /etc/xdg is read via XDG_CONFIG_DIRS and never rewritten by the
  # app: sioyek only ever READS prefs_user.config paths; runtime
  # changes are persisted to ~/.local/share/sioyek/auto.config
  # instead — verified in sioyek source main.cpp/config.cpp).
  # ----------------------------------------------------------------
  environment.etc."xdg/sioyek/prefs_user.config".text = ''
    # Start in dark mode every launch (per sioyek's own prefs
    # comment, this supersedes the deprecated default_dark_mode).
    startup_commands    toggle_dark_mode

    # Dark-mode colors. Sioyek renders dark mode by inverting the
    # page through a shader; these two keys set the result:
    #   dark_mode_background_color 0 0 0  -> fully black
    #   dark_mode_contrast 1.0            -> pure white text,
    #                                          NO grey dimming.
    # The stock default is contrast 0.8, which dims whites to a
    # light grey. Set back to 0.8 if pure white is too harsh.
    dark_mode_background_color   0.0 0.0 0.0
    dark_mode_contrast           1.0

    # --- grey option (uncomment both lines to switch) ---
    # dark_mode_background_color   0.1 0.1 0.1
    # dark_mode_contrast           0.8
  '';
}
