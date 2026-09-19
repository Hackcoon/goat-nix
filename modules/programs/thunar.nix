# Thunar file manager + the services it needs (mounting, trash,
# thumbnails, preference persistence).
{ config, pkgs, lib, ... }:

{
  programs.thunar = {
    enable = true;
    # These plugins were moved from pkgs.xfce to top-level pkgs.
    plugins = [
      pkgs.thunar-archive-plugin
      pkgs.thunar-volman
      pkgs.thunar-media-tags-plugin
      pkgs.thunar-shares-plugin
    ];
  };

  services.gvfs.enable = true;      # mounting, trash, removable devices
  services.tumbler.enable = true;   # thumbnails
  programs.xfconf.enable = true;    # saves Thunar prefs outside a full XFCE session
}
