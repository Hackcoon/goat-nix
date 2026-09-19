#!/usr/bin/env bash
# zsh-aliases.sh — searchable zsh alias list for mango (SUPER+SHIFT+H).
# Live source: zsh -ic alias (NixOS shellAliases + oh-my-zsh plugins).
# Pick a row in rofi to copy its expansion to the clipboard.
if pidof rofi >/dev/null 2>&1; then
  pkill rofi
fi

list=$(zsh -ic 'alias' 2>/dev/null | sed -E -e "s/^([^=]+)='(.*)'$/\1 -> \2/" -e "s/^([A-Za-z0-9_.-]+)=([^'].*)$/\1 -> \2/" | sort)
if [[ -z "$list" ]]; then
  notify-send 'Aliases' 'No aliases found'
  exit 0
fi

choice=$(printf '%s\n' "$list" | rofi -dmenu -i -p "zsh aliases") || exit 0
[[ -z "$choice" ]] && exit 0

cmd=${choice#*-> }
cmd=$(printf '%s' "$cmd" | sed 's/^ *//')
printf '%s' "$cmd" | wl-copy
notify-send 'Alias copied' "$cmd"
