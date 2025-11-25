#!/bin/bash

pacstrap /mnt base \
  base-devel \
  linux \
  linux-firmware \
  btrfs-progs \
  dhcpcd \
  vim \
  git \
  limine \
  limine-mkinitcpio-hook \
  limine-snapper-sync \
  snapper

