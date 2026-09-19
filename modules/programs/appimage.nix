# AppImage support via binfmt_misc.
#
# USAGE:
#   Run (one-off):  chmod +x ./SomeApp.AppImage && ./SomeApp.AppImage
#   Without binfmt: nix-shell -p appimage-run --run "appimage-run ./SomeApp.AppImage"
#   "Install":      gearlever (in nixpkgs) manages AppImages + desktop
#                  entries, like AppImageLauncher on other distros.
#
# PACKAGING an AppImage properly (best for constant use):
#   1. Determine the type: `file ./SomeApp.AppImage`
#      "ISO 9660" in the output = Type 2 (use appimageTools.wrapType2)
#      "ELF" only              = Type 1 (use wrapType1)
#   2. Write a derivation, e.g. /etc/nixos/pkgs/someapp.nix:
#
#        { lib, appimageTools, fetchurl }:
#        let
#          pname = "someapp";
#          version = "1.4.0";
#          src = fetchurl {
#            url = "https://example.com/releases/SomeApp-${version}.AppImage";
#            hash = "";   # leave blank; nix prints the real hash on first build
#          };
#        in
#        appimageTools.wrapType2 {
#          inherit pname version src;
#          # Fixes the .desktop Exec= line so launchers call the wrapped binary
#          extraInstallCommands = '''
#            substituteInPlace $out/share/applications/${pname}.desktop \
#              --replace-fail 'Exec=AppRun' 'Exec=${pname}'
#          ''';
#        }
#
#   3. Wire it in (packages/system-packages.nix):
#        (pkgs.callPackage ./pkgs/someapp.nix { })
#   4. Build once with the empty hash to learn the real one, paste it
#      in, rebuild for real. From here it's a normal package: launcher
#      entry, icon, updates on version bump, correct GC behavior.
#
# IF AN APPIMAGE FAILS TO LAUNCH with "error while loading shared
# libraries: libXXX.so.XX: cannot open shared object file", uncomment
# ONLY what the error names in the override below — some (torch) are
# multi-GB; don't add speculatively.
{ config, pkgs, lib, ... }:

{
  programs.appimage = {
    enable = true;
    binfmt = true;

    # package = pkgs.appimage-run.override {
    #   extraPkgs = pkgs: [
    #     pkgs.icu               # libicuuc.so errors (Electron/Qt AppImages)
    #     pkgs.libxcrypt-legacy  # libcrypt.so.1 errors (older glibc/crypt)
    #     pkgs.python312         # only if it bundles/calls system Python 3.12
    #     pkgs.python312Packages.torch  # ML AppImages expecting host PyTorch (heavy)
    #   ];
    # };
  };
}
