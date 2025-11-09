#!/usr/bin/env bash

set -euo pipefail

# Configuration
PACKAGE_PATH="/mnt/storage/cider/cider-v2.0.3-linux-x64.pkg.tar.zst"
PACKAGE_NAME="cider"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Output functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}➜${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# ---- Header ----

echo ""
echo "═══════════════════════════════════════════════════"
echo "  Cider Music Player Installation"
echo "═══════════════════════════════════════════════════"
echo ""

# ---- Check if Already Installed ----

print_info "Checking if Cider is already installed..."

if pacman -Q "$PACKAGE_NAME" &>/dev/null; then
    INSTALLED_VERSION=$(pacman -Q "$PACKAGE_NAME" | awk '{print $2}')
    print_success "Cider is already installed (version: $INSTALLED_VERSION)"
    echo ""
    print_info "To reinstall, first remove it with: sudo pacman -R $PACKAGE_NAME"
    echo ""
    exit 0
fi

print_info "Cider is not installed"

# ---- Verify Package File Exists ----

print_info "Looking for package at: $PACKAGE_PATH"

if [[ ! -f "$PACKAGE_PATH" ]]; then
    print_error "Package file not found: $PACKAGE_PATH"
    echo ""
    print_info "Please ensure:"
    echo "  1. The storage drive is mounted at /mnt/storage"
    echo "  2. The Cider package exists at the specified path"
    echo "  3. The file name matches: $(basename "$PACKAGE_PATH")"
    echo ""
    exit 1
fi

print_success "Package file found"

# ---- Install Package ----

print_info "Installing Cider from local package..."

if sudo pacman -U --noconfirm --needed "$PACKAGE_PATH"; then
    echo ""
    echo "═══════════════════════════════════════════════════"
    print_success "Cider installed successfully!"
    echo "═══════════════════════════════════════════════════"
    echo ""
    
    # Display installed version
    INSTALLED_VERSION=$(pacman -Q "$PACKAGE_NAME" | awk '{print $2}')
    print_info "Installed version: $INSTALLED_VERSION"
    print_info "Launch Cider with: cider"
    echo ""
else
    echo ""
    print_error "Failed to install Cider"
    echo ""
    exit 1
fi
