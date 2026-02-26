#!/bin/bash

#!/bin/bash
# Configure mkinitcpio for GRUB with btrfs support
# Suitable for btrfs + Timeshift + Hyprland systems

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh"

set -e

# Check root privileges
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
    exit 1
fi

print_info "Configuring mkinitcpio for btrfs system"

HOOKS="(base udev autodetect microcode modconf kms keyboard keymap consolefont block btrfs filesystems fsck)"
MODULES="btrfs amdgpu"

# Configure mkinitcpio for grub with btrfs support
sed -i "s/^HOOKS=.*/HOOKS=$HOOKS/" /etc/mkinitcpio.conf
sed -i "s/^MODULES=.*/MODULES=($MODULES)/" /etc/mkinitcpio.conf

if mkinitcpio -P; then
    print_success "Initramfs regenerated successfully"
else
    print_error "Failed to regenerate initramfs"
    exit 1
fi

