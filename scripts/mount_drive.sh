#!/bin/bash
echo "Mounting storage drive at boot..."
sudo mkdir -p /mnt/storage
if grep -Fxq "UUID=1aa44f69-7eed-4464-9b6f-8a847f9b8366 /mnt/storage   ext4    defaults,nofail  0   2" /etc/fstab; then
  echo "Storage drive already mounted"
else
  echo "# /dev/sda" | sudo tee -a /etc/fstab >/dev/null
  echo "UUID=1aa44f69-7eed-4464-9b6f-8a847f9b8366 /mnt/storage   ext4    defaults,nofail  0   2" | sudo tee -a /etc/fstab >/dev/null
  sudo mount -a
  sudo systemctl daemon-reload
fi
