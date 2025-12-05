#!/bin/bash

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh"
set -e

useradd -m -G wheel builduser
echo "builduser ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/builduser

pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm

# install all packages in ../config/packages.conf and ignore comments and empty lines
PACKAGES_FILE="$ROOT_DIR/config/packages.conf"
PACKAGES=""
while IFS= read -r line; do
    # skip empty lines and comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue
    PACKAGES+="$line "
done < "$PACKAGES_FILE"

if [ -n "$PACKAGES" ]; then
    print_info "Installing packages: $PACKAGES"
    su - builduser -c "yay -S --noconfirm --needed '$PACKAGES'"
else
    print_info "No packages to install."
fi

userdel -r builduser
rm /etc/sudoers.d/builduser
