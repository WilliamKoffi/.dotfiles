#!/bin/bash
# zip.sh
# Description: Generic project packager that archives full project directories
#              or git commit changes, optionally respecting .zipignore rules.

set -eo pipefail

# --- Setup Logging ---
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" 2>/dev/null || echo "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

if [[ -f "$SCRIPT_DIR/library:log.sh" ]]; then
    source "$SCRIPT_DIR/library:log.sh"
elif [[ -n "$LOG_MESSAGE_PATH" && -f "$LOG_MESSAGE_PATH" ]]; then
    source "$LOG_MESSAGE_PATH"
elif [[ -f "$HOME/.dotfiles/scripts/.local/bin/library:log.sh" ]]; then
    source "$HOME/.dotfiles/scripts/.local/bin/library:log.sh"
elif [[ -f "$HOME/.local/bin/library:log.sh" ]]; then
    source "$HOME/.local/bin/library:log.sh"
else
    # Fallback message printer with ANSI colors
    print_message() {
        local level="$1"
        shift
        local msg="$*"
        local RED='\033[0;31m' GREEN='\033[0;32m' YELLOW='\033[0;33m' BLUE='\033[0;34m' NC='\033[0m'
        case "$level" in
            info)    printf "${BLUE}%-9s${NC}   %s\n" "INFO:" "$msg" ;;
            success) printf "${GREEN}%-9s${NC}   %s\n" "SUCCESS:" "$msg" ;;
            warning) printf "${YELLOW}%-9s${NC}   %s\n" "WARNING:" "$msg" ;;
            error)   printf "${RED}%-9s${NC}   %s\n" "ERROR:" "$msg" >&2 ;;
            *)       printf "%-9s   %s\n" "$level:" "$msg" ;;
        esac
    }
fi

# --- Usage Message ---
print_usage() {
    cat <<EOF
Usage: $(basename "$0") [mode] [options] [commit-ref]

A generic project packaging tool that archives project files or recent git changes,
optionally respecting .zipignore rules.

Modes:
  all                  Zip the entire project directory (excludes .zipignore rules if present,
                       or packages all files if .zipignore is absent).
  recent               Zip only files added/modified in a git commit (default: HEAD).
                       Respects .zipignore if present.
  since                Zip files added/modified since the last zip (committed, uncommitted
                       and untracked). Respects .zipignore if present.

Every zip records its time and git commit in ~/.zip-state/<folder>/last-zip
(override the base with ZIP_STATE_DIR).

Options:
  -o, --output <file>  Specify custom output archive name or path.
  -c, --commit <ref>   Git commit or ref for 'recent' mode (default: HEAD).
  -d, --dir <path>     Target directory to archive (default: git root or current directory).
  -h, --help           Display this help message and exit.

Examples:
  $(basename "$0") all
  $(basename "$0") all -o build.zip
  $(basename "$0") all -d /path/to/project
  $(basename "$0") recent
  $(basename "$0") recent HEAD~1
  $(basename "$0") recent -c a1b2c3d -o patch.zip
  $(basename "$0") since
EOF
}

MODE=""
COMMIT_REF="HEAD"
CUSTOM_OUTPUT=""
TARGET_DIR=""

# --- Argument Parsing ---
while [[ $# -gt 0 ]]; do
    case "$1" in
        all|recent|since)
            MODE="$1"
            shift
            ;;
        -o|--output)
            CUSTOM_OUTPUT="$2"
            shift 2
            ;;
        -c|--commit)
            COMMIT_REF="$2"
            shift 2
            ;;
        -d|--dir)
            TARGET_DIR="$2"
            shift 2
            ;;
        -h|--help)
            print_usage
            exit 0
            ;;
        *)
            if [[ "$MODE" == "recent" && "$COMMIT_REF" == "HEAD" ]]; then
                COMMIT_REF="$1"
                shift
            else
                print_message error "Unknown argument: $1"
                print_usage
                exit 1
            fi
            ;;
    esac
done

# --- Resolve Target Directory ---
if [[ -n "$TARGET_DIR" ]]; then
    if [[ ! -d "$TARGET_DIR" ]]; then
        print_message error "Target directory '$TARGET_DIR' does not exist."
        exit 1
    fi
    cd "$TARGET_DIR" || exit 1
