#!/bin/bash

# Script: xchroot
# Description: A user-friendly command-line interface for mounting and unmounting
#              Linux chroot environments. It sources a library for its core logic.

# --- Setup ---
# Get the directory where the script is located.
SCRIPT_DIR="$(dirname "$0")"

# Source the necessary libraries for core logic and logging.
source "${SCRIPT_DIR}/library:log.sh"
source "${SCRIPT_DIR}/xchroot/lib.sh"

# --- Functions ---

# Function to display the help message.
show_help() {
    echo "Usage: $(basename "$0") [command] [OPTIONS]"
    echo ""
    echo "A helper script to easily mount and unmount Linux chroot environments."
    echo ""
    echo "Commands:"
    echo "  mount DEVICE [MOUNT_POINT]   Mounts the specified device."
    echo "                               If MOUNT_POINT is not provided, it defaults to"
    echo "                               '${DEFAULT_CHROOT_DIR}'."
    echo ""
    echo "  umount [MOUNT_POINT]         Unmounts the chroot environment."
    echo "                               If MOUNT_POINT is not provided, it defaults to"
    echo "                               '${DEFAULT_CHROOT_DIR}'."
    echo ""
    echo "  -h, --help                   Displays this help message."
    echo ""
    echo "Examples:"
    echo "  sudo $(basename "$0") mount /dev/sda1"
    echo "  sudo $(basename "$0") umount /mnt/my_chroot"
}

# --- Main Script Logic ---

# Perform initial checks before proceeding.
check_root
check_dependencies

# Parse the main command.
case "$1" in
    mount)
        # Call the main mount function from the library.
        # Pass the device ($2) and optional mount point ($3).
        do_mount "$2" "$3"
        ;;
    umount)
        # Call the main unmount function from the library.
        # Pass the optional mount point ($2).
        do_umount "$2"
        ;;
    -h|--help)
        show_help
        ;;
    "")
        # Handle case where no command is provided.
        print_message error "No command specified."
        show_help
        exit 1
        ;;
    *)
        # Handle invalid commands.
        print_message error "Invalid command: '$1'"
        show_help
        exit 1
        ;;
esac
