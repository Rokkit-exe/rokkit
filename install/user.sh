#!/bin/bash


# Set hostname
echo "$HOST_NAME" > /etc/hostname
# Set root password
hash_root_pass=$(echo -n "$ROOT_PASS" | sha256sum | awk '{print $1}')
echo "root:$hash_root_pass" | chpasswd
# Create user account
useradd -m -G wheel "$USER_NAME"
echo "$USER_NAME:$PASSWORD" | chpasswd
# Set permissions for sudo
# Regenerate initramfs
mkinitcpio -P
# Enable Snapper for root
snapper -c root create-config /
# Configure sudoers to allow wheel group sudo without password
sed -i 's/^# %wheel ALL=(ALL:ALL) NOPASSWD: ALL/%wheel ALL=(ALL:ALL) NOPASSWD: ALL/' /etc/sudoers
