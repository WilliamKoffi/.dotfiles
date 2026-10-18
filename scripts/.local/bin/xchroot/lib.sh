#!/bin/bash

# Library: xchroot-lib
# Description: Core logic for the xchroot script. This file is intended to be
#              sourced by the main xchroot script and is not executable on its own.

# Source the logger utility
source "$(dirname "$0")/library:log.sh"

# --- Configuration ---
DEFAULT_CHROOT_DIR="/mnt/linux_chroot"
BTRFS_SUBVOL="@"
VIRTUAL_FS=("/dev" "/sys" "/proc" "/dev/pts" "/dev/shm")

# --- Helper Functions ---

# Centralized error handling.
die() {
    print_message error "$1"
    exit 1
}

# Checks for required commands.
check_dependencies() {
    print_message info "Checking for required commands..."
    for cmd in lsblk mountpoint sudo; do
        if ! command -v "$cmd" &> /dev/null; then
            die "'$cmd' command not found. Please install it."
        fi
    done
}

# Ensures the script is run with root privileges.
check_root() {
    if [[ $EUID -ne 0 ]]; then
        # Use a direct echo here since we might not have sourced the logger yet
        # or to avoid sourcing just for this check. A simple message is fine.
        echo "Error: This script must be run as root. Please use sudo."
        exit 1
    fi
}

# --- Core Mounting Functions ---

mount_main_partition() {
    local device="$1"
    local chroot_dir="$2"

    if mountpoint -q "$chroot_dir"; then
        print_message warning "${chroot_dir} is already mounted. Skipping."
        return 0
    fi

    print_message info "Detecting filesystem type for ${device}..."
    local fstype
    fstype=$(lsblk -fno FSTYPE "$device")
    [[ -z "$fstype" ]] && die "Could not determine filesystem type for ${device}."
    print_message info "Detected filesystem type: ${fstype}"

    print_message info "Mounting main partition ${device}..."
    case "$fstype" in
        btrfs)
            local mount_args=()
            if [[ -n "$BTRFS_SUBVOL" ]]; then
                mount_args+=("-o" "subvol=$BTRFS_SUBVOL")
                print_message info "Attempting to mount Btrfs with subvolume: $BTRFS_SUBVOL"
            fi
            mount "${mount_args[@]}" "$device" "$chroot_dir" || die "Failed to mount Btrfs partition ${device}."
            ;;
        ext4|xfs|f2fs)
            mount "$device" "$chroot_dir" || die "Failed to mount ${fstype} partition ${device}."
            ;;
        *)
            die "Unsupported filesystem type '${fstype}' on ${device}."
            ;;
    esac
    print_message success "Successfully mounted ${device} to ${chroot_dir}."
}

prepare_chroot_dirs() {
    local chroot_dir="$1"
    
    print_message info "Preparing chroot directories..."
    mkdir -p "$chroot_dir" || die "Failed to create main chroot directory: ${chroot_dir}."

    for fs in "${VIRTUAL_FS[@]}"; do
        mkdir -p "${chroot_dir}${fs}" || die "Could not create directory: ${chroot_dir}${fs}."
    done
    mkdir -p "${chroot_dir}/etc" || die "Could not create directory: ${chroot_dir}/etc."
}

mount_virtual_filesystems() {
    local chroot_dir="$1"

    print_message info "Setting up bind mounts..."
    for fs in "${VIRTUAL_FS[@]}"; do
        mount --bind "$fs" "${chroot_dir}${fs}" || die "Failed to bind mount ${fs}."
    done
    mount --bind /etc/resolv.conf "${chroot_dir}/etc/resolv.conf" || die "Failed to bind mount /etc/resolv.conf."
}

# --- Core Unmounting Functions ---

umount_virtual_filesystems() {
    local chroot_dir="$1"
    
    print_message info "Unmounting bind mounts..."
    local mounts_to_unmount=("${VIRTUAL_FS[@]}" "/etc/resolv.conf")

    for ((i=${#mounts_to_unmount[@]}-1; i>=0; i--)); do
        local mount_point="${chroot_dir}${mounts_to_unmount[i]}"
        if mountpoint -q "$mount_point"; then
            umount "$mount_point" && print_message success "Unmounted ${mount_point}" || print_message warning "Failed to unmount ${mount_point}"
        fi
    done
}

umount_main_partition() {
    local chroot_dir="$1"

    if mountpoint -q "$chroot_dir/boot/efi"; then
        umount "$chroot_dir/boot/efi" && print_message success "Unmounted ${chroot_dir}/boot/efi" || print_message warning "Failed to unmount ${chroot_dir}/boot/efi"
    fi

    print_message info "Unmounting main chroot partition ${chroot_dir}..."
    if mountpoint -q "$chroot_dir"; then
        umount "$chroot_dir" || die "Failed to unmount ${chroot_dir}. It may be busy."
        print_message success "Successfully unmounted ${chroot_dir}."
    else
        print_message warning "${chroot_dir} is not mounted."
    fi
}

# --- High-Level Interface Functions ---

do_mount() {
    local device="$1"
    local chroot_dir="${2:-$DEFAULT_CHROOT_DIR}"

    [[ -z "$device" ]] && die "DEVICE is required for the 'mount' command."

    print_message info "--- Starting chroot mount process ---"
    print_message info "Target directory: ${chroot_dir}"
    print_message info "Main device:      ${device}"

    prepare_chroot_dirs "$chroot_dir"
    mount_main_partition "$device" "$chroot_dir"
    mount_virtual_filesystems "$chroot_dir"

    print_message success "--- Chroot environment successfully mounted! ---"
    echo "You can now enter the chroot using: sudo chroot ${chroot_dir} /bin/bash"
}

do_umount() {
    local chroot_dir="${1:-$DEFAULT_CHROOT_DIR}"
    print_message info "--- Starting chroot unmount process ---"
    print_message info "Target directory: ${chroot_dir}"

    if ! mountpoint -q "$chroot_dir"; then
        print_message warning "${chroot_dir} is not mounted. Nothing to do."
        return 0
    fi

    umount_virtual_filesystems "$chroot_dir"
    umount_main_partition "$chroot_dir"
    
    print_message success "--- Chroot environment successfully unmounted! ---"
}
