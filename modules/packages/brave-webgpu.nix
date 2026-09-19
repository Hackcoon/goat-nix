# Brave WebGPU build (grainrad-type sites) — OPTIONAL, off the default path.
#
# Toggle: comment/uncomment the import in configuration.nix, rebuild.
# Provides `brave-webgpu` (+ launcher entry, SUPER+SHIFT+G in mango).
# Default `brave` stays the smooth native build from system-packages.nix.
#
# Why separate: Vulkan needs X11 ozone (incompatible with ozone/wayland,
# so this runs via XWayland) plus vulkan-loader on LD_LIBRARY_PATH
# (make-brave never adds it to the wrapper's rpath). None of that should
# touch the daily driver.
{ config, pkgs, lib, ... }:

{
  environment.systemPackages = with pkgs; [
    (let
      braveVk = brave.override {
        enableVulkan = true;
        vulkanSupport = true;
        commandLineArgs = "--ozone-platform=x11 --enable-unsafe-webgpu --password-store=gnome-libsecret";
      };
    in
      braveVk.overrideAttrs (prev: {
        postFixup = (prev.postFixup or "") + ''
          if [ -f "$out/bin/brave" ]; then
            sed -i 's|^exec -a "$0"|export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\nexec -a "$0"|' "$out/bin/brave"
            mv "$out/bin/brave" "$out/bin/brave-webgpu"
          fi
          if [ -f "$out/share/applications/brave-browser.desktop" ]; then
            sed -e 's|^Exec=brave|Exec=brave-webgpu|' -e 's|^Name=Brave Web Browser|Name=Brave WebGPU|' "$out/share/applications/brave-browser.desktop" > "$out/share/applications/brave-webgpu.desktop"
            rm "$out/share/applications/brave-browser.desktop"
          fi
        '';
      }))
  ];
}
