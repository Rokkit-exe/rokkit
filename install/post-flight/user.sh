#!/bin/bash
# User Profile Creation Script for Arch Linux
# Creates user account, sets passwords, and configures sudo access

PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/../../" && pwd)"
source "${ROOT_DIR}/lib/print.sh"

set -e

# Load configuration
if [ ! -f "$ROOT_DIR/config/settings.conf" ]; then
    print_error "$ROOT_DIR/config/settings.conf not found."
    exit 1
fi

source "$ROOT_DIR/config/settings.conf"

# Validate required settings
if [ -z "$HOST_NAME" ] || [ -z "$ROOT_PASS" ] || [ -z "$USER_NAME" ] || [ -z "$PASSWORD" ]; then
    print_error "Missing required settings in settings.conf"
    print_info "Required: HOST_NAME, ROOT_PASS, USER_NAME, PASSWORD"
    exit 1
fi

# Check root privileges
if [ "$EUID" -ne 0 ]; then 
    print_error "Please run as root"
    exit 1
fi

print_info "Configuring system hostname and user accounts"

# =============================================================================
# HOSTNAME CONFIGURATION
# =============================================================================

print_info "Setting hostname: $HOST_NAME"

# Set hostname
echo "$HOST_NAME" > /etc/hostname

# Configure /etc/hosts
cat > /etc/hosts <<EOF
127.0.0.1    localhost
::1          localhost
127.0.1.1    ${HOST_NAME}.localdomain ${HOST_NAME}
EOF

print_success "Hostname configured"

# =============================================================================
# ROOT PASSWORD
# =============================================================================

print_info "Setting root password"

# Set root password securely (chpasswd expects plaintext by default)
if echo "root:${ROOT_PASS}" | chpasswd; then
    print_success "Root password set"
else
    print_error "Failed to set root password"
    exit 1
fi

# =============================================================================
# USER CREATION
# =============================================================================

# Determine user shell
USER_SHELL="${USER_SHELL:-/bin/zsh}"

# Check if shell exists, fallback to bash
if [ ! -f "$USER_SHELL" ]; then
    print_warning "Shell $USER_SHELL not found, using /bin/bash"
    USER_SHELL="/bin/bash"
fi

# Check if user already exists
if id "$USER_NAME" &>/dev/null; then
    print_warning "User $USER_NAME already exists"
    
    confirm=$(choose "Delete and recreate user?" "yes" "no")
    if [ "$confirm" = "yes" ]; then
        print_info "Removing existing user"
        userdel -r "$USER_NAME" 2>/dev/null || true
    else
        print_info "Skipping user creation"
        USER_EXISTS=true
    fi
fi

if [ "$USER_EXISTS" != "true" ]; then
    print_info "Creating user: $USER_NAME"
    
    # Determine additional groups based on system type
    EXTRA_GROUPS="wheel"
    
    # Add groups for desktop environment
    if [ "$INSTALL_TYPE" = "desktop" ] || [ "$INSTALL_HYPRLAND" = "true" ]; then
        EXTRA_GROUPS="${EXTRA_GROUPS},audio,video,input,storage,optical,lp,scanner"
    fi
    
    # Add libvirt group if virtualization is enabled
    if [ "$ENABLE_VIRTUALIZATION" = "true" ]; then
        EXTRA_GROUPS="${EXTRA_GROUPS},libvirt,kvm"
    fi
    
    # Add docker group if enabled
    if [ "$INSTALL_DOCKER" = "true" ]; then
        EXTRA_GROUPS="${EXTRA_GROUPS},docker"
    fi
    
    # Create user with appropriate groups
    if useradd -m -G "$EXTRA_GROUPS" -s "$USER_SHELL" "$USER_NAME"; then
        print_success "User $USER_NAME created"
        print_info "Groups: $EXTRA_GROUPS"
        print_info "Shell: $USER_SHELL"
    else
        print_error "Failed to create user $USER_NAME"
        exit 1
    fi
    
    # Set user password
    print_info "Setting password for $USER_NAME"
    if echo "${USER_NAME}:${PASSWORD}" | chpasswd; then
        print_success "User password set"
    else
        print_error "Failed to set user password"
        exit 1
    fi
    
    # Verify home directory was created
    if [ ! -d "/home/$USER_NAME" ]; then
        print_error "Home directory not created for $USER_NAME"
        exit 1
    fi
    
    # Set proper home directory permissions
    chown -R "${USER_NAME}:${USER_NAME}" "/home/$USER_NAME"
    chmod 700 "/home/$USER_NAME"
    print_success "Home directory configured"
fi

# =============================================================================
# SUDO CONFIGURATION
# =============================================================================

print_info "Configuring sudo access"

# Backup sudoers file
if [ ! -f /etc/sudoers.bak ]; then
    cp /etc/sudoers /etc/sudoers.bak
    print_info "Sudoers backup created"
fi

# Create sudoers drop-in file (safer than editing /etc/sudoers directly)
SUDOERS_FILE="/etc/sudoers.d/99-wheel"

# Determine if NOPASSWD should be used
if [ "$SUDO_NOPASSWD" = "true" ]; then
    print_warning "Configuring passwordless sudo (NOPASSWD)"
    SUDO_LINE="%wheel ALL=(ALL:ALL) NOPASSWD: ALL"
else
    print_info "Configuring sudo with password requirement"
    SUDO_LINE="%wheel ALL=(ALL:ALL) ALL"
fi

# Create sudoers drop-in file
cat > "$SUDOERS_FILE" <<EOF
# Created by installation script
# Allow members of group wheel to execute any command
$SUDO_LINE

# Allow wheel group to use specific commands without password
%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/systemctl poweroff
%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/systemctl reboot
%wheel ALL=(ALL:ALL) NOPASSWD: /usr/bin/systemctl suspend
EOF

# Set proper permissions (CRITICAL for sudoers files)
chmod 440 "$SUDOERS_FILE"

# Validate sudoers configuration
if visudo -c -f "$SUDOERS_FILE" &>/dev/null; then
    print_success "Sudo configuration valid"
else
    print_error "Invalid sudoers configuration!"
    rm -f "$SUDOERS_FILE"
    exit 1
fi

# =============================================================================
# USER ENVIRONMENT SETUP
# =============================================================================

print_info "Setting up user environment"

# Create common directories
USER_HOME="/home/$USER_NAME"
mkdir -p "$USER_HOME"/{Documents,Downloads,Pictures,Videos,Music,Projects,.config,.local/share}

# Set ownership
chown -R "${USER_NAME}:${USER_NAME}" "$USER_HOME"

# Copy skeleton files if they don't exist
if [ -d /etc/skel ]; then
    su - "$USER_NAME" -c "cp -rn /etc/skel/. ~/" 2>/dev/null || true
fi

print_success "User environment configured"

# =============================================================================
# SUMMARY
# =============================================================================

echo
print_success "User profile creation complete!"
echo
print_info "Summary:"
echo "  Hostname:       $HOST_NAME"
echo "  Root password:  [SET]"
echo "  Username:       $USER_NAME"
echo "  User password:  [SET]"
echo "  User shell:     $USER_SHELL"
echo "  User groups:    $(id -nG "$USER_NAME" | tr ' ' ',')"
echo "  Home directory: $USER_HOME"
echo "  Sudo access:    $([ "$SUDO_NOPASSWD" = "true" ] && echo "NOPASSWD" || echo "PASSWORD REQUIRED")"
echo
print_warning "Security reminder:"
echo "  - Change passwords after first boot"
echo "  - Remove plaintext passwords from settings.conf"
echo "  - Review sudo configuration in /etc/sudoers.d/"
