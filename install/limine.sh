#!/bin/bash


# Create Limine config
UUID=$(lsblk "$DISK" -no UUID | head -n 1)
echo "Using UUID: $UUID"

MACHINE_ID=$(cat /etc/machine-id)
echo "Machine ID: $MACHINE_ID"

get_snapshots() {
  SNAPSHOTS_FILE="snapshots.json"  # Adjust path as needed
  NUM_SNAPSHOTS=2

  jq -r ".snapshotEntries | sort_by(.snapperID.snapshotID) | reverse | .[0:$NUM_SNAPSHOTS][] | 
    .snapperID as \$id |
    .kernelEntries[0] as \$kernel |
    \":Snapshot \(\$id.timestamp) (\(\$id.properties.description))\" +
    \"\nPROTOCOL=efi_chainload\" +
    \"\nIMAGE_PATH=boot():\(\$kernel.imageDetails[0].snapshotFilePathLine)\" +
    \"\nKERNEL_CMDLINE=\(\$kernel.cmdlineDetails[0].snapshotCmdline)\" +
    \"\n\"" \
    "/boot/c31ff373c87d4f91bce0a187dc36728d/limine_history/$SNAPSHOTS_FILE"
}

cat > /boot/limine.conf << EOF
timeout=10
default_entry=0
interface_branding: Rokkit Bootloader
interface_branding_color: 2

# Terminal colors (Tokyo Night palette)
term_palette: 15161e;f7768e;9ece6a;e0af68;7aa2f7;bb9af7;7dcfff;a9b1d6
term_foreground: c0caf5

/+Rokkit
comment: "Rokkit Bootloader Entry"
comment: "Machine ID: $MACHINE_ID"

//Linux
protocol: linux
path: boot():/vmlinuz-linux
cmdline: root=UUID=$UUID rootflags=subvol=@ rw rootfstype=btrfs
module_path: boot():/initramfs-linux.img

//Linux
protocol: linux
path: boot():/vmlinuz-linux-lts
cmdline: root=UUID=$UUID rootflags=subvol=@ rw rootfstype=btrfs
module_path: boot():/initramfs-linux-lts.img

/Memtest86+
    protocol: efi
    path: boot():/memtest86+/memtest.efi

EOF

get_snapshots >> /boot/limine.conf

# Create EFI directory
mkdir -p /boot/EFI/arch-limine

# Copy EFI files
cp /usr/share/limine/BOOTX64.EFI /boot/EFI/arch-limine/
cp /usr/share/limine/BOOTIA32.EFI /boot/EFI/arch-limine/

# pacman hook
cat > /etc/pacman.d/hooks/99-limine.hook << EOF
[Trigger]
Operation = Install
Operation = Upgrade
Type = Package
Target = limine              

[Action]
Description = Deploying Limine after upgrade...
When = PostTransaction
Exec = /bin/sh -c "/usr/bin/cp /usr/share/limine/BOOTIA32.EFI /boot/EFI/arch-limine/ && /usr/bin/cp /usr/share/limine/BOOTX64.EFI /boot/EFI/arch-limine/"
EOF

cat > /etc/pacman.d/hooks/90-mkinitcpio-install.hook << EOF
[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Operation = Remove
Target = usr/lib/initcpio/*
Target = usr/lib/firmware/*
Target = usr/lib/modules/*/extramodules/
Target = usr/src/*/dkms.conf

[Trigger]
Type = Path
Operation = Install
Operation = Upgrade
Target = usr/lib/modules/*/pkgbase

[Trigger]
Type = Package
Operation = Install
Operation = Upgrade
Target = mkinitcpio
Target = mkinitcpio-git

[Action]
Description = Updating linux initcpios...
When = PostTransaction
Exec = /usr/share/libalpm/scripts/limine-mkinitcpio-install
NeedsTargets
EOF

efibootmgr \
      --create \
      --disk "$DISK" \
      --part Y \
      --label "Arch Linux Limine Boot Loader" \
      --loader '\EFI\arch-limine\BOOTX64.EFI' \
      --unicode

# Generate initramfs (CRITICAL - creates the actual image files)
mkinitcpio -P

# Verify
ls -la /boot/limine.conf /boot/EFI/BOOT/
ls -la /boot/initramfs-linux.img /boot/initramfs-linux-fallback.img



# bios install
mkdir -p /boot/limine
cp /usr/share/limine/limine-bios.sys /boot/limine/
limine bios-install "$DISK"




#!/bin/bash
# Generate limine.conf snapshot entries from snapshots.json


