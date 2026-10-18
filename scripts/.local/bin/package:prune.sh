#!/bin/bash

. $LOG_MESSAGE_PATH

# Default settings
VERBOSE=false
DELETE=false
TARGET_PATH=""

# Help function
show_help() {
    cat << EOF
Usage: ${0##*/} [OPTIONS] PATH

Search for directories in the specified path, optionally filtering and deleting them.

Arguments:
  PATH                Target directory to search (required)

Options:
  -d, --delete        Enable delete mode (will prompt for confirmation)
  -v, --verbose       Show detailed information during execution
  -h, --help          Display this help message and exit

Examples:
  ${0##*/} /path/to/search       # Search in /path/to/search
  ${0##*/} -d -v /path/to/search # Enable delete mode with verbose output
  ${0##*/} --help                # Show this help message
EOF
    exit 0
}

# Parse command line arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -d|--delete)
            DELETE=true
            shift
            ;;
        -*)
            print_message error "Unknown option: $1"
            echo "Use '${0##*/} --help' for usage information."
            exit 1
            ;;
        *)
            # The first non-option argument is the path
            if [ -z "$TARGET_PATH" ]; then
                TARGET_PATH="$1"
            else
                print_message error "Unexpected argument: $1"
                echo "Use '${0##*/} --help' for usage information."
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate that a path was provided
if [ -z "$TARGET_PATH" ]; then
    print_message error "Error: No target directory specified"
    echo "Use '${0##*/} --help' for usage information."
    exit 1
fi

# Ensure TARGET_PATH exists and is a directory
if [ ! -d "$TARGET_PATH" ]; then
    print_message error "Error: Directory does not exist: $TARGET_PATH"
    exit 1
fi

# Ensure TARGET_PATH ends with a slash
[[ "$TARGET_PATH" != */ ]] && TARGET_PATH="$TARGET_PATH/"

BASE_DIR="$TARGET_PATH"

declare -a EXCLUDE_KEYWORDS=("resources" "public")

declare -a filtered_paths

print_message info "Starting directory search in: $BASE_DIR"
print_message info "---"

while IFS= read -r -d $'\0' current_dir_path; do

    parent_dir_path=$(dirname "$current_dir_path")

    if [[ "$parent_dir_path" =~ (^|/)(vendor|node_modules)/ ]]; then
        $VERBOSE && print_message warning "Skipping nested directory: $current_dir_path (parent contains vendor/node_modules)"
        continue
    fi

    should_skip_due_to_keyword=false
    for keyword in "${EXCLUDE_KEYWORDS[@]}"; do
        if [[ "$current_dir_path" =~ "$keyword" ]]; then
            should_skip_due_to_keyword=true
            break
        fi
    done

    if "$should_skip_due_to_keyword"; then
        $VERBOSE && print_message warning "Skipping directory containing an excluded keyword: $current_dir_path"
        continue
    fi

    filtered_paths+=("$current_dir_path")
    print_message success "Found and added: $current_dir_path"

done < <(find "$BASE_DIR" -type d \( -name "vendor" -o -name "node_modules" \) -print0)

echo "---"

if [ ${#filtered_paths[@]} -eq 0 ]; then
    print_message error "No directories matched all criteria in '$BASE_DIR'."
else
    print_message info "Successfully filtered directories:"
    for path in "${filtered_paths[@]}"; do
        if [ "$DELETE" = true ]; then
            print_message warning "Deleting directory: $path"
            rm -rf "$path"
        else
            print_message warning "Would delete directory: $path"
        fi
    done
fi

print_message info "--- Script finished ---"
