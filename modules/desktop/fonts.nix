# System-wide fonts + fontconfig defaults.
#
# Font set = union of LinuxBeginnings + JaKooLit NixOS font modules,
# so any config you copy from either project renders exactly the same.
# JetBrains Mono Nerd Font stays THE default (fury-bar, kitty, waybar).
{ config, pkgs, lib, ... }:

{
  fonts = {
    packages = with pkgs; [
      # ── DEFAULT (keep first — what fury-bar/kitty/waybar use) ──
      nerd-fonts.jetbrains-mono   # JetBrains Mono NF (icons for eza, bat, ...)

      # ── LinuxBeginnings / JaKooLit shared set ──
      dejavu_fonts
      fira
      fira-go
      googlesans-code
      fira-code
      fira-code-symbols
      font-awesome
      hackgen-nf-font
      iosevka
      nerd-fonts.iosevka-term
      nerd-fonts.iosevka-term-slab
      ibm-plex
      inter
      lilex
      material-icons
      material-symbols
      maple-mono.NF
      meslo-lg
      jetbrains-mono
      nerd-fonts.im-writing
      nerd-fonts.blex-mono
      nerd-fonts.caskaydia-cove
      nerd-fonts.caskaydia-mono
      nerd-fonts.code-new-roman
      nerd-fonts.hack
      nerd-fonts.iosevka
      nerd-fonts.lilex
      nerd-fonts.meslo-lg
      nerd-fonts.fira-mono
      nerd-fonts.space-mono
      nerd-fonts.ubuntu
      powerline-fonts
      roboto
      roboto-mono
      terminus_font
      victor-mono

      # ── Language / symbol coverage (was already here — kept) ──
      noto-fonts                  # Multilingual (Arabic, Cyrillic, ...)
      noto-fonts-cjk-sans         # Chinese/Japanese/Korean
      noto-fonts-cjk-serif        # CJK serif (JaKooLit set)
      noto-fonts-monochrome-emoji # monochrome emoji fallback
      noto-fonts-color-emoji      # Emoji
      symbola                     # Full Unicode symbols (squared/enclosed letters)
      freefont_ttf                # GNU FreeFont (math bold script)
      stix-two                    # Math & script coverage
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "JetBrainsMono Nerd Font" "FreeMono" "STIX Two Math" "Symbola" ];
        sansSerif = [ "Noto Sans" "Noto Sans Arabic" "IBM Plex Sans Arabic" "FreeSans" "STIX Two Text" "Symbola" ];
        serif     = [ "Noto Serif" "Noto Naskh Arabic" "FreeSerif" "STIX Two Text" "Symbola" ];
        emoji     = [ "Noto Color Emoji" ];
      };
    };
  };
}
