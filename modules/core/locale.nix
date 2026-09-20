# Localization: timezone + locale + console keyboard.
#
# Ronny's machine: lives in Dubai, Spanish physical keyboard, but wants
# everything in ENGLISH (no Arabic locale anywhere).
#
# Three separate layers — don't conflate them:
#   - timeZone  = wall-clock time (Asia/Dubai = UTC+4, no DST).
#   - defaultLocale = language/apps (en_US = English menus, dates, websites).
#   - keyMap/xkb layout = physical key positions (es = Spanish keyboard).
# Changing locale never changes the keyboard and vice-versa.
{ config, pkgs, lib, ... }:

{
  # Gulf Standard Time (UTC+4, no DST — clocks never shift)
  time.timeZone = "Asia/Dubai";

  # System language: US English everywhere (menus, dates, apps, Firefox).
  # NOT ar_AE — that would flip apps and websites into Arabic.
  i18n.defaultLocale = "en_US.UTF-8";

  # TTY (Ctrl+Alt+F1-6) keyboard: Spanish layout to match the hardware.
  # Graphical layouts: KDE/SDDM come from kde.nix xkb, Hyprland from its
  # own input config — keep all three on "es".
  console.keyMap = "es";
}
