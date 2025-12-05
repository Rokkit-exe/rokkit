#!/bin/bash
# GRUB-Btrfs + Timeshift Configuration Script
# - Sets GRUB timeout to 10 seconds
# - Displays 3 most recent snapshots in GRUB menu
# - Configures daily automatic snapshots using systemd timers

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh"

set -e

# Check root privileges
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
    exit 1
fi

print_info "Configuring GRUB-Btrfs and Timeshift"

# =============================================================================
# PACKAGE INSTALLATION
# =============================================================================

print_info "Checking required packages..."

REQUIRED_PACKAGES=("grub" "grub-btrfs" "timeshift" "inotify-tools")

for pkg in "${REQUIRED_PACKAGES[@]}"; do
    if ! pacman -Qi "$pkg" &> /dev/null; then
        print_error "Package '$pkg' is not installed"
        exit 1
    fi
done

# =============================================================================
# GRUB CONFIGURATION
# =============================================================================

print_info "Configuring GRUB timeout and settings"

# Set GRUB timeout to 10 seconds
if grep -q "^GRUB_TIMEOUT=" /etc/default/grub; then
    sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub
else
    echo "GRUB_TIMEOUT=10" >> /etc/default/grub
fi

# Enable submenu for snapshots (recommended)
sed -i 's/^GRUB_DISABLE_SUBMENU=.*/GRUB_DISABLE_SUBMENU=y/' /etc/default/grub

print_success "GRUB configuration updated"

# =============================================================================
# GRUB-BTRFS CONFIGURATION
# =============================================================================

print_info "Configuring grub-btrfs to show 3 snapshots"

# Configure grub-btrfs
GRUB_BTRFS_CONFIG="/etc/default/grub-btrfs/config"

# Set number of snapshots to display
if grep -q "^GRUB_BTRFS_LIMIT=" "$GRUB_BTRFS_CONFIG"; then
    sed -i 's/^GRUB_BTRFS_LIMIT=.*/GRUB_BTRFS_LIMIT="3"/' "$GRUB_BTRFS_CONFIG"
else
    sed -i '/^#GRUB_BTRFS_LIMIT=/a GRUB_BTRFS_LIMIT="3"' "$GRUB_BTRFS_CONFIG"
fi

# Show full snapshot path for clarity
sed -i 's/^GRUB_BTRFS_SHOW_PATH=.*/GRUB_BTRFS_SHOW_PATH="true"/' "$GRUB_BTRFS_CONFIG"

# Show total number of snapshots found
sed -i 's/^GRUB_BTRFS_SHOW_TOTAL_SNAPSHOTS_FOUND=.*/GRUB_BTRFS_SHOW_TOTAL_SNAPSHOTS_FOUND="true"/' "$GRUB_BTRFS_CONFIG"

# Use timeshift snapshots
sed -i 's/^GRUB_BTRFS_TIMESHIFT_SNAPSHOT_KERNEL=.*/GRUB_BTRFS_TIMESHIFT_SNAPSHOT_KERNEL="true"/' "$GRUB_BTRFS_CONFIG"

print_success "grub-btrfs configured for 3 snapshots"

# =============================================================================
# GRUB-BTRFSD SERVICE CONFIGURATION
# =============================================================================

print_info "Configuring grub-btrfsd service"

# Check if systemd service exists
if [ ! -f /usr/lib/systemd/system/grub-btrfsd.service ]; then
    print_error "grub-btrfsd.service not found"
    print_info "Ensure grub-btrfs package is installed correctly"
    exit 1
fi

# Create systemd override directory
mkdir -p /etc/systemd/system/grub-btrfsd.service.d

# Create override configuration for timeshift integration
cat > /etc/systemd/system/grub-btrfsd.service.d/override.conf < EOF
[Service]
ExecStart=
ExecStart=/usr/bin/grub-btrfsd --syslog --timeshift-auto
EOF

print_success "grub-btrfsd service configured for timeshift"

# Reload systemd daemon
systemctl daemon-reload

# Enable and start grub-btrfsd
print_info "Enabling grub-btrfsd service"
systemctl enable grub-btrfsd.service

if systemctl is-active --quiet grub-btrfsd.service; then
    print_info "Restarting grub-btrfsd service"
    systemctl restart grub-btrfsd.service
else
    print_info "Starting grub-btrfsd service"
    systemctl start grub-btrfsd.service
fi

# Verify service is running
if systemctl is-active --quiet grub-btrfsd.service; then
    print_success "grub-btrfsd service is running"
else
    print_error "grub-btrfsd service failed to start"
    systemctl status grub-btrfsd.service --no-pager
    exit 1
fi

# =============================================================================
# TIMESHIFT CONFIGURATION WITH SYSTEMD TIMER
# =============================================================================

print_info "Configuring Timeshift for daily snapshots"

# Create timeshift config directory
mkdir -p /etc/timeshift

