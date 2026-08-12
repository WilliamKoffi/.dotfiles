# Add to PATH if not already present
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$PATH:$HOME/.local/bin"
[[ ":$PATH:" != *":$HOME/.local/share/nvim/mason/bin:"* ]] && export PATH="$PATH:$HOME/.local/share/nvim/mason/bin"

export DOTFILES_PATH="$HOME/.dotfiles"
export LOG_MESSAGE_PATH="$DOTFILES_PATH/scripts/.local/bin/log-message.sh"

# Android SDK
export ANDROID_HOME="$HOME/.android"
[[ ":$PATH:" != *":$ANDROID_HOME/cmdline-tools/bin:"* ]] && export PATH="$PATH:$ANDROID_HOME/cmdline-tools/bin"
[[ ":$PATH:" != *":$ANDROID_HOME/platform-tools:"* ]] && export PATH="$PATH:$ANDROID_HOME/platform-tools"

# Composer
[[ ":$PATH:" != *":$HOME/.config/composer/vendor/bin:"* ]] && export PATH="$PATH:$HOME/.config/composer/vendor/bin"

