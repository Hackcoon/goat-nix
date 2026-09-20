# Thunar file manager + the services it needs (mounting, trash,
# thumbnails, preference persistence).
#
# Thunar alone is just a window — without these three helpers it can't
# mount USB sticks, show thumbnails, remember view settings, or trash
# files (deletes would be permanent):
#   gvfs    = virtual filesystem: MTP phones, SMB shares, trash://, USB mounting
#   tumbler = thumbnail daemon: image/video previews in the file grid
#   xfconf  = settings store: remembers sort order, zoom, side pane, etc.
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
