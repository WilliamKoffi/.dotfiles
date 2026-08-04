#!/usr/bin/env bash
# cliphist-paste.sh
# Show cliphist picker in rofi, copy selection to clipboard, then paste into
# the focused window. Uses wtype for paste so it works in both terminals and
# GUI apps without needing a Hyprland sendshortcut.

selected=$(cliphist list | rofi -dmenu -p "Clipboard") || exit 0

[[ -z "$selected" ]] && exit 0

cliphist decode <<<"$selected" | wl-copy

# Give the clipboard a moment to settle before sending the paste keystroke.
sleep 0.1

class=$(hyprctl activewindow -j 2>/dev/null | jq -r '.class // empty')

# Terminals use Ctrl+Shift+V; editors and browsers use Ctrl+V.
# Use -k (press+release) so key-repeat cannot spam paste while the key is held.
case "$class" in
  rio|kitty|Alacritty|foot|wezterm|org.wezfurlong.wezterm|dev.warp.Warp|warp-terminal|com.mitchellh.ghostty)
    wtype -M shift -M ctrl -k v -m ctrl -m shift
    ;;
  *)
    wtype -M ctrl -k v -m ctrl
    ;;
esac
