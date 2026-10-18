#!/usr/bin/env bash
# tilde: read clipboard, replace $HOME with ~, write back

set -euo pipefail

content=$(wl-paste --no-newline)
wl-copy -- "${content//"$HOME"/'~'}"
