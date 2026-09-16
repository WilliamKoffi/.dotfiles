# ~/.zprofile: Sourced by zsh login shells and display managers (like SDDM)

# Source the system-wide profile to load Nix and other environment variables
if [ -f /etc/profile ]; then
    . /etc/profile
fi

# Source the user's .profile if it exists
if [ -f "$HOME/.profile" ]; then
    . "$HOME/.profile"
fi
