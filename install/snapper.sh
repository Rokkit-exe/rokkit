#!/bin/bash
# Configure Snapper for automatic daily snapshots (max 3)
# This script sets up timeline snapshots with proper cleanup

set -e

source ../lib/print.sh

print_info "Configuring Snapper for automatic daily snapshots..."

# Check if snapper is installed
if ! command -v snapper &> /dev/null; then
    print_info "Installing snapper..."
    pacman -S --needed --noconfirm snapper
fi

systemctl enable --now snapperd.service

# Check if root config exists
if [ ! -f "/etc/snapper/configs/root" ]; then
    print_info "Creating Snapper root configuration..."
    snapper -c root create-config /
    
    # Remove the .snapshots subvolume if it was created (for existing layouts)
    if [ -d "/.snapshots" ]; then
        umount /.snapshots 2>/dev/null || true
        btrfs subvolume delete /.snapshots 2>/dev/null || true
        mkdir -p /.snapshots
    fi
else
    print_info "Snapper root config already exists"
fi

# Backup original config
if [ -f "/etc/snapper/configs/root" ]; then
    cp /etc/snapper/configs/root /etc/snapper/configs/root.backup
    print_info "Backed up original config to /etc/snapper/configs/root.backup"
fi

# Configure snapper for daily snapshots with max 3
print_info "Updating Snapper configuration..."

# Update the config file
cat > /etc/snapper/configs/root << 'EOF'
# subvolume to snapshot
SUBVOLUME="/"

# filesystem type
FSTYPE="btrfs"

# btrfs qgroup for space aware cleanup algorithms
QGROUP=""

# fraction or absolute size of the filesystems space the snapshots may use
SPACE_LIMIT="0.5"

# fraction or absolute size of the filesystems space that should be free
FREE_LIMIT="0.2"

# users and groups allowed to work with config
ALLOW_USERS=""
ALLOW_GROUPS=""

# sync users and groups from ALLOW_USERS and ALLOW_GROUPS to .snapshots
# directory
SYNC_ACL="no"

# start comparing pre- and post-snapshot in background after creating
# post-snapshot
BACKGROUND_COMPARISON="yes"

# run daily number cleanup
NUMBER_CLEANUP="yes"

# limit for number cleanup
NUMBER_MIN_AGE="1800"
NUMBER_LIMIT="3"
NUMBER_LIMIT_IMPORTANT="3"

# create hourly snapshots
TIMELINE_CREATE="yes"

# cleanup hourly snapshots after some time
TIMELINE_CLEANUP="yes"

# limits for timeline cleanup
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="0"
TIMELINE_LIMIT_DAILY="3"
TIMELINE_LIMIT_WEEKLY="0"
TIMELINE_LIMIT_MONTHLY="0"
TIMELINE_LIMIT_YEARLY="0"

# cleanup empty pre-post-pairs
EMPTY_PRE_POST_CLEANUP="yes"

# limits for empty pre-post-pair cleanup
EMPTY_PRE_POST_MIN_AGE="1800"
EOF

print_info "Snapper configuration updated"

# Enable and start snapper timeline service
print_info "Enabling Snapper timeline service..."
systemctl enable --now snapper-timeline.timer
systemctl enable --now snapper-cleanup.timer

# Show status
echo ""
print_info "Service status:"
systemctl status snapper-timeline.timer --no-pager || true
echo ""
systemctl status snapper-cleanup.timer --no-pager || true

echo ""
print_info "=========================================="
print_info "Snapper automatic snapshots configured!"
print_info "=========================================="
print_info "Configuration:"
print_info "  - Daily snapshots: Enabled"
print_info "  - Max daily snapshots: 3"
print_info "  - Hourly/Weekly/Monthly: Disabled"
print_info "  - Timeline: Enabled"
print_info "  - Cleanup: Enabled"
echo ""
print_info "Timers:"
print_info "  - snapper-timeline.timer: Creates snapshots"
print_info "  - snapper-cleanup.timer: Removes old snapshots"
echo ""
print_info "Useful commands:"
print_info "  snapper list                    - List all snapshots"
print_info "  snapper create -d 'Description' - Create manual snapshot"
print_info "  snapper delete <number>         - Delete snapshot"
print_info "  snapper status <num1>..<num2>   - Compare snapshots"
print_info "  snapper diff <num1>..<num2>     - Show file differences"
echo ""
print_info "Configuration file: /etc/snapper/configs/root"
echo ""
print_warn "First automatic snapshot will be created within 24 hours"
print_info "Or create one manually: snapper -c root create --description 'Initial snapshot'"
