#!/usr/bin/env bash

# Rokkit - Uninstall Command
# Uninstalls packages listed in uninstall-packages.conf using yay

set -euo pipefail

uninstall_packages() {
    local packages_conf="${SCRIPT_DIR}/config/uninstall-packages.conf"
    
    print_info "Starting package uninstallation..."
    
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
    
    # Collect packages to uninstall
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
    
    # Check if there are packages to uninstall
    if [[ ${#packages[@]} -eq 0 ]]; then
        print_warning "No packages found in $packages_conf"
        exit 0
    fi
    
    # Filter packages - separate installed from not installed
    # Performance optimization: Get all installed packages once
    local installed_packages=()
    local not_installed_packages=()
    local all_installed
    
    print_info "Checking package status..."
    all_installed=$(yay -Qq 2>/dev/null || echo "")
    
    for pkg in "${packages[@]}"; do
        if echo "$all_installed" | grep -qx "$pkg"; then
            installed_packages+=("$pkg")
        else
            not_installed_packages+=("$pkg")
        fi
    done
    
    # Show not installed packages
    if [[ ${#not_installed_packages[@]} -gt 0 ]]; then
        echo ""
        print_info "Skipping ${#not_installed_packages[@]} package(s) not installed:"
        for pkg in "${not_installed_packages[@]}"; do
            echo "  - $pkg"
        done
    fi
    
    # Check if there are installed packages to remove
    if [[ ${#installed_packages[@]} -eq 0 ]]; then
        echo ""
        print_warning "No packages to uninstall (all packages are already not installed)"
        exit 0
    fi
    
    # Show confirmation prompt for installed packages
    echo ""
    print_warning "This will remove the following ${#installed_packages[@]} package(s):"
    for pkg in "${installed_packages[@]}"; do
        echo "  - $pkg"
    done
    echo ""
    read -p "Are you sure you want to continue? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Uninstall cancelled"
        exit 0
    fi
    
    # Uninstall packages with yay
    echo ""
    print_info "Uninstalling packages with yay..."
    
    local uninstalled=0
    local failed=0
    
    for pkg in "${installed_packages[@]}"; do
        # Capture stderr for error reporting while suppressing stdout
        local error_output
        if error_output=$(yay -R --noconfirm "$pkg" 2>&1 >/dev/null); then
            print_success "Uninstalled: $pkg"
            uninstalled=$((uninstalled + 1))
        else
            print_error "Failed to uninstall: $pkg"
            # Show error details if available
            if [[ -n "$error_output" ]]; then
                echo "  Error: ${error_output}" | head -n 1
            fi
            failed=$((failed + 1))
        fi
    done
    
    # Summary
    echo ""
    print_info "Uninstall complete!"
    echo "  Uninstalled: $uninstalled"
    [[ ${#not_installed_packages[@]} -gt 0 ]] && echo "  Skipped (not installed): ${#not_installed_packages[@]}"
    [[ $failed -gt 0 ]] && echo "  Failed: $failed"
}
