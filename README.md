# Rokkit

A comprehensive bash CLI tool for backing up and managing your dotfiles, system packages, and Arch Linux environment setup.

## Features

### Core Dotfiles Management
- Backup dotfiles and directories to a centralized location
- Restore dotfiles from backup to your system
- Install packages from a package list using yay
- Uninstall unwanted packages from a package list using yay
- Simple configuration via `dotfiles.conf`, `packages.conf`, and `uninstall-packages.conf`
- Color-coded output with success/warning/error messages
- Automatic directory structure preservation
- Safety confirmation before restore and uninstall operations

### Additional Utilities
- **ZSH Setup**: Automated ZSH installation with Oh-My-ZSH, Powerlevel10k theme, and essential plugins
- **Nerd Fonts**: Automated installation of popular Nerd Fonts (FiraCode, JetBrainsMono, Meslo, etc.)
- **Development Tools**: Flutter SDK, Android SDK Manager, and Android tools installation scripts
- **System Configuration**: USB device management and systemd service files
- **Cider Installation**: Quick installation script for Cider music player

### Included Resources
- **Wallpapers**: Curated collection of aesthetic backgrounds for your desktop
- **Hyprland Shaders**: 80+ screen shaders for Hyprland (cyberpunk, retro, accessibility, color filters, and more)

## Installation

```bash
# Clone or download the repository
cd rokkit

# Make the script executable
chmod +x rokkit
```

## Usage

### Backup Your Dotfiles

```bash
./rokkit backup
```

This command will:
- Read all dotfile paths from `config/dotfiles.conf`
- Copy each file/directory from your HOME to `dotfiles/`
- Preserve directory structure
- Show a summary of backed up, skipped, and failed items

### Restore Your Dotfiles

```bash
./rokkit restore
```

This command will:
- Read all dotfile paths from `config/dotfiles.conf`
- Copy each file/directory from `dotfiles/` back to your HOME
- Replace existing files/directories with backed up versions
- Ask for confirmation before proceeding
- Show a summary of restored, skipped, and failed items

**Warning:** This will overwrite your current dotfiles! Make sure you have a recent backup.

### Install Packages

```bash
./rokkit install
```

This command will:
- Read all package names from `config/packages.conf`
- Install all packages using `yay -S --needed --noconfirm`
- Skip packages that are already installed (thanks to `--needed` flag)
- Show installation progress and summary

**Note:** Requires `yay` to be installed on your system.

### Uninstall Packages

```bash
./rokkit uninstall
```

This command will:
- Read all package names from `config/uninstall-packages.conf`
- Display the list of packages to be removed
- Ask for confirmation before proceeding
- Uninstall all packages using `yay -R --noconfirm`
- Show uninstallation progress and summary

**Note:** Use this to remove unwanted packages from your system. Requires `yay` to be installed.

### Show Help

```bash
./rokkit help
```

## Configuration

### Dotfiles Configuration

Edit `config/dotfiles.conf` to specify which dotfiles to track. Add one path per line, relative to your HOME directory.

Example:
```
# Shell Configuration
.zshrc
.bashrc

# Terminal Config
.config/kitty

# Editor
.config/nvim

# Git
.gitconfig
```

### Package Configuration

Edit `config/packages.conf` to specify which packages to install. Add one package name per line.

Example:
```
# Browsers
firefox
brave-bin

# Development Tools
git
docker
neovim

# Utilities
htop
fastfetch
```

### Uninstall Package Configuration

Edit `config/uninstall-packages.conf` to specify which packages to uninstall. Add one package name per line.

Example:
```
# Unwanted packages
1password-cli
spotify
zoom
```

### Drive Mount Configuration

Edit `config/drive.conf` to configure automatic drive mounting (used by `scripts/mount_drive.sh`).

Example:
```
UUID=1aa44f69-7eed-4464-9b6f-8a847f9b8366
MOUNT_POINT=/mnt/storage
FILESYSTEM=ext4
MOUNT_OPTIONS=defaults,nofail
DEVICE_LABEL=Storage Drive
```

**Note:** Find your drive's UUID with: `lsblk -f` or `blkid`

Lines starting with `#` are comments and will be ignored in all configuration files.

## Utility Scripts

Rokkit includes several idempotent utility scripts in the `scripts/` directory. All scripts feature:
- Clean, color-coded console output with clear status messages
- Safe to run multiple times (idempotent)
- Automatic checks to skip already-completed steps
- Proper error handling and validation

### Setup & Installation Scripts

#### setup_zsh.sh
Automated ZSH setup with modern shell environment:
- Installs ZSH (supports Arch Linux, Ubuntu, Debian)
- Sets ZSH as default shell
- Installs Oh-My-ZSH framework
- Installs essential plugins (syntax highlighting, autosuggestions, completions)
- Installs Powerlevel10k theme
- Provides next-steps guidance for configuration

```bash
./scripts/setup_zsh.sh
```

#### install_cider.sh
Install Cider music player from local package:
- Checks if Cider is already installed
- Verifies package file exists at `/mnt/storage/cider/`
- Installs using pacman
- Displays installed version

```bash
./scripts/install_cider.sh
```

