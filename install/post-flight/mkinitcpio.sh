#!/bin/bash

# Configure mkinitcpio for grub with btrfs support
sed -i 's/^HOOKS=.*/HOOKS=(base udev autodetect modconf keyboard fsck btrfs filesystems)/' /etc/mkinitcpio.conf
mkinitcpio -P
