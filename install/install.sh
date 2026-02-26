#!/bin/bash

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/.." && pwd)"
echo "ROOT_DIR is $ROOT_DIR"
source "${ROOT_DIR}/lib/print.sh"
set -e

cd iso
./all.sh

if [ ! -f "$ROOT_DIR/config/settings.conf" ]; then
    print_error "$ROOT_DIR/config/settings.conf not found."
    exit 1
fi
source "$ROOT_DIR/config/settings.conf"

if [ -z "$HOST_NAME" ] || [ -z "$ROOT_PASS" ] || [ -z "$USER_NAME" ] || [ -z "$PASSWORD" ] || [ -z "$LOCALE" ] || [ -z "$KEYBOARD_LAYOUT" ] || [ -z "$GIT_NAME" ] || [ -z "$GIT_EMAIL" ] || [ -z "$DISK" ]; then
    print_error "One or more required settings are missing in ./config/settings.conf."
    exit 1
fi

# copy rokkit to the new system
print_title "Copying Rokkit to the New System"
ROOT_DIR_TARGET="/mnt/work"
mkdir -p "$ROOT_DIR_TARGET"
cp -r "/usr/local/share/rokkit" "$ROOT_DIR_TARGET"

print_title "Chrooting into the New System to Continue Setup"
arch-chroot /mnt bash -c "
  cd /work/rokkit/install/chroot
  ./all.sh
"

umount -R /mnt
echo "Installation complete! You can now reboot into your new system."
gum confirm "Installation complete! You can now reboot into your new system. Reboot now?" && reboot
