# Rokkit

A simple bash CLI tool for backing up and managing your dotfiles and system packages.

## Features

- Backup dotfiles and directories to a centralized location
- Restore dotfiles from backup to your system
- Install packages from a package list using yay
- Simple configuration via `dotfiles.conf` and `packages.conf`
- Color-coded output with success/warning/error messages
- Automatic directory structure preservation
- Safety confirmation before restore operations

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

### Show Help

```bash
./rokkit help
```

## Configuration

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

Lines starting with `#` are comments and will be ignored.

## Project Structure

```
rokkit/
├── rokkit              # Main CLI executable
├── commands/           # Command implementations
│   ├── backup.sh       # Backup command
│   └── restore.sh      # Restore command
├── config/
│   └── dotfiles.conf   # Dotfiles configuration
├── dotfiles/           # Backup destination (created automatically)
└── scripts/            # Utility scripts
```

## Requirements

- Bash 4.0+
- Standard Unix utilities (cp, mkdir, dirname)
- yay (AUR helper) - required for the install command

## License

MIT
