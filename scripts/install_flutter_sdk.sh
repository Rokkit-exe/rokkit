#!/usr/bin/env bash

set -euo pipefail

# Load common library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../lib/common.sh"

# Constants
INSTALL_DIR="/opt/flutter"
BIN_SYMLINK="/usr/local/bin/flutter"
MARK_START="# >>> FLUTTER (managed by install_flutter_sdk.sh) >>>"
MARK_END="# <<< FLUTTER (managed by install_flutter_sdk.sh) <<<"
LOCK_FILE="$HOME/.rokkit/install_flutter_sdk.lock"
REQUIRED_SPACE_MB=1500  # Flutter SDK ~800MB + extraction space

# Cleanup function
cleanup() {
    release_lock "$LOCK_FILE"
}

setup_cleanup cleanup

# ---- Check for concurrent execution ----
if ! check_lock "$LOCK_FILE"; then
    exit 1
fi

# ---- Header ----
echo ""
echo "═══════════════════════════════════════════════════"
echo "  Flutter SDK Installation"
echo "═══════════════════════════════════════════════════"
echo ""

log_message "Flutter SDK installation started"

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
            log_message "Flutter SDK installation skipped (already installed)"
            echo ""
            exit 0
        fi
        log_message "User chose to update Flutter SDK"
    fi
fi

# ---- Check disk space ----
if ! check_disk_space "/opt" "$REQUIRED_SPACE_MB"; then
    log_message "Flutter SDK installation failed: insufficient disk space"
    exit 1
fi

# ---- Fetch latest stable version ----
print_info "Fetching latest Flutter stable release information..."
log_message "Fetching Flutter release information"

# Flutter releases API endpoint
RELEASES_URL="https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json"

# Fetch and parse the latest stable version for Linux
FLUTTER_DATA=$(curl -sL "$RELEASES_URL" || true)

if [[ -z "$FLUTTER_DATA" ]]; then
    print_error "Could not fetch Flutter release information"
    print_info "Please visit: https://docs.flutter.dev/release/archive"
    log_message "Flutter SDK installation failed: could not fetch release info"
    exit 1
fi

# Extract the latest stable release info
SDK_URL=$(echo "$FLUTTER_DATA" | grep -oP '"archive":\s*"\K[^"]+' | grep "stable/linux" | head -n1 || true)

if [[ -z "$SDK_URL" ]]; then
    print_error "Could not parse latest stable release URL"
    log_message "Flutter SDK installation failed: could not parse URL"
    exit 1
fi

# Prepend base URL if needed
if [[ "$SDK_URL" != http* ]]; then
    SDK_URL="https://storage.googleapis.com/flutter_infra_release/releases/$SDK_URL"
fi

# Extract version and checksum
VERSION=$(echo "$SDK_URL" | grep -oP 'flutter_linux_\K[^.]+\.[^.]+\.[^-]+(?=-stable)' || echo "latest")

# Try to get checksum from release data (Flutter doesn't always provide it in the JSON)
SDK_CHECKSUM=$(echo "$FLUTTER_DATA" | grep -B5 "$SDK_URL" | grep -oP '"sha256":\s*"\K[^"]+' | head -n1 || echo "")

print_success "Found latest stable version: $VERSION"
print_info "Download URL: $SDK_URL"
if [[ -n "$SDK_CHECKSUM" ]]; then
    print_info "SHA256: $SDK_CHECKSUM"
fi
echo ""

log_message "Flutter SDK version: $VERSION"

# ---- Install prerequisites ----
print_info "Checking prerequisites..."

MISSING_DEPS=()
require_command "wget" || MISSING_DEPS+=("wget")
require_command "tar" || MISSING_DEPS+=("tar")
require_command "cmake" || MISSING_DEPS+=("cmake")
require_command "ninja" || MISSING_DEPS+=("ninja")
require_command "pkg-config" "pkgconf" || MISSING_DEPS+=("pkgconf")

