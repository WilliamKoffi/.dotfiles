export PATH="$PATH:$HOME/.local/bin"
export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"

export DOTFILES_PATH="$HOME/.dotfiles"
export LOG_MESSAGE_PATH="$DOTFILES_PATH/scripts/.local/bin/log-message.sh"

export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"
export PATH="$ASDF_DATA_DIR/shims:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

# Deno
[ -f "$HOME/.deno/env" ] && . "$HOME/.deno/env"

# Go
export PATH="$PATH:$HOME/.go/bin"

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# Android SDK
export ANDROID_HOME="$HOME/.android"
export PATH="$PATH:$ANDROID_HOME/cmdline-tools/bin:$ANDROID_HOME/platform-tools"

# Rust/Cargo
export PATH="$PATH:/usr/lib/cargo/bin/:$HOME/.cargo/bin"

# Composer
export PATH="$PATH:$HOME/.config/composer/vendor/bin"
