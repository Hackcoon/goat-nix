# System-wide fonts + fontconfig defaults.
#
# Font set = union of LinuxBeginnings + JaKooLit NixOS font modules,
# so any config you copy from either project renders exactly the same.
# JetBrains Mono Nerd Font stays THE default (fury-bar, kitty, waybar).
#
# HOW DEFAULTS WORK: fontconfig's defaultFonts below pick the fallback
# chain per generic family. Apps asking for "monospace" get JetBrainsMono
# Nerd Font first (icons render in terminals/ls), then FreeMono/STIX/Symbola
# for missing glyphs. Sans/serif chains include Arabic-capable fonts
# (Noto Sans Arabic, IBM Plex Sans Arabic) so mixed English/Arabic pages
# in Dubai never show tofu boxes — UI language itself stays English.
{ config, pkgs, lib, ... }:

{
  fonts = {
    packages = with pkgs; [
      # ── DEFAULT (keep first — what fury-bar/kitty/waybar use) ──
      nerd-fonts.jetbrains-mono   # JetBrains Mono NF (icons for eza, bat, ...)

      # ── LinuxBeginnings / JaKooLit shared set ──
      # Plain (non-Nerd) versions kept so copied configs referencing the
      # base family name still resolve; Nerd variants add the icon glyphs.
      dejavu_fonts                # classic fallback sans/mono/serif trio
      fira                        # Fira Sans UI font
      fira-go                     # Fira variant with extended language coverage
      googlesans-code             # monospace matching the kitty setting in home.nix
      fira-code                   # programmer font with ligatures
      fira-code-symbols           # extra ligature symbols for fira-code
      font-awesome                # icon font (window decorations, waybar)
      hackgen-nf-font             # Hack + Nerd icons + Japanese glyphs
      iosevka                     # tall narrow coding font (base build)
      nerd-fonts.iosevka-term     # Iosevka terminal variant + icons
      nerd-fonts.iosevka-term-slab  # slab-serif terminal variant + icons
      ibm-plex                    # IBM Plex family (sans/mono/serif)
      inter                       # UI font (web-style clean sans)
      lilex                       # Lilex coding font (base build)
      material-icons              # Google Material icon glyphs
      material-symbols            # newer Material symbol glyphs
      maple-mono.NF               # rounded coding font + Nerd icons
      meslo-lg                    # Apple-terminal-style mono (base build)
      jetbrains-mono              # base JetBrains Mono (pairs with the NF default above)
      nerd-fonts.im-writing       # handwriting-style font + icons
      nerd-fonts.blex-mono        # IBM Plex Mono + icons
      nerd-fonts.caskaydia-cove   # Cascadia Code + icons
      nerd-fonts.caskaydia-mono   # Cascadia Mono (no ligatures) + icons
      nerd-fonts.code-new-roman   # Cascadia Code serif-ish variant + icons
      nerd-fonts.hack             # Hack + icons
      nerd-fonts.iosevka          # Iosevka proportional + icons
      nerd-fonts.lilex            # Lilex + icons
      nerd-fonts.meslo-lg         # Meslo LG + icons
      nerd-fonts.fira-mono        # Fira Mono + icons
      nerd-fonts.space-mono       # Space Mono + icons
      nerd-fonts.ubuntu           # Ubuntu family + icons
      powerline-fonts             # legacy statusline separator glyphs
      roboto                      # Android/ChromeOS UI sans
      roboto-mono                 # Roboto monospace companion
      terminus_font               # bitmap terminal font (tiny sizes stay crisp)
      victor-mono                 # cursive-italic coding font

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
