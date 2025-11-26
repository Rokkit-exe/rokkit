#!/bin/bash


# check internet connectivity
./connection.sh

# Check for required commands and environment
./requirements.sh

# Ask for user input (hostname, username, password, keyboard layout, locale, git config)
./settings.sh

# Set up disk partitions and filesystems
./partition.sh

# pacstrap (base system) ✓
./base-packages.sh
./install-yay.sh
./aur-packages.sh

# Generate fstab ✓
genfstab -U /mnt >> /mnt/etc/fstab

# arch-chroot into new system
arch-chroot /mnt

# Configure system (timezone, locale, hostname)
# keyboard layout
loadkeys "$KEYBOARD_LAYOUT"
# set timezone
./timezone.sh
# set locale
echo "$LOCALE.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=$LOCALE.UTF-8" > /etc/locale.conf
# Configure mkinitcpio for Limine and Snapper
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modules btrfs keyboard keymap block filesystems fsck)/' /etc/mkinitcpio.conf


# Install bootloader (Limine)
./limine.sh

# set hosname/user/root password
./user.sh

# Set git config
git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"

# Enable dhcpcd service
systemctl enable dhcpcd

# Enable snapper timeline and cleanup timers
systemctl enable snapper-timeline.timer
systemctl enable snapper-cleanup.timer


# Install additional packages and configure system
# read lines from packages.txt and install them
xargs -a ../config/packages.txt pacman -S --noconfirm --needed

# clone rokkit repository
git clone https://github.com/Rokkit-exe/rokkit.git /home/"$USER_NAME"/.local/share/rokkit
chown -R "$USER_NAME":"$USER_NAME" /home/"$USER_NAME"/.local/share/rokkit
# Install Hyprland and dependencies ← do it here
systemctl enable sddm
echo 
# Create user account
# Configure dotfiles (your rokkit system)
#

logout
umount -R /mnt
limine bios-install /dev/"$DISK"
echo "Installation complete! You can now reboot into your new system."
gum confirm "Installation complete! You can now reboot into your new system. Reboot now?" && reboot
