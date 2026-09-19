# Virtualization: libvirtd/KVM + virt-manager + Spice USB + Podman.
{ config, pkgs, lib, ... }:

{
  # libvirtd with settings tuned for KVM/QEMU VM performance
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  # Virt-Manager GUI
  programs.virt-manager.enable = true;

  # Spice redirection for USB passthrough
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
