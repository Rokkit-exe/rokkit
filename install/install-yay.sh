#!/bin/bash


# install yay from chroot
#
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
    echo "Yay installation failed."
    exit 1
fi
echo "Yay installed successfully."
