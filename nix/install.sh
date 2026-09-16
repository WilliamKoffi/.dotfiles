#!/usr/bin/env bash
# Single Responsibility: Install Nix packages from packages.txt with selection support
set -euo pipefail

locate_nix() {
    if [ -x "$HOME/.nix-profile/bin/nix" ]; then
        echo "$HOME/.nix-profile/bin/nix"
        return 0
    fi
    if [ -x "/nix/var/nix/profiles/default/bin/nix" ]; then
        echo "/nix/var/nix/profiles/default/bin/nix"
        return 0
    fi
    if command -v nix >/dev/null 2>&1; then
        command -v nix
        return 0
    fi
    return 1
}

locate_fzf() {
    if command -v fzf >/dev/null 2>&1; then
        command -v fzf
        return 0
    fi
    if [ -x "$HOME/.nix-profile/bin/fzf" ]; then
        echo "$HOME/.nix-profile/bin/fzf"
        return 0
    fi
    return 1
}

load_all_packages() {
    local list_file="$1"
    if [ ! -f "$list_file" ]; then
        return 1
    fi
    grep -vE '^\s*(#|$)' "$list_file"
}

format_fzf_input() {
    local list_file="$1"
    if [ ! -f "$list_file" ]; then
        return 1
    fi
    awk '/^[[:space:]]*#/ { sub(/^[[:space:]]*#[[:space:]]*/, ""); cat = $0; next }
         /^[[:space:]]*$/ { next }
         { printf "%-40s  # %s\n", $1, cat }' "$list_file"
}

resolve_package() {
    local arg="$1"
    local list_file="$2"
    if grep -qE "^${arg}\$" "$list_file"; then
        echo "$arg"
        return 0
    fi
    if grep -qE "^nixpkgs#${arg}\$" "$list_file"; then
        echo "nixpkgs#$arg"
        return 0
    fi
    if [[ "$arg" == *"#"* ]]; then
        echo "$arg"
        return 0
    fi
    echo "nixpkgs#$arg"
}

select_packages_fzf() {
    local list_file="$1"
    local fzf_bin="$2"

    if [ -z "$fzf_bin" ] || [ ! -x "$fzf_bin" ]; then
        echo "Error: fzf is required for interactive selection but was not found." >&2
        return 1
    fi

    local raw_selection
    raw_selection="$(format_fzf_input "$list_file" | "$fzf_bin" -m \
        --header="TAB: toggle selection | Ctrl-A: select all | Ctrl-D: deselect | ENTER: confirm | ESC: cancel" \
        --prompt="Select packages to install > ")" || true

    if [ -z "$raw_selection" ]; then
        return 1
    fi

    echo "$raw_selection" | awk '{print $1}'
}

prompt_install_mode() {
    if [ ! -t 0 ]; then
        echo "all"
        return 0
    fi

    echo "Nix Package Installer" >&2
    echo "  1) Select packages interactively (fzf) [default]" >&2
    echo "  2) Install all packages from packages.txt" >&2
    local choice=""
    read -r -p "Choose an option [1/2, default: 1]: " choice </dev/tty || choice=""

    if [ "$choice" = "2" ] || [ "$choice" = "a" ] || [ "$choice" = "all" ]; then
        echo "all"
        return 0
    fi

    echo "select"
    return 0
}

show_help() {
    cat << 'HELP'
Usage: ./install.sh [OPTIONS] [PACKAGES...]

Install packages into your Nix profile from packages.txt or CLI arguments.

Options:
  -s, --select, -i, --interactive   Interactively select packages using fzf
  -a, --all                         Install all packages from packages.txt
  -h, --help                        Show this help message

Examples:
  ./install.sh                      # Prompt for mode (interactive fzf by default)
  ./install.sh -s                   # Jump straight to interactive fzf selection
  ./install.sh -a                   # Install all packages
  ./install.sh flutter dart         # Install specific packages directly
  ./install.sh nixpkgs#gradle_9     # Install by full flake reference
HELP
}

install_packages() {
    local nix_bin="$1"
    shift
    local pkgs=("$@")

    if [ ${#pkgs[@]} -eq 0 ]; then
        echo "No packages to install."
        return 0
    fi

    echo "Installing ${#pkgs[@]} package(s) via Nix profile..."
    for pkg in "${pkgs[@]}"; do
        echo "  + $pkg"
    done
    echo ""

    "$nix_bin" profile add --impure "${pkgs[@]}"
}

main() {
    local list_file
    list_file="$(dirname "$0")/packages.txt"

    if [ ! -f "$list_file" ]; then
        echo "Error: $list_file not found." >&2
        exit 1
    fi

    local nix_bin
    nix_bin="$(locate_nix)" || {
        echo "Error: nix binary not found." >&2
        exit 1
    }

    local fzf_bin
    fzf_bin="$(locate_fzf)" || fzf_bin=""

    local mode=""
    local custom_pkgs=()

    while [ $# -gt 0 ]; do
        case "$1" in
            -h|--help)
                show_help
                exit 0
                ;;
            -s|--select|-i|--interactive)
                mode="select"
                shift
                ;;
            -a|--all)
                mode="all"
                shift
                ;;
            *)
                custom_pkgs+=("$1")
                shift
                ;;
        esac
    done

    # If explicit package arguments were provided, resolve and install them
    if [ ${#custom_pkgs[@]} -gt 0 ]; then
        local pkgs=()
        for p in "${custom_pkgs[@]}"; do
            pkgs+=("$(resolve_package "$p" "$list_file")")
        done
        install_packages "$nix_bin" "${pkgs[@]}"
        exit 0
    fi

    # Determine mode if not explicitly provided via flags
    if [ -z "$mode" ]; then
        if [ -n "$fzf_bin" ] && [ -t 0 ]; then
            mode="$(prompt_install_mode)"
        else
            mode="all"
        fi
    fi

    # Execute selected mode
    if [ "$mode" = "all" ]; then
        mapfile -t pkgs < <(load_all_packages "$list_file")
        if [ ${#pkgs[@]} -eq 0 ]; then
            echo "No packages found in $list_file."
            exit 0
        fi
        install_packages "$nix_bin" "${pkgs[@]}"
        exit 0
    fi

    # Interactive selection mode
    if [ -z "$fzf_bin" ]; then
        echo "Error: fzf is required for interactive package selection." >&2
        exit 1
    fi

    local selected_lines
    selected_lines="$(select_packages_fzf "$list_file" "$fzf_bin")" || {
        echo "No packages selected. Aborting."
        exit 0
    }

    mapfile -t pkgs <<< "$selected_lines"
    if [ ${#pkgs[@]} -eq 0 ]; then
        echo "No packages selected. Aborting."
        exit 0
    fi

    install_packages "$nix_bin" "${pkgs[@]}"
    exit 0
}

main "$@"
