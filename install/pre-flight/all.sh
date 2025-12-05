#!/bin/bash

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh" 

print_title "Checking Internet Connectivity"
# check internet connectivity
./connection.sh

print_title "Checking Requirements"
# Check for required commands and environment
./requirements.sh

print_title "Asking for User Input"
# Ask for user input (hostname, username, password, keyboard layout, locale, git config)
./settings.sh

print_title "Setting Up Disk Partitions and Filesystems"
# Set up disk partitions and filesystems
./partition.sh

print_title "Installing Base System"
# pacstrap (base system) ✓
./base-packages.sh

print_title "Configuring the New System"
# Generate fstab ✓
genfstab -U /mnt >> /mnt/etc/fstab
