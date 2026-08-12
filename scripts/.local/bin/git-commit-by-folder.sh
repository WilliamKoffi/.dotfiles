#!/usr/bin/env bash
# git-commit-by-folder: commits all modified/untracked files grouped by their top-level folder

set -euo pipefail

# Ensure we are in a git repository
is_git_repository() {
  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "Error: Not a git repository." >&2
    return 1
  fi
}

# Check if there are any changes to commit
has_changes() {
  if [[ -z "$(git status --porcelain)" ]]; then
    echo "No changes to commit."
    return 1
  fi
}

# Commit changes for a specific folder/group
commit_group() {
  local group="$1"
  
  if [[ "$group" == "root" ]]; then
    # Stage untracked/modified files in root directory specifically
    # to avoid staging other folders
    git status --porcelain | sed -E 's/^.{3}//' | while read -r filepath; do
      if [[ "$filepath" != *"/"* ]]; then
        git add "$filepath"
      fi
    done
    git commit -m "chore: update root level files"
    return
  fi

  # Normal folder group
  git add "$group"
  git commit -m "chore(${group}): update config"
}

main() {
  is_git_repository || return 1
  has_changes || return 0

  # Get list of top-level folders/groups containing changes
  local groups
  groups=$(git status --porcelain | sed -E 's/^.{3}//' | while read -r filepath; do
    if [[ "$filepath" == *"/"* ]]; then
      echo "${filepath%%/*}"
    else
      echo "root"
    fi
  done | sort -u)

  for group in $groups; do
    echo "Committing changes for: $group"
    commit_group "$group"
  done
}

main "$@"
