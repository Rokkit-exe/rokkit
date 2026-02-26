#!/bin/bash

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh"

print_title "Running All chroot Installation Steps"

print_title "Setting Up keyboard layout"
./keyboard.sh

print_title "Setting Up locale"
./locale.sh

print_title "Setting Up timezone"
./timezone.sh

print_title "Setting Up initramfs"
./mkinitcpio.sh

print_title "Installing AUR helper"
./install-yay.sh

print_title "Installing additional packages"
#./install-packages.sh

print_title "Setting Up User Account"
./user.sh

print_title "Setting Up Bootloader"
./grub.sh

print_title "Setting Up Git"
./git.sh

print_title "Enable Services"
./services.sh

print_title "default Hyprland configuration"
./hyprland.sh
