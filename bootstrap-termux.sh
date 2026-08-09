#!/data/data/com.termux/files/usr/bin/bash
# Bootstrap ~/.dotfiles on Termux (Android). Run inside the Termux app:
#   curl -fsSL https://raw.githubusercontent.com/WilliamKoffi/.dotfiles/main/bootstrap-termux.sh | bash
# or, if already cloned:
#   bash ~/.dotfiles/bootstrap-termux.sh
set -e

pkg update -y
pkg install -y git stow zsh neovim vim bat git-delta eza fzf php nodejs openssh

if [ ! -d "$HOME/.dotfiles" ]; then
    git clone https://github.com/WilliamKoffi/.dotfiles.git "$HOME/.dotfiles"
fi
cd "$HOME/.dotfiles"

# CLI-only subset. Deliberately skipped: hyprland, niri, ironbar, mako, rofi,
# rio, swaylock, waybar, windsurf, code, zed — all Wayland/X11 desktop tools
# with nothing to run them under on Android. hooks/ (systemd service
# management) is skipped entirely for the same reason.
stow bash bat claude gemini git nvim qwen vim zsh

# scripts/: xchroot.sh (needs root chroot) and disable-services.sh (needs
# systemd) don't apply on Termux, but are harmless dead weight if stowed —
# they'd just fail with "command not found" if run, not misbehave silently.
stow scripts

echo "Stowed. Run 'exec zsh' (or restart Termux) to pick up the new shell config."
