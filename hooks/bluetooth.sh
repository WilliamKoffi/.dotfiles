#!/bin/bash

LOG_FILE="/tmp/audio_setup.log"

log() {
    # Logs message with timestamp
    echo "$(date '+%F %T') - $1" >> "$LOG_FILE"
}

get_user() {
    local tmp_user
    tmp_user=$(users | cut -d ' ' -f 1)
    if id "$tmp_user" >/dev/null 2>&1; then
        echo "$tmp_user"
    else
        log "Invalid user: $tmp_user"
        return 1
    fi
}

wait_for_sink() {
    local sink=""
    for i in {1..10}; do
        sink=$(pactl list short sinks | grep -i bluez_ | awk '{print $1}')
        if [ -n "$sink" ]; then
            log "Bluetooth sink found on try $i: $sink"
            echo "$sink"
            return 0
        else
            log "Attempt $i: Bluetooth sink not found yet"
        fi
        sleep 1
    done
    log "No bluetooth sink found after 10s"
    return 1
}

main() {
    # Wait for bluetooth sink
    SINK=$(wait_for_sink) || exit 1

    # Set sink volume
    pactl set-sink-volume "$SINK" 32%
}

# Get valid user
USERNAME=$(get_user) || exit 1

# If running as root, re-run main as the logged-in user (so PulseAudio/PipeWire
# talks to that user's session bus). Otherwise just run main directly.
if [ "$(id -u)" -eq 0 ]; then
    sudo -u "$USERNAME" bash -c "LOG_FILE=\"$LOG_FILE\"; export XDG_RUNTIME_DIR=/run/user/$(id -u "$USERNAME"); $(typeset -f main wait_for_sink log); main"
else
    main
fi
