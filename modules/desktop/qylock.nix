# Qylock SDDM themes (from the qylock flake input).
#
# NOTE: the Quickshell lockscreen requires compositor support for the
# ext-session-lock-v1 protocol, which KWin does NOT support yet — so
# only the SDDM login-screen theme works under Plasma. qylock-lock
# becomes useful only under a wlroots compositor like Hyprland.
{ config, pkgs, lib, ... }:

{
  programs.qylock = {
    enable = true;

    # Any directory name under qylock's `themes/` folder:
    # "nier-automata", "terraria", "clockwork", "pixel-coffee", ...
    # Full list: https://github.com/Darkkal44/qylock#-gallery
    theme = "nier-automata";

    # sddm.enable = true;         # default: installs theme + sets it active
    # quickshell.enable = false;  # see NOTE above — no KWin support yet

    # Optional per-theme tweaks (skips qylock's interactive prompts):
    # themeOptions = {
    #   terraria.backgroundMode = "time";   # time | random | static
    #   Genshin.backgroundMode = "time";
    #   clockwork.orbital = { themeMode = "dark"; enableWindup = true; };
    #   osu.gameMode = "menu";              # menu | game
    # };
  };
}
