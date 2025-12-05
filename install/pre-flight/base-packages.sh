#!/bin/bash

# Enable multilib repository
arch-chroot /mnt sed -i '/\[multilib\]/,/Include/ s/^#//' /etc/pacman.conf
# Initialize pacman keyring
pacman-key --init
pacman-key --populate archlinux
pacman -Sy --noconfirm

# Install base packages
pacstrap /mnt base \
  base-devel \
  linux \
  linux-lts \
  linux-firmware \
  dhcpcd \
  sudo \
  efibootmgr \
  os-prober \
  networkmanager \
  grub \
  grub-btrfs \
  timeshift \
  gnome-keyring \
  gnome-themes-extra \
  polkit-gnome \
  xdg-desktop-portal-gtk \
  kvantum-qt5 \
  qt5-wayland \
  sddm \
  hyprland \
  hypridle \
  hyprland-guiutils \
  hyprlock \
  hyprpicker \
  hyprshot \
  hyprsunset \
  xdg-desktop-portal-hyprland \
  waybar \
  swaybg \
  swayosd \
  mako \
  power-profiles-daemon \
  satty \
  slurp \
  uwsm \
  wl-clipboard \
  wl-clip-persist \
  zram-generator \
  impala \
  wireless-regdb \
  blueberry \
  gst-plugin-pipewire \
  libpulse \
  pamixer \
  pipewire \
  pipewire-alsa \
  pipewire-jack \
  pipewire-pulse \
  playerctl \
  wiremix \
  wireplumber \
  brightnessctl \
  noto-fonts \
  noto-fonts-cjk \
  noto-fonts-emoji \
  noto-fonts-extra \
  ttf-cascadia-mono-nerd \
  ttf-iawriter-nerd \
  ttf-jetbrains-mono-nerd \
  ttf-firacode-nerd \
  woff2-font-awesome \
  mesa-utils \
  vulkan-radeon \
  firefox \
  btrfs-progs \
  zsh \
  starship \
  kitty \
  thunar \
  nautilus \
  thunderbird \
  neovim \
  obsidian \
  chezmoi \
  curl \
  wget \
  git \
  gum \
  jq \
  rsync
  # net-tools \
  # openbsd-netcat \
  # inetutils \
  # nss-mdns \
  # ufw \
  # ufw-docker \
  # whois \
  # nodejs \
  # npm \
  # jdk17-openjdk \
  # gradle \
  # go \
  # clang \
  # cmake \
  # rust \
  # docker \
  # docker-buildx \
  # docker-compose \
  # tmux \
  # github-cli \
  # lazydocker \
  # lazygit \
  # mariadb-libs \
  # mise \
  # ninja \
  # postgresql-libs \
  # tree-sitter-cli \
  # xmlstarlet \
  # vlc \
  # mpv \
  # ffmpegthumbnailer \
  # obs-studio \
  # gnome-sound-recorder \
  # discord \
  # evince \
  # imagemagick \
  # imv \
  # localsend \
  # gnome-calculator \
  # openvpn \
  # qemu-desktop \
  # libreoffice-fresh \
  # htop \
  # btop \
  # nvtop \
  # radeontop \
  # 7zip \
  # unzip \
  # fastfetch \
  # gparted \
  # asdcontrol \
  # base-devel \
  # gpu-screen-recorder \
  # fontconfig \
  # fzf \
  # gvfs-mtp \
  # gvfs-nfs \
  # gvfs-smb \
  # inxi \
  # libqalculate \
  # libyaml \
  # ripgrep \
  # zoxide \
  # bat \
  # dust \
  # expac \
  # eza \
  # fd \
  # llvm \
  # less \
  # man-db \
  # inotify-tools \
  # tldr \
  # cups \
  # cups-browsed \
  # cups-filters \
  # cups-pdf \
  # system-config-printer \

# Sync package databases
arch-chroot /mnt pacman -Sy
