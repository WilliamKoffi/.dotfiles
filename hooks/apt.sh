#!/bin/bash

# Make sure the script fails on any error
set -e

# Run this as 'llyam'
sudo -u llyam bash -c '
  set -e

  # Ensure asdf shims and bins are available (for node/npm)
  export ASDF_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
  export PATH="$HOME/.local/bin:$ASDF_DIR/bin:$ASDF_DIR/shims:$HOME/.deno/bin:$HOME/.cargo/bin:$HOME/.bun/bin:$PATH"

  # Source logger directly by path
  LOG_SCRIPT="$HOME/.dotfiles/scripts/.local/bin/library:log.sh"
  if [[ -f "$LOG_SCRIPT" ]]; then
    . "$LOG_SCRIPT"
  else
    # Fallback logger if not found
    print_message() { echo "[$1] $2"; }
    print_message warning "Logger not found at $LOG_SCRIPT; using fallback logger."
  fi

  print_message info "Updating deps for $(whoami)"

  # Deno
  if command -v deno >/dev/null 2>&1; then
    deno upgrade || print_message warning "deno upgrade failed"
  else
    print_message warning "deno not found; skipping deno upgrade"
  fi

  # Bun
  if command -v bun >/dev/null 2>&1; then
    bun upgrade || print_message warning "bun upgrade failed"
  else
    print_message warning "bun not found; skipping bun upgrade"
  fi

  # npm (requires node)
  if command -v npm >/dev/null 2>&1 && command -v node >/dev/null 2>&1; then
    npm -g update || print_message warning "npm -g update failed"
  else
    print_message warning "npm/node not found; skipping global npm update"
  fi

  # uv
  if command -v uv >/dev/null 2>&1; then
    uv self update || print_message warning "uv self update failed"
  else
    print_message warning "uv not found; skipping global uv update"
  fi
'
