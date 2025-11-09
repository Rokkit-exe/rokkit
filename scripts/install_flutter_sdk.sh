#!/usr/bin/env bash

set -euo pipefail

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

# Constants
INSTALL_DIR="/opt/flutter"
BIN_SYMLINK="/usr/local/bin/flutter"
MARK_START="# >>> FLUTTER (managed by install_flutter_sdk.sh) >>>"
MARK_END="# <<< FLUTTER (managed by install_flutter_sdk.sh) <<<"

# Determine shell RC file
SHELL_NAME="$(basename "${SHELL:-bash}")"
if [[ "$SHELL_NAME" == "zsh" ]]; then
    RCFILE="$HOME/.zshrc"
else
    RCFILE="$HOME/.bashrc"
fi

# ---- Header ----
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Flutter SDK Installation"
echo "═══════════════════════════════════════════════════"
echo ""

# ---- Check if already installed ----
if [[ -d "$INSTALL_DIR" ]] && [[ -f "$INSTALL_DIR/bin/flutter" ]]; then
    print_success "Flutter SDK is already installed"
    
    # Export PATH for current session to check version
    export PATH="/usr/local/bin:$INSTALL_DIR/bin:$PATH"
    
    if command -v flutter &>/dev/null; then
        CURRENT_VERSION=$(flutter --version 2>&1 | grep "Flutter" | head -n1 || echo "unknown")
        print_info "$CURRENT_VERSION"
        print_info "Location: $INSTALL_DIR"
        echo ""
        
        read -p "Do you want to update to the latest stable version? (y/N): " -n 1 -r
        echo ""
        
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Installation skipped"
            echo ""
            exit 0
        fi
    fi
fi

# ---- Fetch latest stable version ----
print_info "Fetching latest Flutter stable release information..."

# Flutter releases API endpoint
RELEASES_URL="https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"

# Fetch and parse the latest stable version for Linux
FLUTTER_DATA=$(curl -sL "$RELEASES_URL" || true)

if [[ -z "$FLUTTER_DATA" ]]; then
    print_error "Could not fetch Flutter release information"
    print_info "Please visit: https://docs.flutter.dev/release/archive"
    print_info "And run this script with the tarball URL as an argument:"
    print_info "  $0 <flutter-tarball-url>"
    echo ""
    exit 1
fi

# Extract the latest stable release info
SDK_URL=$(echo "$FLUTTER_DATA" | grep -oP '"archive":\s*"\K[^"]+' | grep "stable/linux" | head -n1 || true)

if [[ -z "$SDK_URL" ]]; then
    print_error "Could not parse latest stable release URL"
    exit 1
fi

# Prepend base URL if needed
if [[ "$SDK_URL" != http* ]]; then
    SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/$SDK_URL"
fi

# Extract version from URL
VERSION=$(echo "$SDK_URL" | grep -oP 'flutter_linux_\K[^.]+\.[^.]+\.[^-]+(?=-stable)' || echo "latest")
print_success "Found latest stable version: $VERSION"
print_info "Download URL: $SDK_URL"
echo ""

# ---- Install prerequisites ----
print_info "Checking prerequisites..."

MISSING_DEPS=()
command -v wget &>/dev/null || MISSING_DEPS+=("wget")
command -v tar &>/dev/null || MISSING_DEPS+=("tar")
command -v cmake &>/dev/null || MISSING_DEPS+=("cmake")
command -v ninja &>/dev/null || MISSING_DEPS+=("ninja")
command -v pkg-config &>/dev/null || MISSING_DEPS+=("pkgconf")

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    print_info "Installing missing dependencies: ${MISSING_DEPS[*]}"
    sudo pacman -S --needed --noconfirm "${MISSING_DEPS[@]}"
    print_success "Dependencies installed"
else
    print_success "All prerequisites satisfied"
fi

# ---- Download Flutter SDK ----
TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

TAR_NAME="flutter_linux_${VERSION}-stable.tar.xz"
TAR_PATH="$TMPDIR/$TAR_NAME"

print_info "Downloading Flutter SDK..."
if wget -q --show-progress -O "$TAR_PATH" "$SDK_URL"; then
    print_success "Download complete"
else
    print_error "Failed to download Flutter SDK"
    exit 1
fi

# ---- Extract Flutter SDK ----
print_info "Extracting Flutter SDK..."

# Try .xz first, then .gz
if tar -xJf "$TAR_PATH" -C "$TMPDIR" 2>/dev/null; then
    print_success "Extraction complete"
