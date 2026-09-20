# Qylock SDDM themes (from the qylock flake input).
#
# TWO SEPARATE PRODUCTS — don't confuse them:
#   - SDDM theme  = the LOGIN screen (username/password prompt at boot).
#     Works everywhere, including Plasma/KDE.
#   - Quickshell lockscreen = the IN-SESSION lock (Super+Alt+L style).
#     Needs the ext-session-lock-v1 Wayland protocol, which KWin does NOT
#     support yet — so qylock-lock only works on wlroots compositors
#     (Hyprland/MangoWC), never under a Plasma session.
#
# CURRENTLY DISABLED for goat (see configuration.nix import list):
# plain SDDM is fine and this only themes the login screen anyway.
# Re-enable by uncommenting the import + the flake input.
{ config, pkgs, lib, ... }:

{
  programs.qylock = {
    enable = true;

    # Any directory name under qylock's `themes/` folder:
    # "nier-automata", "terraria", "clockwork", "pixel-coffee", ...
    # Full list: https://github.com/Darkkal44/qylock#-gallery
    # nier-automata = 2B-themed dark login screen (fits the black/red setup).
    theme = "nier-automata";

    # sddm.enable = true;         # default: installs theme + sets it active (keep enabled for the theme to actually show)
    # quickshell.enable = false;  # see NOTE above — no KWin support yet (Hyprland/Mango-only)

    # Optional per-theme tweaks (skips qylock's interactive prompts):
    # themeOptions = {
    #   terraria.backgroundMode = "time";   # time | random | static
    #   Genshin.backgroundMode = "time";
    #   clockwork.orbital = { themeMode = "dark"; enableWindup = true; };
    #   osu.gameMode = "menu";              # menu | game
    # };
  };
}
