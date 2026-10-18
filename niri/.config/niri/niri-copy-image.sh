#!/usr/bin/env bash
set -euo pipefail

# Single Responsibility: Store copied PNG image data from stdin into CopyQ history
# without creating duplicate consecutive items.

TMP_FILE="${XDG_RUNTIME_DIR:-/tmp}/copyq_image_$$.png"
trap 'rm -f "$TMP_FILE"' EXIT

main() {
    cat > "$TMP_FILE"

    if [[ ! -s "$TMP_FILE" ]]; then
        return 0
    fi

    local new_hash current_hash
    new_hash=$(sha256sum "$TMP_FILE" | awk '{print $1}')
    current_hash=$(copyq read image/png 0 2>/dev/null | sha256sum | awk '{print $1}' || true)

    if [[ "$new_hash" == "$current_hash" ]]; then
        return 0
    fi

    copyq write image/png - < "$TMP_FILE"
    return 0
}

main "$@"
