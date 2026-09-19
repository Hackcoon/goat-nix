# Brave Browser: Enabling WebGPU (Vulkan) on NixOS + NVIDIA

**Date:** 2026-09-10
**Machine:** Desktop (AMD Ryzen 5 3600, NVIDIA GTX 1660 SUPER, proprietary driver 595.71.05)
**Compositor:** MangoWC (wlroots-based Wayland)
**NixOS:** 26.05, flake-based config at `/etc/nixos`

## The Problem

Sites using WebGPU (`navigator.gpu`) — e.g. grainrad — worked on
Windows/Android but failed on Linux. In Brave, `navigator.gpu` didn't
even exist, and `brave://gpu` showed no Vulkan support.

## Root Cause (4 separate issues, all required fixing)

WebGPU on Linux in Chromium/Brave requires the **Vulkan** backend.
Nothing in the default NixOS setup provides it to Brave:

1. **nixpkgs disables Vulkan by default** — `make-brave.nix` ships
   `vulkanSupport ? false` (comment in nixpkgs: "disabled by default as
   it seems to break VA-API"). Without it, Brave never gets the
   `--enable-features=Vulkan` flag.

2. **`vulkan-loader` is invisible to Brave even when enabled** —
   `vulkanSupport = true` only adds the ICD *discovery* path
   (`XDG_DATA_DIRS` → `/run/opengl-driver/share`), but `make-brave.nix`
   builds the wrapper's `LD_LIBRARY_PATH`/rpath from a fixed `deps`
   list that does **not** include `vulkan-loader`. The GPU process
   logs `Failed to load 'libvulkan.so.1'` and falls back to software.

3. **The loader wasn't in the driver runpath at all** —
   `hardware.graphics` didn't include `vulkan-loader`, so
   `/run/opengl-driver/lib/libvulkan.so.1` didn't exist for any app.

4. **Chromium's Vulkan backend is incompatible with ozone/wayland** —
   Brave logged:
   `'--ozone-platform=wayland' is not compatible with Vulkan. Consider
   switching to '--ozone-platform=x11'`
   The compositor's `ELECTRON_OZONE_PLATFORM_HINT=auto` env was forcing
   Wayland. WebGPU on Vulkan requires `--ozone-platform=x11`
   (runs via XWayland).

Additionally, `requestAdapter()` returned `null` until
`--enable-unsafe-webgpu` was passed (WebGPU is gated behind
origin trials / flags on Linux).

## The Fix

### 1. `modules/hardware/nvidia.nix` — put the loader in the driver runpath

```nix
hardware.graphics = {
  enable = true;
  enable32Bit = true;
  # vulkan-loader: Chromium browsers with the Vulkan feature need
  # libvulkan.so.1 at runtime. make-brave.nix only adds the ICD search
  # path, not the loader itself.
  extraPackages = [ pkgs.vulkan-loader ];
};
```

### 2. `modules/packages/system-packages.nix` — Brave override

```nix
(let
  braveVk = brave.override {
    enableVulkan = true;       # adds --enable-features=Vulkan
    vulkanSupport = true;      # adds ICD discovery path (XDG_DATA_DIRS)
    # X11 ozone: Chromium's Vulkan backend (needed for WebGPU) is
    # incompatible with ozone/wayland. Runs via XWayland.
    # ELECTRON_OZONE_PLATFORM_HINT=auto (set by the mango config)
    # would otherwise force wayland.
    commandLineArgs = "--ozone-platform=x11 --enable-unsafe-webgpu";
  };
in
  braveVk.overrideAttrs (prev: {
    # bin/brave is the bash launcher that execs .brave-wrapped.
    # Inject the driver lib path right before the exec line so the
    # GPU process can dlopen libvulkan.so.1 (make-brave never adds
    # vulkan-loader to the wrapper's rpath).
    postFixup = (prev.postFixup or "") + ''
      if [ -f "$out/bin/brave" ]; then
        sed -i 's|^exec -a "$0"|export LD_LIBRARY_PATH="/run/opengl-driver/lib''${LD_LIBRARY_PATH:+:$LD_LIBRARY_PATH}"\nexec -a "$0"|' "$out/bin/brave"
      fi
    '';
  }))
```

Then:

```
sudo nixos-rebuild switch --flake /etc/nixos#nixos
```

**Kill any running Brave first** — a pre-switch session keeps serving
new launches from the old process, making it look like the fix didn't
work. (`pkill -f 'opt/brave'`)

## Verification

- `brave://gpu` should show:
  ```
  Vulkan: Enabled
  WebGPU: Hardware accelerated
  Video Decode: Hardware accelerated
  Video Encode: Hardware accelerated
  ```
- DevTools console (`F12`) on any https page:
  ```js
  const a = await navigator.gpu.requestAdapter();
  (await a.requestAdapterInfo()).architecture  // should not be "swiftshader"
  ```
- GPU process cmdline should include `ozone-platform=x11` and the
  `Vulkan` feature; its maps should include `libvulkan.so.1`.

## Notes & Caveats

- **Why the adapter may still say `swiftshader`:** if
  `requestAdapter()` returns a SwiftShader adapter, WebGPU is running
  on CPU. Verify vendor/architecture via `requestAdapterInfo()`.
  `webgpu_on_vk_via_gl_interop` shows as disabled — normal on this
  driver combo.
- **X11 ozone tradeoff:** Brave now runs through XWayland, not native
  Wayland. Fractional-scaling sharpness may be slightly worse. VA-API
  video decode is not affected on NVIDIA (decode goes through NVDEC;
  gpu page confirms hardware decode/encode stay enabled).
- **nixpkgs comment warns Vulkan breaks VA-API** — that mainly
  affects AMD/Intel. On this NVIDIA setup, both video decode and
  encode remained hardware accelerated after the switch.
- **Diagnostics that helped:** launch with
  `--remote-debugging-port=9222 --remote-allow-origins=http://localhost:9222`
  and query `SystemInfo.getInfo` over CDP for `gpu.features`
  (`vulkan: enabled_on`, `webgpu: enabled`).
- The `--enable-unsafe-webgpu` flag name is intentional; on Linux it
  doesn't mean "unsafe" so much as "not yet origin-trial-gated".

## Related Files

- `/etc/nixos/modules/packages/system-packages.nix` — Brave override
- `/etc/nixos/modules/hardware/nvidia.nix` — vulkan-loader in graphics
- `~/.config/mango/config.conf` — sets `ELECTRON_OZONE_PLATFORM_HINT=auto`
  (reason Brave needs the explicit `--ozone-platform=x11` flag)
