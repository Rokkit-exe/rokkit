#!/bin/bash

systemctl enable NetworkManager.service
systemctl enable systemd-timesyncd.service
systemctl enable sddm.service
systemctl enable bluetooth.service
#systemctl enable cups.service
#systemctl enable sshd.service
#systemctl enable ufw.service
#systemctl enable libvirtd.service
#systemctl enable virtlogd.service
#systemctl enable docker.service
systemctl enable grub-btrfsd.service
systemctl enable fstrim.timer

