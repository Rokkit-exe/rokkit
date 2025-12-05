#!/bin/bash


PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh"
set -e

# install yay from chroot
pacman -S base-devel git --noconfirm --needed

useradd -m -s /bin/bash builduser

echo "builduser ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

sudo -u builduser bash << EOF
cd /home/builduser
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF

# cleanup
userdel -r builduser 2>/dev/null || true 
sed -i '/builduser ALL=(ALL) NOPASSWD: ALL/d' /etc/sudoers

# verify installation
if ! command -v yay &> /dev/null; then
    print_error "Yay installation failed."
    exit 1
fi
print_success "Yay installed successfully."
