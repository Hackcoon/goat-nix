# Cursor + GTK theme environment variables.
#
# XCURSOR_THEME must match a variant provided by google-cursor
# (installed in packages/system-packages.nix under THEMES & CURSORS).
#
# GTK_THEME: forces the GTK theme at the library level for ALL GTK
# apps, overriding gsettings/xsettings. WHY: Electron apps (vscodium,
# brave, mailspring...) render native menus/dialogs with GTK.
# Pinning to Breeze-Dark (present in /run/current-
# system/sw/share/themes/ via the breeze-gtk package) keeps
# Electron UIs consistent with the Plasma look in every session.
# XDG_MENU_PREFIX=plasma-: KDE's freedesktop menu namespace, so
# app launchers resolve KDE-provided .directory entries.
{ config, pkgs, lib, ... }:

{
  environment.variables = {
    # Variant options: GoogleDot-Blue, GoogleDot-Black, GoogleDot-White, GoogleDot-Red
    # Other themes: phinger-cursors (most over-engineered),
    #   Borealis-cursors, bibata-cursors-translucent, bibata-cursors
    #   macOS-like: apple-cursor, afterglow-cursors-recolored
    #   Windows-like: openzone-cursors
    # GoogleDot-Black = dark dot cursor (fits the black/red desktop).
    XCURSOR_THEME = "GoogleDot-Black";

    # Standard cursor sizes: 22, 24, 32, 48, 64
    # 22 = small but readable at 1080p; HiDPI panels want 32+.
    XCURSOR_SIZE = "22";

    # Dark GTK theme for Electron/Chromium apps under Plasma.
    # (Library-level override — wins even when xsettings/gsettings says
    # otherwise. Remove to let per-desktop settings decide again.)
    GTK_THEME = "Breeze-Dark";

    # Use KDE's application-menu namespace for Dolphin and other KDE apps.
    # This affects application discovery/file associations, not widget colors
    # or the Qt/GTK theme.
    XDG_MENU_PREFIX = "plasma-";
  };

  # -------------------------------------------------------------------------
  # KDE-side GTK theme pin (fix for inverted/grey Qt apps + drkonqi)
  #
  # ROOT CAUSE (2026-09): kded6's kde-gtk-config module generates
  # ~/.config/xsettingsd/xsettingsd.conf from kdeglobals [KDE] keys.
  # kdeglobals had NO gtkTheme key (DMS's matugen theming targets
  # adw-gtk3 which isn't installed, so it skips+resets the gtk theme),
  # so kded6 wrote Net/ThemeName "" — an EMPTY xsettings theme. Empty
  # over XSETTINGS overrides settings.ini for every GTK app, killing
  # the dark flag: Dolphin, drkonqi and friends rendered light-grey
  # ("inverted") in mango/Hyprland sessions because
  # QT_QPA_PLATFORMTHEME=gtk3 routes Qt through GTK resolution.
  #
  # FIX: declare the GTK theme in kdeglobals' [KDE] group, which both
  # KDE's kcm and kded6 read (module maps Breeze-Dark for dark
  # schemes), so the generated xsettingsd.conf carries a real theme.
  # ~/.config/kdeglobals is user-owned; kdedefaults (XDG_CONFIG_DIRS,
  # never rewritten by apps) is the system-side override point.
  # -------------------------------------------------------------------------
  environment.etc."xdg/kdedefaults/kdeglobals".text = ''
    [KDE]
    widgetStyle=Breeze
    gtkTheme=Breeze-Dark

    [Icons]
    Theme=Papirus-Dark
  '';
}
