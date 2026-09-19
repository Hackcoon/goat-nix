# Firefox — system-wide installation via the NixOS module
# (wraps the unwrapped package with policies/wrapping support).
#
# Pywalfox (DMS Option 2): native host wired here so the Pywalfox
# extension finds it without `pywalfox install` (which fails on NixOS —
# store is read-only, see nixpkgs issue #281377). Needs
# ~/.cache/wal/colors.json (symlink to DMS's dank-pywalfox.json) + the
# AMO extension. See danklinux.com docs for DankMaterialShell
# application theming.
{ config, pkgs, lib, ... }:

let
  # nixpkgs' pywalfox-native ships NO manifest file — upstream generates
  # it at `pywalfox install` time by substituting the `<path>` placeholder
  # in its bundled assets/manifest.json. That can't run against the
  # read-only store, and feeding the raw package to nativeMessagingHosts
  # breaks the Firefox wrapper build (empty glob -> `ln` with no operand).
  # So this shim does declaratively what `pywalfox install` does
  # imperatively: same template, store path baked in. (No new file in
  # ./pkgs/ needed — pure glue next to its only consumer.)
  pywalfoxHost = pkgs.runCommand "pywalfox-native-host" { } ''
    mkdir -p $out/lib/mozilla/native-messaging-hosts
    src=( ${pkgs.pywalfox-native}/lib/python*/site-packages/pywalfox/assets/manifest.json )
    substitute "$src" \
      $out/lib/mozilla/native-messaging-hosts/pywalfox.json \
      --replace-fail '<path>' '${pkgs.pywalfox-native}/bin/pywalfox'
  '';
in
{
  programs.firefox = {
    enable = true;

    # ── Stay logged in across sessions/desktops/rebuilds ──
    # On NixOS, Firefox "logs you out" for three mechanical reasons, and
    # this block fixes all three:
    #   1. Dedicated-profiles-per-install: every rebuild swaps the store
    #      path, so stock Firefox spawns a FRESH profile (logins gone).
    #      Fixed by MOZ_LEGACY_PROFILES=1 below (one stable profile in
    #      ~/.mozilla, shared across rebuilds and desktop sessions).
    #   2. "Clear on shutdown" wiping cookies. Fixed by locking the
    #      privacy.clearOnShutdown.* prefs to false.
    #   3. Crash/lock leaving sessionstore disabled. Fixed by locking
    #      resume-from-crash on + restoring the previous session at start.
    # What still logs you out (not our bug): sites with short-lived
    # cookies, "log out other sessions" buttons, and private windows.
    # Verify after rebuild: `about:policies` in Firefox.
    policies = {
      # Reopen previous tabs + windows after restart/crash.
      Homepage.StartPage = "previous-session";

      # Block the "Refresh Firefox" button — it migrates you to a new
      # profile and orphans every login.
      DisableProfileRefresh = true;

      # Lock the prefs that would otherwise nuke cookies/history on exit.
      Preferences = {
        "browser.sessionstore.resume_from_crash" = {
          Value = true;
          Status = "locked";
        };
        "privacy.clearOnShutdown.cookies" = {
          Value = false;
          Status = "locked";
        };
        "privacy.clearOnShutdown.history" = {
          Value = false;
          Status = "locked";
        };
        "privacy.clearOnShutdown.cache" = {
          Value = false;
          Status = "locked";
        };
      };

      # Keep password manager + autofill available (some hardening guides
      # disable these, which just pushes users to weaker habits).
      PasswordManagerEnabled = true;

      # US English UI + en-US first for Accept-Language (matches
      # locale.nix en_US — pages render English, never Arabic).
      RequestedLocales = [ "en-US" ];
    };
  };

  # Opt out of dedicated-profiles-per-install (see policy comment #1):
  # with this set, Firefox reuses the same ~/.mozilla profile no matter
  # how often the store path changes under it.
  environment.sessionVariables.MOZ_LEGACY_PROFILES = "1";

  # Exposes the shim's manifest to the Firefox wrapper, landing at:
  # /run/current-system/sw/lib/mozilla/native-messaging-hosts/pywalfox.json
  programs.firefox.nativeMessagingHosts.packages = [ pywalfoxHost ];
}
