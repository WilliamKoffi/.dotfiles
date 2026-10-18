#!/bin/bash

ERROR='\033[0;31m'   # Error
SUCCESS='\033[0;32m' # Success
WARNING='\033[0;33m' # Warning
INFO='\033[0;34m'    # Info
NC='\033[0m'         # No Color (reset)

# Function to calculate the maximum width of the message type
get_max_type_width() {
    local types=("INFO" "WARNING" "ERROR" "SUCCESS")
    local max_length=0

    for t in "${types[@]}"; do
        local length=${#t}
        if ((length > max_length)); then
            max_length=$((length + 1))
        fi
    done

    # Return the maximum width for formatting
    echo $max_length
}

# Function to display messages
print_message() {
    local type="$1:"
    local message="$2"
    local color
    local max_width

    # Set color based on the type of message
    case "$type" in
    info:)
        color=$INFO
        ;;
    warning:)
        color=$WARNING
        ;;
    error:)
        color=$ERROR
        ;;
    success:)
        color=$SUCCESS
        ;;
    *)
        color=$NC
        ;;
    esac

    # Calculate the width for formatting
    max_width=$(get_max_type_width)

    # Format the message with consistent spacing after the colon
    printf "${color}%-${max_width}s${NC}   %s\n" "$(echo "$type" | tr '[:lower:]' '[:upper:]')" "$message"
}

# Usage example
# print_message info "This is an informational message."
# print_message warning "This is a warning message."
# print_message error "This is an error message."
# print_message success "This is a success message."

