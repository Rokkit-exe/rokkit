#!/bin/bash
# This script installs Cider on a Linux system.
if pacman -Q cider &>/dev/null; then
  echo "Cider is already installed"
else
  if [[ -f "/mnt/storage/cider/cider-v2.0.3-linux-x64.pkg.tar.zst" ]]; then
    sudo pacman -U --noconfirm --needed /mnt/storage/cider/cider-v2.0.3-linux-x64.pkg.tar.zst
  else
    echo "Unable to find Cider v2 package in storage drive"
  fi
fi
