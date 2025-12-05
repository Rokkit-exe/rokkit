#!/bin/bash
# Disk Partitioning Script for Arch Linux
# Creates EFI partition and btrfs root partition with subvolumes

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "$ROOT_DIR/lib/print.sh"  

set -e

# Load configuration
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

# Check root privileges
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
    exit 1
fi

# Verify disk exists
if [ ! -b "$DISK" ]; then
    print_error "Disk $DISK does not exist."
    DISK=$(gum input --placeholder "Enter target disk (e.g., /dev/sda): ")
    
    if [ ! -b "$DISK" ]; then
        print_error "Disk $DISK still does not exist."
        exit 1
    fi
fi

# Show warning
print_warning "WARNING: This will ERASE all data on $DISK"
echo
lsblk "$DISK"
echo

confirm=$(choose "Confirm ?" "yes" "no")
if [ "$confirm" != "yes" ]; then
    print_info "Cancelled."
    exit 0
fi

print_info "Wiping existing partition tables and signatures on $DISK"
wipefs -af "$DISK"
sync
print_success "Disk wiped"

print_info "Creating partitions on $DISK"
# Create GPT partition table and partitions using parted
parted -s "$DISK" -- \
    mklabel gpt \
    mkpart primary fat32 1MiB 513MiB \
    set 1 esp on \
    mkpart primary btrfs 513MiB 100%

# Inform kernel of partition changes
partprobe "$DISK"
sleep 1

print_success "Partitions created"

# Identify partition names (handles both /dev/sdX and /dev/nvmeXnYpZ)
if [[ $DISK == *nvme* ]] || [[ $DISK == *mmcblk* ]]; then
    efi_part="${DISK}p1"
    root_part="${DISK}p2"
else
    efi_part="${DISK}1"
    root_part="${DISK}2"
fi

# Verify partitions were created
if [ ! -b "$efi_part" ] || [ ! -b "$root_part" ]; then
    print_error "Partitions were not created successfully"
    print_error "Expected: $efi_part and $root_part"
    lsblk "$DISK"
    exit 1
fi

print_info "EFI partition: $efi_part"
print_info "Root partition: $root_part"
echo

# Format EFI partition
print_info "Formatting EFI partition"
mkfs.fat -F 32 "$efi_part"
print_success "EFI partition formatted"

# Format btrfs root partition
print_info "Formatting btrfs root partition"
mkfs.btrfs -f "$root_part"
print_success "Btrfs root partition formatted"

# Mount and create subvolumes
print_info "Creating btrfs subvolumes"
mount "$root_part" /mnt

btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@snapshots
btrfs subvolume create /mnt/@pkg
btrfs subvolume create /mnt/@log

print_success "Subvolumes created:"
btrfs subvolume list /mnt
echo

umount /mnt
echo

# Mount with proper options
print_info "Mounting partitions with optimized options"

BTRFS_OPTS="compress=zstd,noatime,space_cache=v2"

mount -o "subvol=@,$BTRFS_OPTS" "$root_part" /mnt

mkdir -p /mnt/{boot,home,.snapshots,var/cache/pacman/pkg,var/log}

mount -o "subvol=@home,$BTRFS_OPTS" "$root_part" /mnt/home
mount -o "subvol=@snapshots,$BTRFS_OPTS" "$root_part" /mnt/.snapshots
mount -o "subvol=@pkg,$BTRFS_OPTS" "$root_part" /mnt/var/cache/pacman/pkg
mount -o "subvol=@log,$BTRFS_OPTS" "$root_part" /mnt/var/log

mount "$efi_part" /mnt/boot

print_success "Partitions mounted"
echo

# Show mount status
print_info "Mount Status:"
mount | grep /mnt
echo

# Get and display UUIDs
EFI_UUID=$(blkid -s UUID -o value "$efi_part")
ROOT_UUID=$(blkid -s UUID -o value "$root_part")

print_info "Partition Information"
echo "EFI Partition:  $efi_part"
echo "UUID:           $EFI_UUID"
echo
echo "Root Partition: $root_part"
echo "UUID:           $ROOT_UUID"
echo

# Save UUIDs to a file for later use
mkdir -p "$ROOT_DIR/tmp"
cat > "$ROOT_DIR/tmp/partition_info.sh" <<EOF
# Generated partition information
export EFI_PARTITION="$efi_part"
export ROOT_PARTITION="$root_part"
export EFI_UUID="$EFI_UUID"
export ROOT_UUID="$ROOT_UUID"
export DISK="$DISK"
EOF

print_success "Partition info saved to $ROOT_DIR/tmp/partition_info.sh"
echo

print_success "Partitioning complete!"

