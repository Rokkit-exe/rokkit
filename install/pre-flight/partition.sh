#!/bin/bash

# Disk Partitioning Script for Arch Linux
# Creates EFI partition and btrfs root partition
PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "$ROOT_DIR/lib/print.sh"  

set -e

if [ ! -f "$ROOT_DIR/config/settings.conf" ]; then
    print_error "Error: ../config/settings.conf not found."
    exit 1
fi
source "$ROOT_DIR/config/settings.conf"

if [ -z "$DISK" ]; then
    print_error "Error: DISK is not set in ../config/settings.conf."
    exit 1
fi

print_info "Arch Linux Disk Partitioner"

if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
    exit 1
fi

# Verify disk exists
if [ ! -b "$DISK" ]; then
    print_error "disk $DISK does not exist."
    DISK=$(gum input --placeholder "Enter target disk (e.g., /dev/sda): ")
fi

# Show warning
print_warning "WARNING: This will ERASE all data on $DISK"
lsblk "$DISK"

confirm=$(choose "Confirm ?" "yes" "no")
if [ "$confirm" != "yes" ]; then
    print_info "Cancelled."
    exit 0
fi

print_info "Creating partitions on $DISK "

# Clear any existing partition tables
dd if=/dev/zero of="$DISK" bs=512 count=2048 2>/dev/null

# Create GPT partition table and partitions using parted
parted -s "$DISK" -- \
    mklabel gpt \
    mkpart primary fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart primary btrfs 513MiB 100%

print_success "Partitions created"

# Identify partition names (handles both /dev/sdX and /dev/nvmeXnYpZ)
if [[ $DISK == *nvme* ]]; then
    efi_part="${DISK}p1"
    root_part="${DISK}p2"
else
    efi_part="${DISK}1"
    root_part="${DISK}2"
fi

print_info "EFI partition: $efi_part"
print_info "Root partition: $root_part"

# Format EFI partition
print_info "Formatting EFI partition"
mkfs.fat -F 32 "$efi_part"
print_success "EFI partition formatted"

# Format btrfs root partition
print_info "Formatting btrfs root partition"
mkfs.btrfs -f "$root_part"
print_success "btrfs root partition formatted"

# Mount and create subvolumes
print_info "Creating btrfs subvolumes"
mount "$root_part" /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@log
#btrfs subvolume create /mnt/.snapshots

print_success "Subvolumes created:"
btrfs subvolume list /mnt
echo

umount /mnt
echo

# Mount with proper options
print_info "Mounting partitions"
mount -o subvol=@,compress=zstd "$root_part" /mnt
mkdir -p /mnt/{boot,home,var/cache/pacman/pkg,var/log,.snapshots}

mount -o subvol=@home,compress=zstd "$root_part" /mnt/home
mount -o subvol=@pkg,compress=zstd "$root_part" /mnt/var/cache/pacman/pkg
mount -o subvol=@log,compress=zstd "$root_part" /mnt/var/log
#mount -o subvol=@.snapshots,compress=zstd "$root_part" /mnt/.snapshots

mount "$efi_part" /mnt/boot

print_success "✓ Partitions mounted"

# Show mount status
print_info "Mount Status:"
mount | grep /mnt

# Get UUIDs for later
print_info "Partition Information"
echo "EFI Partition UUID:"
blkid "$efi_part"
echo
echo "Root Partition UUID:"
blkid "$root_part"
echo

print_success "Partitioning complete!"
echo "Ready to run: pacstrap /mnt base base-devel linux linux-firmware btrfs-progs"
