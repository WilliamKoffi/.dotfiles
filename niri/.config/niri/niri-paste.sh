#!/usr/bin/env bash

# Single Responsibility: Copy primary selection (selected text) to clipboard
# and simulate paste key presses based on the focused window.

copy_selection_to_clipboard() {
    local selected_text
    selected_text=$(wl-paste --primary --no-newline 2>/dev/null)

    if [[ -z "$selected_text" ]]; then
        return 1
    fi

    echo -n "$selected_text" | wl-copy
    return 0
}

get_focused_app_id() {
    local app_id
    app_id=$(niri msg -j focused-window 2>/dev/null | jq -r '.app_id // empty')

    if [[ -z "$app_id" ]]; then
        return 1
    fi

    echo "$app_id"
    return 0
}

is_terminal() {
    local app_id="$1"
    case "$app_id" in
        rio|kitty|Alacritty|foot|wezterm|org.wezfurlong.wezterm|dev.warp.Warp|warp-terminal|com.mitchellh.ghostty)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

paste_text() {
    local app_id
    app_id=$(get_focused_app_id) || return 0

    if is_terminal "$app_id"; then
        wtype -M shift -M ctrl -k v -m ctrl -m shift
        return 0
    fi

    wtype -M ctrl -k v -m ctrl
    return 0
}

main() {
    if [[ "$1" == "--paste-only" ]]; then
        paste_text
        return 0
    fi
    copy_selection_to_clipboard || return 0
    paste_text
}

main "$@"
