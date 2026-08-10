#!/bin/bash
# git-commit-folders.sh
# Description: Groups unstaged/staged/untracked changes in a Git repository by their top-level folder
#              and commits each folder's changes individually.

# --- Setup & Imports ---
SCRIPT_DIR="$(dirname "$0")"
if [[ -f "$SCRIPT_DIR/log-message.sh" ]]; then
  source "$SCRIPT_DIR/log-message.sh"
else
  print_message() {
    echo "[$1] $2"
  }
fi

# --- Early Verification: Ensure Inside Git Repo ---
check_git_repo() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    print_message error "Not inside a git repository."
    exit 1
  fi
}

check_git_repo

# Go to git root directory
GIT_ROOT=$(git rev-parse --show-toplevel)
cd "$GIT_ROOT" || exit 1

# --- Helper Functions ---
get_changed_paths() {
  git status --porcelain | awk '{print $2}' | sed 's/^"//; s/"$//'
}

# --- Core Logic ---
commit_grouped_changes() {
  local changed_files
  changed_files=$(get_changed_paths)
  if [[ -z "$changed_files" ]]; then
    print_message info "No changes to commit."
    return 0
  fi

  # Store top-level groups in an associative array
  declare -A groups
  while read -r file; do
    [[ -z "$file" ]] && continue
    local top
    top=$(echo "$file" | cut -d'/' -f1)
    groups["$top"]=1
  done <<< "$changed_files"

  # Commit each group separately
  for group in "${!groups[@]}"; do
    print_message info "Processing changes in: '$group'"

    # Stage the changes for this group
    if [[ ! -e "$group" ]]; then
      git add -u "$group"
    else
      git add "$group"
    fi

    # Check if staging was successful/contains changes
    if git diff --cached --quiet -- "$group"; then
      print_message warning "No staged changes found to commit for '$group'"
      continue
    fi

    # Build commit message
    local msg="feat($group): update configs"
    if [[ ! -d "$group" ]]; then
      msg="feat(root): update $group"
    fi

    # Commit
    print_message info "Committing changes with message: '$msg'"
    if git commit -m "$msg"; then
      print_message success "Successfully committed changes for '$group'"
    else
      print_message error "Failed to commit changes for '$group'"
      return 1
    fi
  done

  return 0
}

commit_grouped_changes
