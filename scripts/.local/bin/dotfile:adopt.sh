#!/bin/bash
# dotfile:adopt.sh
# Description: Moves a target file or directory into a dotfiles directory. 
# By default it preserves the relative path inside $HOME. With -i, only the 
# basename is kept. Then it creates a symlink back to the original location.
# Usage: ./dotfile:adopt.sh [-n] [-i] -t <target> -d <dotfiles_dir>

# --- Setup ---
source "$(dirname "$0")/library:log.sh"

# --- Default Flags ---
DRY_RUN=false
IGNORE_PATH=false

# --- Usage Function ---
print_usage() {
  cat <<EOF
Usage: $(basename "$0") [options] -t <target> -d <dotfiles_dir>

Options:
  -t <target>        Path to the file/directory you want to manage as a dotfile
  -d <dotfiles_dir>  Destination dotfiles directory
  -n                 Dry run mode (simulate actions without making changes)
  -i                 Ignore full path (store only the basename inside dotfiles dir)
  -h                 Show this help message and exit

Examples:
  $(basename "$0") -t ~/.bashrc -d ~/.dotfiles
  $(basename "$0") -n -i -t ~/lab/dev/app/config.php -d ~/.dotfiles/php
EOF
}

# --- Argument Parsing ---
while getopts "nhit:d:" opt; do
  case $opt in
    n) DRY_RUN=true ;;
    i) IGNORE_PATH=true ;;
    t) TARGET="$OPTARG" ;;
    d) DOTFILES_DIR="$OPTARG" ;;
    h) print_usage; exit 0 ;;
    *) print_usage; exit 1 ;;
  esac
done

# --- Validation ---
if [[ -z "$TARGET" || -z "$DOTFILES_DIR" ]]; then
  print_message error "Both -t (target) and -d (dotfiles directory) are required."
  print_usage
  exit 1
fi

# --- Dry Run ---
if [ "$DRY_RUN" = true ]; then
  print_message warning "--- DRY RUN MODE ---"
  print_message warning "No changes will be made to the filesystem."
fi

# --- Expand and validate target ---
EXPANDED_TARGET="${TARGET/#\~/$HOME}"
if [[ ! -e "$EXPANDED_TARGET" ]]; then
  print_message error "Target '$EXPANDED_TARGET' does not exist."
  exit 1
fi
TARGET_ABS=$(readlink -f "$EXPANDED_TARGET")

# --- Resolve dotfiles dir (fallback if nonexistent) ---
DOTFILES_DIR_ABS=$(readlink -f "${DOTFILES_DIR/#\~/$HOME}" || echo "${DOTFILES_DIR/#\~/$HOME}")

# --- Build relative path ---
if [ "$IGNORE_PATH" = true ]; then
  RELATIVE_PATH=$(basename "$TARGET_ABS")
else
  RELATIVE_PATH="${TARGET_ABS#$HOME/}"
  if [[ "$RELATIVE_PATH" == "$TARGET_ABS" ]]; then
    print_message error "Target must be inside your home directory unless -i is used."
    exit 1
  fi
fi

DEST_PATH="$DOTFILES_DIR_ABS/$RELATIVE_PATH"
DEST_PARENT_DIR=$(dirname "$DEST_PATH")

# --- Abort if destination already exists ---
if [[ -e "$DEST_PATH" ]]; then
  print_message error "Destination '$DEST_PATH' already exists."
  exit 1
fi

# --- Create parent directory ---
if [ "$DRY_RUN" = true ]; then
  print_message info "[DRY RUN] Would create directory: $DEST_PARENT_DIR"
else
  mkdir -p "$DEST_PARENT_DIR" || {
    print_message error "Failed to create directory '$DEST_PARENT_DIR'."
    exit 1
  }
  print_message success "Created directory: $DEST_PARENT_DIR"
fi

# --- Move target ---
if [ "$DRY_RUN" = true ]; then
  print_message info "[DRY RUN] Would move '$TARGET_ABS' to '$DEST_PATH'"
else
  mv "$TARGET_ABS" "$DEST_PATH" || {
    print_message error "Failed to move '$TARGET_ABS'."
    exit 1
  }
  print_message success "Moved: $TARGET_ABS -> $DEST_PATH"
fi

# --- Create symlink ---
if [ "$DRY_RUN" = true ]; then
  print_message info "[DRY RUN] Would symlink: $TARGET_ABS -> $DEST_PATH"
  print_message success "Dry run complete."
  exit 0
fi

ln -s "$DEST_PATH" "$TARGET_ABS" || {
  print_message error "Failed to create symlink. Rolling back..."
  mv "$DEST_PATH" "$TARGET_ABS" && {
    print_message success "Rollback successful. Original file restored."
    exit 1
  }
  print_message error "CRITICAL: Rollback failed. File remains at '$DEST_PATH'."
  exit 1
}

print_message success "Symlink created: $TARGET_ABS -> $DEST_PATH"
print_message success "Dotfile setup complete for '$RELATIVE_PATH'."
