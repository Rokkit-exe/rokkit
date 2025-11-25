#!/bin/bash


# Create Limine config
UUID=$(lsblk /dev/"$DISK" -no UUID | head -n 1)
echo "Using UUID: $UUID"

cat > /boot/limine.conf << EOF
TIMEOUT=5
DEFAULT_ENTRY=0

:Arch Linux
PROTOCOL=linux
KERNEL_PATH=boot:///vmlinuz-linux
CMDLINE=root=UUID=$UUID rootflags=subvol=@ rw quiet
INITRD_PATH=boot:///initramfs-linux.img

:Arch Linux (fallback)
PROTOCOL=linux
KERNEL_PATH=boot:///vmlinuz-linux
CMDLINE=root=UUID=$UUID rootflags=subvol=@ rw
INITRD_PATH=boot:///initramfs-linux-fallback.img
EOF

# Create EFI directory
mkdir -p /boot/EFI/BOOT

# Copy EFI files
cp /usr/lib/limine/BOOTX64.EFI /boot/EFI/BOOT/
cp /usr/lib/limine/BOOTIA32.EFI /boot/EFI/BOOT/

# Generate initramfs (CRITICAL - creates the actual image files)
mkinitcpio -P

# Verify
ls -la /boot/limine.conf /boot/EFI/BOOT/
ls -la /boot/initramfs-linux.img /boot/initramfs-linux-fallback.img
