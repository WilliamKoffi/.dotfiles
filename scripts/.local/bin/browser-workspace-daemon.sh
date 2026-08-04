#!/usr/bin/env bash
# browser-workspace-daemon.sh
#
# Listens on Hyprland's event socket for `openwindow` events. Any window
# whose class matches BROWSER_CLASS_RE is moved to the first workspace
# (starting at START_WS) that does not already contain another browser
# window. This groups each browser instance onto its own workspace and
# works no matter how the window was launched (keybind, rofi, xdg-open,
# a notification click, ...) since it reacts to the compositor event
# rather than to how the process was spawned.

set -euo pipefail

START_WS=3
MAX_WS=20

BROWSER_CLASS_RE='^(brave-browser|google-chrome|google-chrome-stable|chromium|chromium-browser|firefox|firefoxdeveloperedition|org\.mozilla\.firefox|zen|zen-browser|vivaldi-stable|microsoft-edge|microsoft-edge-stable)$'

sock="${XDG_RUNTIME_DIR}/hypr/${HYPRLAND_INSTANCE_SIGNATURE}/.socket2.sock"

handle_openwindow() {
  local payload=$1
  local addr ws_name class
  addr=$(cut -d, -f1 <<<"$payload")
  ws_name=$(cut -d, -f2 <<<"$payload")
  class=$(cut -d, -f3 <<<"$payload")

  [[ "$class" =~ $BROWSER_CLASS_RE ]] || return 0

  local full_addr="0x${addr}"
  local clients target_ws=""
  clients=$(hyprctl clients -j)

  for ((ws = START_WS; ws <= MAX_WS; ws++)); do
    local count
    count=$(jq --argjson id "$ws" --arg self "$full_addr" --arg re "$BROWSER_CLASS_RE" '
      [.[] | select(.workspace.id == $id) | select(.address != $self) | select(.class | test($re))] | length
    ' <<<"$clients")
    if [[ "$count" -eq 0 ]]; then
      target_ws=$ws
      break
    fi
  done
  target_ws=${target_ws:-$MAX_WS}

  # Already on the target workspace (e.g. daemon restarted mid-session) — nothing to do.
  [[ "$ws_name" == "$target_ws" ]] && return 0

  hyprctl dispatch movetoworkspace "${target_ws},address:${full_addr}" >/dev/null 2>&1 || true
}

# Auto-reconnect: the compositor socket can drop across an Hyprland reload.
while true; do
  socat -U - UNIX-CONNECT:"$sock" 2>/dev/null | while IFS= read -r line; do
    case "$line" in
      openwindow\>\>*)
        handle_openwindow "${line#openwindow>>}"
        ;;
    esac
  done
  sleep 1
done