if [[ ${#MISSING_DEPS[@]} -gt 0 ]]; then
    print_info "Installing missing dependencies: ${MISSING_DEPS[*]}"
    log_message "Installing dependencies: ${MISSING_DEPS[*]}"
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

log_message "Downloading Flutter SDK from: $SDK_URL"

if ! download_with_retry "$SDK_URL" "$TAR_PATH" 3 60; then
    log_message "Flutter SDK installation failed: download error"
    exit 1
fi

# ---- Verify checksum if available ----
if [[ -n "$SDK_CHECKSUM" ]]; then
    if ! verify_checksum "$TAR_PATH" "$SDK_CHECKSUM"; then
        log_message "Flutter SDK installation failed: checksum verification failed"
        exit 1
    fi
else
    print_warning "Checksum not available, skipping verification"
    log_message "Warning: Checksum verification skipped (not available)"
fi

# ---- Extract Flutter SDK ----
print_info "Extracting Flutter SDK..."
log_message "Extracting Flutter SDK"

# Try .xz first, then .gz
if tar -xJf "$TAR_PATH" -C "$TMPDIR" 2>/dev/null; then
    print_success "Extraction complete"
elif tar -xzf "$TAR_PATH" -C "$TMPDIR" 2>/dev/null; then
    print_success "Extraction complete"
else
    print_error "Failed to extract archive (unknown format)"
    log_message "Flutter SDK installation failed: extraction error"
    exit 1
fi

if [[ ! -d "$TMPDIR/flutter" ]]; then
    print_error "Expected 'flutter' directory not found in archive"
    log_message "Flutter SDK installation failed: invalid archive structure"
    exit 1
fi

STAGE_DIR="$TMPDIR/flutter"

# ---- Install Flutter SDK ----
print_info "Installing Flutter to $INSTALL_DIR..."
log_message "Installing Flutter to $INSTALL_DIR"

# Backup existing installation if present
BACKUP_PATH=""
if [[ -d "$INSTALL_DIR" ]]; then
    BACKUP_PATH=$(create_backup "$INSTALL_DIR")
    if [[ -z "$BACKUP_PATH" ]]; then
        print_error "Failed to backup existing installation"
        log_message "Flutter SDK installation failed: backup error"
        exit 1
    fi
fi

# Install new version
sudo mkdir -p "$(dirname "$INSTALL_DIR")"
if ! sudo mv "$STAGE_DIR" "$INSTALL_DIR"; then
    print_error "Failed to install Flutter"
    
    # Restore backup if installation failed
    if [[ -n "$BACKUP_PATH" ]] && [[ -d "$BACKUP_PATH" ]]; then
        restore_backup "$BACKUP_PATH" "$INSTALL_DIR"
    fi
    
    log_message "Flutter SDK installation failed: install error"
    exit 1
fi

print_success "Flutter installed to: $INSTALL_DIR"
log_message "Flutter SDK installed successfully"

# Clean up backup if new installation succeeded
if [[ -n "$BACKUP_PATH" ]] && [[ -d "$BACKUP_PATH" ]]; then
    sudo rm -rf "$BACKUP_PATH"
fi

# ---- Create symlink ----
print_info "Creating symlink: $BIN_SYMLINK"
sudo mkdir -p "$(dirname "$BIN_SYMLINK")"
sudo ln -sf "$INSTALL_DIR/bin/flutter" "$BIN_SYMLINK"
print_success "Symlink created"

# ---- Setup environment variables ----
print_info "Configuring environment variables..."

RCFILE=$(get_shell_rc)
RC_CONTENT='# Flutter SDK PATH configuration
if ! command -v flutter >/dev/null 2>&1; then
  export PATH="/usr/local/bin:$PATH"
fi
if [[ -d "/opt/flutter/bin" ]] && [[ ":$PATH:" != *":/opt/flutter/bin:"* ]]; then
  export PATH="/opt/flutter/bin:$PATH"
fi'

update_rc_block "$RCFILE" "$MARK_START" "$MARK_END" "$RC_CONTENT"
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
    log_message "Flutter SDK installation failed: verification error"
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

log_message "Flutter SDK installation completed successfully"
