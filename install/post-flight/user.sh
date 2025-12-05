#!/bin/bash

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh"
set -e

if [ ! -f "$ROOT_DIR/config/settings.conf" ]; then
    print_error "$ROOT_DIR/config/settings.conf not found."
    exit 1
fi
source "$ROOT_DIR/config/settings.conf"


if [ -z "$HOST_NAME" ] || [ -z "$ROOT_PASS" ] || [ -z "$USER_NAME" ] || [ -z "$PASSWORD" ]; then
    echo "One or more required settings are missing in ../config/settings.conf."
    exit 1
fi

# Set hostname
echo "$HOST_NAME" > /etc/hostname
# Set root password
hash_root_pass=$(echo -n "$ROOT_PASS" | sha256sum | awk '{print $1}')
echo "root:$hash_root_pass" | chpasswd
# Create user account
useradd -m -G wheel -s /bin/zsh "$USER_NAME"
echo "$USER_NAME:$PASSWORD" | chpasswd
# Configure sudoers to allow wheel group sudo without password
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
