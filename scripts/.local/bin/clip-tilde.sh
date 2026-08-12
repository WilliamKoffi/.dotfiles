#!/usr/bin/env bash
# clip-tilde: read clipboard, replace $HOME with ~, write back

set -euo pipefail

content=$(copyq clipboard)
trimmed="${content//$HOME/\~}"
copyq copy -- "$trimmed"