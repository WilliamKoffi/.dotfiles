#!/usr/bin/env bash
# Single Responsibility: Install Nix packages from packages.txt
set -euo pipefail

LIST_FILE="$(dirname "$0")/packages.txt"

# Early return if package list does not exist
if [ ! -f "$LIST_FILE" ]; then
    echo "Error: $LIST_FILE not found." >&2
    exit 1
fi

# Load packages, ignoring comments and empty lines
mapfile -t pkgs < <(grep -vE '^\s*(#|$)' "$LIST_FILE")

# Early return if no packages to install
if [ ${#pkgs[@]} -eq 0 ]; then
    echo "No packages to install."
    exit 0
fi

# Locate Nix binary using $HOME with a fallback to the default system profile path
NIX_BIN=""
if [ -x "$HOME/.nix-profile/bin/nix" ]; then
    NIX_BIN="$HOME/.nix-profile/bin/nix"
elif [ -x "/nix/var/nix/profiles/default/bin/nix" ]; then
    NIX_BIN="/nix/var/nix/profiles/default/bin/nix"
fi

# Early return if nix is not found
if [ -z "$NIX_BIN" ]; then
    echo "Error: nix binary not found." >&2
    exit 1
fi

echo "Installing ${#pkgs[@]} packages via Nix profile..."
"$NIX_BIN" profile add --impure "${pkgs[@]}"

