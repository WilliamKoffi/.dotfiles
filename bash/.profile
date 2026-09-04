# ~/.profile: executed by the command interpreter for login shells.
# This file is not read by bash(1), if ~/.bash_profile or ~/.bash_login
# exists.
# see /usr/share/doc/bash/examples/startup-files for examples.
# the files are located in the bash-doc package.

# the default umask is set in /etc/profile; for setting the umask
# for ssh logins, install and configure the libpam-umask package.
#umask 022

# if running bash
if [ -n "$BASH_VERSION" ]; then
    # include .bashrc if it exists
    if [ -f "$HOME/.bashrc" ]; then
	. "$HOME/.bashrc"
    fi
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/bin" ] ; then
    [[ ":$PATH:" != *":$HOME/bin:"* ]] && PATH="$HOME/bin:$PATH"
fi

# set PATH so it includes user's private bin if it exists
if [ -d "$HOME/.local/bin" ] ; then
    [[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && PATH="$HOME/.local/bin:$PATH"
fi

if [ -f "$HOME/.cargo/env" ]; then
    . "$HOME/.cargo/env"
fi

# Added by Antigravity CLI installer
[[ ":$PATH:" != *":$HOME/.local/bin:"* ]] && export PATH="$HOME/.local/bin:$PATH"

# Flutter
if [ -d "$HOME/.flutter/bin" ]; then
    [[ ":$PATH:" != *":$HOME/.flutter/bin:"* ]] && export PATH="$PATH:$HOME/.flutter/bin"
fi

# Go
if [ -d "$HOME/go/bin" ]; then
    [[ ":$PATH:" != *":$HOME/go/bin:"* ]] && export PATH="$PATH:$HOME/go/bin"
fi

# Gradle (kept manual: /opt/gradle 9.3.1 is newer than nixpkgs' 8.14.4)
if [ -d "/opt/gradle/gradle-9.3.1/bin" ]; then
    [[ ":$PATH:" != *":/opt/gradle/gradle-9.3.1/bin:"* ]] && export PATH="$PATH:/opt/gradle/gradle-9.3.1/bin"
fi

# pnpm (binary is from Nix; this is only for `pnpm add -g` globals)
export PNPM_HOME="$HOME/.local/share/pnpm"
[[ ":$PATH:" != *":$PNPM_HOME/bin:"* ]] && export PATH="$PNPM_HOME/bin:$PATH"

# Nix
if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
  unset __ETC_PROFILE_NIX_SOURCED
  . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
fi
if [ -d "$HOME/.nix-profile/bin" ]; then
    [[ ":$PATH:" != *":$HOME/.nix-profile/bin:"* ]] && export PATH="$HOME/.nix-profile/bin:$PATH"
fi