# Configure Timeshift settings
TIMESHIFT_CONFIG="/etc/timeshift/timeshift.json"

# Check if root btrfs subvolume @ exists
if ! btrfs subvolume list / | grep -q "@$"; then
    print_warning "Root subvolume '@' not found"
    print_info "Timeshift works best with @ subvolume layout"
fi

# Initialize Timeshift if not already done
if [ ! -f "$TIMESHIFT_CONFIG" ]; then
    print_info "Initializing Timeshift"
    timeshift --btrfs --yes
fi

# Configure snapshot schedule
print_info "Setting up daily snapshot schedule (max 3 snapshots)"

# Detect root device
ROOT_DEVICE=$(findmnt -n -o SOURCE /)
if [ -z "$ROOT_DEVICE" ]; then
    print_error "Could not detect root device"
    exit 1
fi

print_info "Root device: $ROOT_DEVICE"

# Update schedule settings
timeshift --btrfs --snapshot-device "$ROOT_DEVICE" --yes \
    --schedule-daily 1 \
    --schedule-weekly 0 \
    --schedule-monthly 0 \
    --schedule-boot 0 \
    --schedule-hourly 0

# Ensure config file exists after initialization
if [ ! -f "$TIMESHIFT_CONFIG" ]; then
    print_error "Timeshift configuration file not created"
    exit 1
fi

# Set retention count using sed
sed -i 's/"count_boot" : [0-9]*/"count_boot" : 0/' "$TIMESHIFT_CONFIG"
sed -i 's/"count_hourly" : [0-9]*/"count_hourly" : 0/' "$TIMESHIFT_CONFIG"
sed -i 's/"count_daily" : [0-9]*/"count_daily" : 3/' "$TIMESHIFT_CONFIG"
sed -i 's/"count_weekly" : [0-9]*/"count_weekly" : 0/' "$TIMESHIFT_CONFIG"
sed -i 's/"count_monthly" : [0-9]*/"count_monthly" : 0/' "$TIMESHIFT_CONFIG"

print_success "Timeshift schedule configured"

# Enable and start Timeshift systemd timer
print_info "Enabling Timeshift systemd timer for automatic snapshots"

systemctl enable timeshift.timer
systemctl start timeshift.timer

# Verify timer is active
if systemctl is-active --quiet timeshift.timer; then
    print_success "Timeshift timer is active"
    echo
    # Show next scheduled run
    print_info "Next scheduled snapshot:"
    systemctl list-timers timeshift.timer --no-pager | head -n 3
    echo
else
    print_error "Timeshift timer failed to start"
    systemctl status timeshift.timer --no-pager
    exit 1
fi

# =============================================================================
# CREATE INITIAL SNAPSHOT
# =============================================================================

print_info "Creating initial snapshot"

if timeshift --create --comments "Initial Snapshot - Post Installation" --tags D --yes; then
    print_success "Initial snapshot created"
else
    print_warning "Failed to create initial snapshot (may already exist)"
fi

echo
print_info "Current snapshots:"
timeshift --list
echo

# =============================================================================
# UPDATE GRUB CONFIGURATION
# =============================================================================

print_info "Generating GRUB configuration with btrfs snapshots"

# Make sure 41_snapshots-btrfs script is executable
if [ -f /etc/grub.d/41_snapshots-btrfs ]; then
    chmod +x /etc/grub.d/41_snapshots-btrfs
else
    print_warning "/etc/grub.d/41_snapshots-btrfs not found"
    print_info "This is normal if no snapshots exist yet"
fi

# Regenerate GRUB config
if grub-mkconfig -o /boot/grub/grub.cfg; then
    print_success "GRUB configuration updated"
else
    print_error "Failed to update GRUB configuration"
    exit 1
fi

# =============================================================================
# VERIFICATION
# =============================================================================

print_info "Verifying configuration"

# Check if snapshots appear in GRUB config
if grep -q "Arch Linux snapshots" /boot/grub/grub.cfg; then
    print_success "Snapshots found in GRUB configuration"
elif grep -q "snapshots-btrfs" /boot/grub/grub.cfg; then
    print_success "Snapshot menu entry found in GRUB configuration"
else
    print_warning "No snapshots found in GRUB configuration yet"
    print_info "Snapshots will appear in GRUB menu after they are created"
fi

# =============================================================================
# SUMMARY
# =============================================================================

echo
print_success "GRUB-Btrfs and Timeshift configuration complete!"
echo
print_info "Configuration Summary:"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  GRUB timeout:           10 seconds"
echo "  Snapshots in GRUB:      3 most recent"
echo "  Snapshot schedule:      Daily (managed by systemd timer)"
echo "  Snapshot retention:     3 snapshots"
echo "  grub-btrfsd service:    $(systemctl is-active grub-btrfsd.service)"
echo "  Timeshift timer:        $(systemctl is-active timeshift.timer)"
echo "  ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo
print_success "All done! Reboot to see changes in GRUB menu."
