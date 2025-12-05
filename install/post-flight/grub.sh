#!/bin/bash

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh"
set -e

# replace the ExecStart line to use timeshift
sudo sed -i 's|^ExecStart=.*|ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto|' /usr/lib/systemd/system/timeshift-restore.service

# Enable and start the grub-btrfsd service
sudo systemctl enable grub-btrfsd
sudo systemctl start grub-btrfsd

# create initial snapshot
sudo timeshift --create --comments "Initial Snapshot" --tags D

# make timeshift create snapshots daily with a maximum of 3 snapshots
sudo timeshift --schedule --daily 1 --weekly 0 --monthly 0 --boot 0 --count 3

# Update GRUB configuration to include Btrfs snapshots
sudo /etc/grub.d/41_snapshots-btrfs
sudo grub-mkconfig -o /boot/grub/grub.cfg
