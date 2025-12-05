#!/bin/bash

# making sure all required commands are available

# check if vanilla arch linux iso
# if [ ! -f /etc/arch-release ]; then
#     echo "This script is intended to be run on a vanilla Arch Linux installation ISO."
#     exit 1
# fi
# if cat /etc/os-release | grep -q "Arch Linux"; then
#     echo "This script is intended to be run on a vanilla Arch Linux installation ISO."
#     exit 1
# fi

# check efi mode
if [ ! -d /sys/firmware/efi/efivars ]; then
    echo "This system is not booted in UEFI mode. Please boot in UEFI mode to proceed with the installation."
    exit 1
fi

# Install gum if not present
if ! command -v gum &> /dev/null; then
  sudo pacman -S --noconfirm gum
fi

if ! command -v git &> /dev/null; then
  sudo pacman -S --noconfirm git
fi

if ! command -v curl &> /dev/null; then
  sudo pacman -S --noconfirm curl
fi

if ! command -v jq &> /dev/null; then
  sudo pacman -S --noconfirm jq 
fi


