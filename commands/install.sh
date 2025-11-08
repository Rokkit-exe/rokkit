#!/usr/bin/env bash

# Rokkit - Install Command
# Installs packages listed in packages.conf using yay

set -euo pipefail

install_packages() {
    local packages_conf="${SCRIPT_DIR}/config/packages.conf"
    
    print_info "Starting package installation..."
    
    # Check if config file exists
    if [[ ! -f "$packages_conf" ]]; then
        print_error "Configuration file not found: $packages_conf"
        exit 1
    fi
    
    # Check if yay is installed
    if ! command -v yay &> /dev/null; then
        print_error "yay is not installed. Please install yay first."
        exit 1
    fi
    
    # Collect packages to install
    local packages=()
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Remove leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue
        
        packages+=("$line")
    done < "$packages_conf"
    
    # Check if there are packages to install
    if [[ ${#packages[@]} -eq 0 ]]; then
        print_warning "No packages found in $packages_conf"
        exit 0
    fi
    
    print_info "Found ${#packages[@]} packages to install"
    echo ""
    
    # Install packages with yay
    print_info "Installing packages with yay..."
    if yay -S --needed --noconfirm "${packages[@]}"; then
        echo ""
        print_success "Package installation complete!"
    else
        echo ""
        print_error "Package installation failed"
        exit 1
    fi
}
