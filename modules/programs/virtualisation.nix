# Virtualization: libvirtd/KVM + virt-manager + Spice USB + Podman.
#
# TWO SEPARATE WORLDS in one file — don't conflate them:
#   - libvirtd/QEMU/KVM = full virtual MACHINES (Windows, other distros)
#     managed via the virt-manager GUI. Needs hardware VT-x/AMD-V.
#   - Podman = lightweight CONTAINERS (single apps/services sharing the
#     host kernel). Docker-compatible CLI, but daemonless — nothing runs
#     at idle, the API socket starts on demand for docker-API tools
#     like winboat.
{ config, pkgs, lib, ... }:

{
  # libvirtd with settings tuned for KVM/QEMU VM performance
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      # KVM-accelerated QEMU (near-native speed) instead of pure emulation.
      package = pkgs.qemu_kvm;
      # Run QEMU system instances as root so bridged networking and PCI
      # passthrough don't hit permission walls.
      runAsRoot = true;
      # swtpm = software TPM emulator. Required for Windows 11 guests
      # (installer refuses to proceed without a TPM 2.0 device).
      swtpm.enable = true;
    };
  };

  # Virt-Manager GUI: point-and-click VM create/start/console manager
  # on top of libvirtd. Guest access is via the libvirtd group
  # (see modules/users/users.nix).
  programs.virt-manager.enable = true;

  # Spice redirection for USB passthrough: lets a running VM claim host
  # USB sticks / webcams / serial dongles from the viewer (spice client),
  # instead of statically binding the device at VM definition time.
  virtualisation.spiceUSBRedirection.enable = true;

  # Podman — daemonless container backend. Nothing runs until you
  # actually start a container (zero idle CPU/memory).
  #   dockerCompat    -> `docker` CLI shim pointing at podman
  #   dockerSocket    -> docker-compatible API socket (socket-activated,
  #                     starts on demand) so docker-API tools (winboat)
  #                     work without a permanent daemon.
  # Want the REAL Docker daemon instead? Drop this block and enable
  # virtualisation.docker.enable = true;
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
  };
}
