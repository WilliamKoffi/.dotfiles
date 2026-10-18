#!/usr/bin/env bash
set -euo pipefail

# Single Responsibility: Store copied plain text from stdin into CopyQ history
# without creating duplicate consecutive items.

main() {
    local content
    content=$(cat)

    if [[ -z "$content" ]]; then
        return 0
    fi

    local current
    current=$(copyq read 0 2>/dev/null || true)

    if [[ "$content" == "$current" ]]; then
        return 0
    fi

    printf '%s' "$content" | copyq add -
    return 0
}

main "$@"