else
    # Default to Git repository root if inside git worktree, otherwise current directory
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        GIT_ROOT="$(git rev-parse --show-toplevel)"
        cd "$GIT_ROOT" || exit 1
    fi
fi

BASE_DIR_NAME="$(basename "$PWD")"
ZIPIGNORE_FILE=".zipignore"
STATE_DIR="${ZIP_STATE_DIR:-$HOME/.zip-state}/$BASE_DIR_NAME"
STATE_FILE="$STATE_DIR/last-zip"

# --- Record when (and at which git commit) the last archive was made, and keep a copy of it ---
record_last_zip() {
    local archive="$1" mode="$2" commit=""
    [[ -f "$archive" ]] || return 0
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        commit="$(git rev-parse HEAD 2>/dev/null || true)"
    fi
    mkdir -p "$STATE_DIR"
    cp -f "$archive" "$STATE_DIR/last.zip"
    cat > "$STATE_FILE" <<EOF
time=$(date -Iseconds)
commit=$commit
mode=$mode
dir=$PWD
archive=$(readlink -f "$archive")
copy=$STATE_DIR/last.zip
EOF
    print_message info "Last zip recorded in: $STATE_DIR (commit ${commit:0:7})"
}

# --- Read the commit recorded by the last archive ---
last_zip_commit() {
    [[ -f "$STATE_FILE" ]] || return 1
    sed -n 's/^commit=//p' "$STATE_FILE"
}

