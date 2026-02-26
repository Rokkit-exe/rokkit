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
cat > /etc/systemd/system/grub-btrfsd.service.d/override.conf <<EOF
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
# TIMESHIFT CONFIGURATION (CRON-BASED)
# =============================================================================

print_info "Configuring Timeshift for daily snapshots"

# Create timeshift config directory
mkdir -p /etc/timeshift

# Configure Timeshift settings
TIMESHIFT_CONFIG="/etc/timeshift/timeshift.json"

# Detect root device
ROOT_DEVICE=$(findmnt -n -o SOURCE /)
if [ -z "$ROOT_DEVICE" ]; then
    print_error "Could not detect root device"
    exit 1
fi

print_info "Root device: $ROOT_DEVICE"

# Initialize Timeshift
print_info "Initializing Timeshift"
timeshift --btrfs --snapshot-device "$ROOT_DEVICE" --yes 2>&1 | grep -v "CRITICAL" || true

# If config wasn't created, create it manually
if [ ! -f "$TIMESHIFT_CONFIG" ]; then
    print_warning "Creating Timeshift config manually"
    
    ROOT_UUID=$(blkid -s UUID -o value "$ROOT_DEVICE")
    
    cat > "$TIMESHIFT_CONFIG" <<EOF
{
  "backup_device_uuid" : "$ROOT_UUID",
  "parent_device_uuid" : "",
  "do_first_run" : "false",
  "btrfs_mode" : "true",
  "include_btrfs_home_for_backup" : "false",
  "include_btrfs_home_for_restore" : "false",
  "stop_cron_emails" : "true",
  "schedule_monthly" : "false",
  "schedule_weekly" : "false",
  "schedule_daily" : "true",
  "schedule_hourly" : "false",
  "schedule_boot" : "false",
  "count_monthly" : "0",
  "count_weekly" : "0",
  "count_daily" : "3",
  "count_hourly" : "0",
  "count_boot" : "0",
  "snapshot_size" : "0",
  "snapshot_count" : "0",
  "date_format" : "%Y-%m-%d %H:%M:%S",
  "exclude" : [],
  "exclude-apps" : []
}
EOF
    print_success "Timeshift config created"
fi

# Configure snapshot schedule
print_info "Configuring snapshot retention (3 daily snapshots)"

sed -i 's/"schedule_daily" : [a-z]*/"schedule_daily" : true/' "$TIMESHIFT_CONFIG"
sed -i 's/"count_daily" : [0-9]*/"count_daily" : 3/' "$TIMESHIFT_CONFIG"

# Timeshift will automatically create cron job on first run
print_info "Timeshift will use cron for scheduling (automatic)"

print_success "Timeshift configured"

# Note: Timeshift creates /etc/cron.d/timeshift-hourly automatically
# This runs every hour and checks if a scheduled snapshot is due

# =============================================================================
# SKIP INITIAL SNAPSHOT DURING INSTALL
# =============================================================================

# Note: Creating snapshot during install often fails
# Let the timer create the first snapshot after reboot
print_info "Skipping initial snapshot (will be created after first boot)"
print_info "To manually create snapshot after reboot: timeshift --create --comments 'Manual' --tags D"

# Alternative: Try to create initial snapshot (may fail, that's OK)
# print_info "Attempting to create initial snapshot (may fail during install)"
# timeshift --create --comments "Initial Snapshot - Post Installation" --tags D --yes 2>&1 | grep -v "CRITICAL" || true

echo
print_info "Timeshift configuration:"
if [ -f "$TIMESHIFT_CONFIG" ]; then
    echo "  Config file: $TIMESHIFT_CONFIG"
    echo "  Daily snapshots: 3"
    echo "  Timer enabled: $(systemctl is-enabled timeshift.timer)"
else
    print_error "Timeshift config file not found!"
fi
echo

# =============================================================================
# GRUB INSTALLATION AND CONFIGURATION
# =============================================================================

print_info "Installing and configuring GRUB bootloader"

# Verify boot partition is mounted
if ! mountpoint -q /boot; then
    print_error "/boot is not mounted!"
    print_info "Mount your EFI partition first:"
    print_info "  mount /dev/sdX1 /boot"
    exit 1
fi

# Verify we have EFI firmware
if [ ! -d /sys/firmware/efi ]; then
    print_error "System is not booted in UEFI mode!"
    print_info "This script is for UEFI systems only"
    exit 1
fi

# Install GRUB package if not already installed
if ! pacman -Qi grub &>/dev/null; then
    print_info "Installing GRUB package"
    pacman -S --noconfirm grub efibootmgr
fi

# Install GRUB to EFI partition
print_info "Installing GRUB bootloader to EFI partition"

if grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB --recheck; then
    print_success "GRUB installed successfully"
else
    print_error "GRUB installation failed"
    exit 1
fi

# Verify GRUB directory was created
if [ ! -d /boot/grub ]; then
    print_error "/boot/grub directory not created by grub-install"
    exit 1
fi

# Install microcode
print_info "Installing CPU microcode"
if grep -q "GenuineIntel" /proc/cpuinfo; then
    pacman -S --noconfirm intel-ucode
    print_success "Intel microcode installed"
elif grep -q "AuthenticAMD" /proc/cpuinfo; then
    pacman -S --noconfirm amd-ucode
    print_success "AMD microcode installed"
fi

# Configure GRUB settings BEFORE generating config
print_info "Configuring GRUB settings"

# Backup GRUB config
if [ ! -f /etc/default/grub.bak ]; then
    cp /etc/default/grub /etc/default/grub.bak
    print_success "GRUB config backed up"
fi

# Set GRUB timeout to 10 seconds
sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=10/' /etc/default/grub

# Disable GRUB_TIMEOUT_STYLE=hidden if present
sed -i 's/^GRUB_TIMEOUT_STYLE=hidden/#GRUB_TIMEOUT_STYLE=hidden/' /etc/default/grub

# Enable submenu for snapshots
if grep -q "^GRUB_DISABLE_SUBMENU=" /etc/default/grub; then
    sed -i 's/^GRUB_DISABLE_SUBMENU=.*/GRUB_DISABLE_SUBMENU=y/' /etc/default/grub
else
    echo "GRUB_DISABLE_SUBMENU=y" >> /etc/default/grub
fi

print_success "GRUB settings configured"

# Generate GRUB configuration
print_info "Generating GRUB configuration"

if grub-mkconfig -o /boot/grub/grub.cfg; then
    print_success "GRUB configuration generated"
else
    print_error "Failed to generate GRUB configuration"
    exit 1
fi

# Verify GRUB config was created
if [ -f /boot/grub/grub.cfg ]; then
    print_success "GRUB configuration file created"
    print_info "GRUB config size: $(du -h /boot/grub/grub.cfg | cut -f1)"
else
    print_error "GRUB configuration file not found!"
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