#### install_nerd_fonts.sh
Download and install popular Nerd Fonts (FiraCode, JetBrainsMono, Meslo, Noto, AdwaitaMono)

```bash
./scripts/install_nerd_fonts.sh
```

### System Management Scripts

#### mount_drive.sh
Mount a drive and add it to /etc/fstab for automatic boot mounting:
- Reads configuration from `config/drive.conf`
- Verifies drive exists before mounting
- Creates mount point if needed
- Checks if already mounted (prevents conflicts)
- Backs up /etc/fstab before modifications
- Validates fstab configuration
- Shows drive status with df

**Configuration**: Edit `config/drive.conf` with your drive details:
```
UUID=your-drive-uuid-here
MOUNT_POINT=/mnt/storage
FILESYSTEM=ext4
MOUNT_OPTIONS=defaults,nofail
DEVICE_LABEL=Storage Drive
```

**Usage**:
```bash
# Find your drive UUID first
lsblk -f

# Edit config/drive.conf with your UUID
nano config/drive.conf

# Run the script (idempotent - safe to run multiple times)
./scripts/mount_drive.sh
```

#### disable_usb.sh
Setup systemd service to prevent USB devices (keyboard) from waking system after suspend:
- Installs wake disable script to `/usr/local/bin/`
- Installs and enables systemd service
- Disables wake for USB devices: XHC0, XHC1, XHC2
- Shows before/after wake status
- Runs automatically on boot

```bash
./scripts/disable_usb.sh
```

### Development Tools Scripts

- **install_flutter_sdk.sh**: Install Flutter SDK for mobile development
- **install_sdk_manager.sh**: Install Android SDK Manager
- **install-android-tools.sh**: Install Android development tools

### Making Scripts Executable

```bash
# Make all scripts executable
chmod +x scripts/*.sh

# Or make individual scripts executable
chmod +x scripts/setup_zsh.sh
```

## Additional Resources

### Wallpapers
The `backgrounds/` directory contains curated wallpapers:
- Cyberpunk city sunset
- Low-poly street scene
- Night city views
- Aesthetic desk setups

### Hyprland Shaders
Over 80 screen shaders for Hyprland window manager in `dotfiles/.config/hypr/shaders/`:

**Categories:**
- **Accessibility**: Color-blind filters (deuteranopia, protanopia, tritanopia)
- **Cyberpunk/Retro**: Cyberpunk, vaporwave, CRT effects, VHS, neon
- **Color Themes**: Monochrome variations, duotone, tritone
- **Vintage**: Film grain, sepia, vintage, noir, technicolor
- **Filters**: Blue light reduction, night vision, thermal, infrared
- **Effects**: Glitch, scanlines, depth of field, oil paint, cel shade
- **Era Vibes**: 40s-00s decade-specific color grading
- **Utility**: Brightness boost, contrast adjustment, color correction

## Project Structure

```
rokkit/
├── rokkit                          # Main CLI executable
├── commands/                       # Command implementations
│   ├── backup.sh                   # Backup command
│   ├── restore.sh                  # Restore command
│   ├── install.sh                  # Install command
│   └── uninstall.sh                # Uninstall command
├── config/
│   ├── dotfiles.conf               # Dotfiles configuration
│   ├── packages.conf               # Packages to install
│   ├── uninstall-packages.conf     # Packages to uninstall
│   └── drive.conf                  # Drive mount configuration
├── dotfiles/                       # Backup destination (created automatically)
│   └── .config/                    # Configuration files backup
│       ├── hypr/                   # Hyprland configuration
│       │   ├── shaders/            # 80+ screen shaders
│       │   ├── hyprland.conf       # Main config
│       │   ├── hyprlock.conf       # Lock screen config
│       │   └── ...                 # Additional Hyprland configs
│       ├── kitty/                  # Kitty terminal config
│       ├── nvim/                   # Neovim configuration
│       └── waybar/                 # Waybar config with custom scripts
├── backgrounds/                    # Wallpaper collection
├── scripts/                        # Utility installation scripts
│   ├── setup_zsh.sh               # ZSH setup with Oh-My-ZSH (idempotent)
│   ├── install_nerd_fonts.sh      # Nerd Fonts installer
│   ├── install_cider.sh           # Cider music player (idempotent)
│   ├── install_flutter_sdk.sh     # Flutter SDK
│   ├── install_sdk_manager.sh     # Android SDK Manager
│   ├── install-android-tools.sh   # Android tools
│   ├── disable_usb_wake.sh        # USB wake disable helper script
│   ├── disable_usb.sh             # USB wake setup (idempotent)
│   └── mount_drive.sh             # Drive mounting with config (idempotent)
└── services/                       # Systemd service files
    └── disable-usb-wakeup.service # USB wake disable service
```

## Requirements

### Core Requirements
- Bash 4.0+
- Standard Unix utilities (cp, mkdir, dirname)
- Git (for cloning repositories and plugins)

### Optional Requirements
- **yay** - AUR helper (required for install/uninstall package commands)
- **curl** - For downloading fonts and installation scripts
- **unzip** - For extracting font archives
- **Hyprland** - To use the included shaders
- **systemd** - For service file management

## License

MIT
