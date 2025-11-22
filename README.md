# Rokkit

A comprehensive system configuration tool for Arch Linux with Hyprland.
Rokkit provides an all-in-one solution for managing packages, and maintaining system utilities through simple bash scripts.

## Features

- **Package Management**: Install/uninstall packages using yay package manager
- **System Initialization**: Complete system setup with a single command
- **Hyprland Utilities**: Collection of helper scripts for Hyprland window manager
- **Theme Management**: Consistent theming across applications

## Project Structure

```
rokkit/
├── bin/                    # System utility scripts
├── config/                 # Configuration files
│   ├── dotfiles.conf       # Dotfiles to track (paths relative to $HOME)
│   ├── packages.conf       # Packages to install
│   ├── uninstall-packages.conf  # Packages to remove from omarchy
│   └── drive.conf          # Drive mount configuration
├── default/                # Default configuration templates
├── lib/                    # Shared bash libraries
│   ├── common.sh           # Common utility functions
│   └── print.sh            # Formatted output functions (uses gum)
├── themes/                 # Theme files for various applications
└── services/               # Systemd service files
```

## Core Component of the OS

- **Hyprland**: Dynamic tiling window manager
- **Waybar**: Highly customizable status bar for Wayland
- **Yay**: AUR helper for package management
- **Kitty**: Fast, feature-rich terminal emulator
- **Neovim**: Extensible text editor
- **Nautilus**: File manager for GNOME
- **Mako**: Notification daemon for Wayland
- **Grim & Slurp**: Screenshot tools for Wayland
- **Walker**: Menu application for Wayland
- **Elephant**: App launcher for Wayland
- **Wiremix**: Audio mixer for PipeWire
- **Impala**: Wireless network manager for Wayland
- **Blueberry**: Bluetooth manager for Wayland
- **ZSH**: Powerful shell with extensive plugin support
- **btrfs**: Advanced filesystem with snapshot capabilities
- **Firefox**: Popular web browser

## License

MIT