elif tar -xzf "$TAR_PATH" -C "$TMPDIR" 2>/dev/null; then
    print_success "Extraction complete"
else
    print_error "Failed to extract archive (unknown format)"
    exit 1
fi

if [[ ! -d "$TMPDIR/flutter" ]]; then
    print_error "Expected 'flutter' directory not found in archive"
    exit 1
fi

STAGE_DIR="$TMPDIR/flutter"

# ---- Install Flutter SDK ----
print_info "Installing Flutter to $INSTALL_DIR..."

# Backup existing installation if present
if [[ -d "$INSTALL_DIR" ]]; then
    BACKUP_DIR="${INSTALL_DIR}.backup.$(date +%s)"
    print_info "Backing up existing installation to: $BACKUP_DIR"
    sudo mv "$INSTALL_DIR" "$BACKUP_DIR" || {
        print_error "Failed to backup existing installation"
        exit 1
    }
fi

# Install new version
sudo mkdir -p "$(dirname "$INSTALL_DIR")"
sudo mv "$STAGE_DIR" "$INSTALL_DIR" || {
    print_error "Failed to install Flutter"
    # Restore backup if installation failed
    if [[ -d "$BACKUP_DIR" ]]; then
        sudo mv "$BACKUP_DIR" "$INSTALL_DIR"
        print_info "Restored previous installation"
    fi
    exit 1
}

print_success "Flutter installed to: $INSTALL_DIR"

# Clean up old backup if new installation succeeded
if [[ -d "$BACKUP_DIR" ]]; then
    sudo rm -rf "$BACKUP_DIR"
fi

# ---- Create symlink ----
print_info "Creating symlink: $BIN_SYMLINK"
sudo mkdir -p "$(dirname "$BIN_SYMLINK")"
sudo ln -sf "$INSTALL_DIR/bin/flutter" "$BIN_SYMLINK"
print_success "Symlink created"

# ---- Setup environment variables ----
print_info "Configuring environment variables..."

# Update RC file
if [[ -f "$RCFILE" ]]; then
    # Remove old managed block if exists
    if grep -qF "$MARK_START" "$RCFILE" 2>/dev/null; then
        print_info "Removing old environment configuration from $RCFILE"
        awk -v s="$MARK_START" -v e="$MARK_END" '
            $0==s {skip=1}
            !skip {print}
            $0==e {skip=0; next}
        ' "$RCFILE" > "$RCFILE.tmp" && mv "$RCFILE.tmp" "$RCFILE"
    fi
fi

# Add new configuration
cat >> "$RCFILE" <<EOF

$MARK_START
# Flutter SDK PATH configuration
if ! command -v flutter >/dev/null 2>&1; then
  export PATH="/usr/local/bin:\$PATH"
fi
if [[ -d "/opt/flutter/bin" ]] && [[ ":\$PATH:" != *":/opt/flutter/bin:"* ]]; then
  export PATH="/opt/flutter/bin:\$PATH"
fi
$MARK_END
EOF

print_success "Environment configured in $RCFILE"

# Export for current session
export PATH="/usr/local/bin:$INSTALL_DIR/bin:$PATH"

# ---- Verify installation ----
print_info "Verifying Flutter installation..."

if command -v flutter &>/dev/null; then
    FLUTTER_PATH=$(which flutter)
    print_success "Flutter found at: $FLUTTER_PATH"
    
    print_info "Flutter version:"
    flutter --version
    echo ""
else
    print_error "Flutter not found in PATH"
    exit 1
fi

# ---- Run Flutter doctor ----
print_info "Running Flutter doctor to check setup..."
echo ""
flutter doctor -v || print_warning "Flutter doctor reported some issues (this is normal for initial setup)"

# ---- Summary ----
echo ""
echo "═══════════════════════════════════════════════════"
print_success "Flutter SDK installation complete!"
echo "═══════════════════════════════════════════════════"
echo ""
print_info "Installation location: $INSTALL_DIR"
print_info "Symlink created: $BIN_SYMLINK"
print_info "Environment configured in: $RCFILE"
echo ""
print_info "Next steps:"
echo "  1. Open a new terminal or run: source $RCFILE"
echo "  2. Verify Flutter: flutter --version"
echo "  3. Check setup: flutter doctor"
echo "  4. Accept Android licenses (if Android SDK installed):"
echo "     flutter doctor --android-licenses"
echo "  5. Create your first app: flutter create my_app"
echo ""