# --- Ignore Pattern Handling ---
zipignore_patterns=()
load_zipignore_patterns() {
    zipignore_patterns=(".zipignore" "*.zip")

    if [[ -f "$ZIPIGNORE_FILE" ]]; then
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Trim leading and trailing whitespace
            line="${line#"${line%%[![:space:]]*}"}"
            line="${line%"${line##*[![:space:]]}"}"

            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^# ]] && continue

            zipignore_patterns+=("$line")
        done < "$ZIPIGNORE_FILE"
    fi
}

is_ignored() {
    local file="$1"
    local base_name="${file##*/}"

    for pattern in "${zipignore_patterns[@]}"; do
        # Strip trailing slash if any
        local dir_pattern="${pattern%/}"

        # Match exact file or directory prefix (e.g. node_modules or public/storage)
        if [[ "$file" == "$dir_pattern" || "$file" == "$dir_pattern"/* ]]; then
            return 0
        fi

        # If pattern ends with /*, match prefix
        if [[ "$pattern" == *"/*" ]]; then
            local prefix="${pattern%/*}"
            if [[ "$file" == "$prefix"/* ]]; then
                return 0
            fi
        fi

        # Glob pattern matching against full relative path
        if [[ "$file" == $pattern ]]; then
            return 0
        fi

        # If no slash in pattern, also match against basename (e.g. *.zip, .DS_Store)
        if [[ "$pattern" != *"/"* ]]; then
            if [[ "$base_name" == $pattern ]]; then
                return 0
            fi
        fi
    done

    return 1
}

# --- Mode: ALL ---
zip_all() {
    local output_zip="${CUSTOM_OUTPUT:-${BASE_DIR_NAME}.zip}"
    rm -f "$output_zip"

    print_message info "Creating full archive of '$PWD' into '$output_zip'..."

    if [[ -f "$ZIPIGNORE_FILE" ]]; then
        print_message info "Found $ZIPIGNORE_FILE, applying exclude rules..."
        zip -r "$output_zip" . -x "$output_zip" "*.zip" -x @"$ZIPIGNORE_FILE"
    else
        print_message info "No $ZIPIGNORE_FILE found. Archiving all project files..."
        zip -r "$output_zip" . -x "$output_zip" "*.zip"
    fi

    print_message success "Archive created: $output_zip"
    record_last_zip "$output_zip" all
}

# --- Mode: RECENT ---
zip_recent_changes() {
    local commit_ref="$1"
    local output_zip="${CUSTOM_OUTPUT:-${BASE_DIR_NAME}_recent.zip}"
    rm -f "$output_zip"

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_message error "Not inside a git repository. 'recent' mode requires git."
        exit 1
    fi

    if ! git rev-parse --verify "$commit_ref" >/dev/null 2>&1; then
        print_message error "Git commit or reference '$commit_ref' not found."
        return 1
    fi

    local commit_info
    commit_info=$(git log -1 --oneline "$commit_ref" 2>/dev/null)
    print_message info "Finding files changed in commit [$commit_info]..."

    load_zipignore_patterns

    local exclude_args=()
    if [[ -f "$ZIPIGNORE_FILE" ]]; then
        exclude_args+=(--exclude @"$ZIPIGNORE_FILE")
    fi

    mapfile -t files < <(git diff-tree -r --root --no-commit-id --name-only --diff-filter=ACMR "$commit_ref")

    if [[ ${#files[@]} -eq 0 ]]; then
        print_message warning "No added or modified files found in commit '$commit_ref'."
        return 0
    fi

    local filtered_files=()
    for file in "${files[@]}"; do
        if [[ -f "$file" ]]; then
            if ! is_ignored "$file"; then
                filtered_files+=("$file")
            fi
        fi
    done

    if [[ ${#filtered_files[@]} -eq 0 ]]; then
        print_message warning "No files to package for commit '$commit_ref' (all changes were ignored by .zipignore or deleted)."
        return 0
    fi

    print_message info "Packaging ${#filtered_files[@]} file(s)..."
    if zip -FS "$output_zip" "${filtered_files[@]}" "${exclude_args[@]}"; then
        print_message success "Commit files zipped into: $output_zip"
        record_last_zip "$output_zip" recent
    else
        print_message error "Failed to create $output_zip"
        return 1
    fi
}

# --- Mode: SINCE ---
# Zips every file added or modified since the commit recorded by the last zip,
# including uncommitted and untracked changes.
zip_since_last() {
    local output_zip="${CUSTOM_OUTPUT:-${BASE_DIR_NAME}_since.zip}"
    rm -f "$output_zip"

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        print_message error "Not inside a git repository. 'since' mode requires git."
        exit 1
    fi

    local base_commit
    base_commit="$(last_zip_commit)" || true
    if [[ -z "$base_commit" ]] || ! git rev-parse --verify "$base_commit^{commit}" >/dev/null 2>&1; then
        print_message error "No usable last zip recorded in $STATE_FILE. Run 'all' first."
        exit 1
    fi

    print_message info "Last zip: $(sed -n 's/^time=//p' "$STATE_FILE") at [$(git log -1 --oneline "$base_commit")]"
    print_message info "Finding files changed since then..."

    load_zipignore_patterns

    local exclude_args=()
    if [[ -f "$ZIPIGNORE_FILE" ]]; then
        exclude_args+=(--exclude @"$ZIPIGNORE_FILE")
    fi

    mapfile -t files < <(
        {
            git diff --name-only --diff-filter=ACMR "$base_commit"
            git ls-files --others --exclude-standard
        } | sort -u
    )

    local filtered_files=()
    for file in "${files[@]}"; do
        if [[ -f "$file" ]] && ! is_ignored "$file"; then
            filtered_files+=("$file")
        fi
    done

    if [[ ${#filtered_files[@]} -eq 0 ]]; then
        print_message warning "Nothing changed since the last zip."
        return 0
    fi

    print_message info "Packaging ${#filtered_files[@]} file(s)..."
    if zip -FS "$output_zip" "${filtered_files[@]}" "${exclude_args[@]}"; then
        print_message success "Changes since last zip saved into: $output_zip"
        record_last_zip "$output_zip" since
    else
        print_message error "Failed to create $output_zip"
        return 1
    fi
}

# --- Execution ---
if [[ -z "$MODE" ]]; then
    echo "Please select a packaging mode:"
    select MODE in "all" "recent" "since"; do
        case "$MODE" in
            all)
                zip_all
                break
                ;;
            recent)
                zip_recent_changes "$COMMIT_REF"
                break
                ;;
            since)
                zip_since_last
                break
                ;;
            *)
                echo "Invalid selection. Choose 1 for 'all', 2 for 'recent' or 3 for 'since'."
                ;;
        esac
    done
else
    case "$MODE" in
        all)
            zip_all
            ;;
        recent)
            zip_recent_changes "$COMMIT_REF"
            ;;
        since)
            zip_since_last
            ;;
        *)
            print_usage
            exit 1
            ;;
    esac
fi
