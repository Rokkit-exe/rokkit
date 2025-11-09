#!/usr/bin/env bash

# Rokkit - Init Command
# Complete system initialization: uninstalls unwanted packages, installs packages,
# restores dotfiles, and runs utility setup scripts

set -euo pipefail


init_system() {
    print_title "Rokkit System Initialization"
    print_info "This will perform a complete system setup:"
    echo "  1. Uninstall unwanted packages"
    echo "  2. Install required packages"
    echo "  3. Restore dotfiles"
    echo "  4. Mount storage drive"
    echo "  5. Disable USB wake"
    echo "  6. Setup ZSH environment"
    echo "  7. Install Android SDK Manager"
    echo "  8. Install Flutter SDK"
    echo "  9. Install Cider music player"
    echo ""
    
    # Confirmation prompt
    read -p "Do you want to proceed? (y/N): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_warning "Initialization cancelled"
        exit 0
    fi
    
    print_title "Starting System Initialization"
    
    local start_time=$(date +%s)
    local step=1
    local total_steps=9
    
    # ---- Step 1: Uninstall unwanted packages ----
    sleep 2
    print_title "Step $step/$total_steps: Uninstalling Unwanted Packages"
    
    # Run in subshell to prevent exit from stopping init
    (uninstall_packages) || true
    print_success "Step $step/$total_steps complete: Unwanted packages processed"
    step=$((step + 1))
    
    # ---- Step 2: Install packages ----
    sleep 2
    print_title "Step $step/$total_steps: Installing Packages"
    
    # Run in subshell to allow script to continue if package list is empty
    (install_packages) || print_warning "Package installation had issues (continuing anyway)"
    print_success "Step $step/$total_steps complete: Packages processed"
    step=$((step + 1))
    
    # ---- Step 3: Restore dotfiles ----
    sleep 2
    print_title "Step $step/$total_steps: Restoring Dotfiles"
    
    # Run in subshell to allow script to continue if user cancels
    (restore_dotfiles) || print_warning "Dotfiles restore skipped or had issues (continuing anyway)"
    print_success "Step $step/$total_steps complete: Dotfiles processed"
    step=$((step + 1))
    
    # ---- Step 4: Mount storage drive ----
    sleep 2
    print_title "Step $step/$total_steps: Mounting Storage Drive"
    
    # Run in subshell to allow script to continue if it exits
    ("${SCRIPT_DIR}/scripts/mount_drive.sh") || print_warning "Drive mount had issues (continuing anyway)"
    print_success "Step $step/$total_steps complete: Storage drive processed"
    step=$((step + 1))
    
    # ---- Step 5: Disable USB wake ----
    sleep 2
    print_title "Step $step/$total_steps: Disabling USB Wake"
    
    # Run in subshell to allow script to continue if it exits
    ("${SCRIPT_DIR}/scripts/disable_usb.sh") || print_warning "USB wake setup had issues (continuing anyway)"
    print_success "Step $step/$total_steps complete: USB wake processed"
    step=$((step + 1))
    
    # ---- Step 6: Setup ZSH ----
    sleep 2
    print_title "Step $step/$total_steps: Setting up ZSH Environment"
    
    # Run in subshell to allow script to continue if it exits
    ("${SCRIPT_DIR}/scripts/setup_zsh.sh") || print_warning "ZSH setup had issues (continuing anyway)"
    print_success "Step $step/$total_steps complete: ZSH environment processed"
    step=$((step + 1))
    
    # ---- Step 7: Install Android SDK Manager ----
    sleep 2
    print_title "Step $step/$total_steps: Installing Android SDK Manager"
    
    # Run in subshell to allow script to continue if it exits
    ("${SCRIPT_DIR}/scripts/install_sdk_manager.sh") || print_warning "Android SDK Manager installation had issues (continuing anyway)"
    print_success "Step $step/$total_steps complete: Android SDK Manager processed"
    step=$((step + 1))
    
    # ---- Step 8: Install Flutter SDK ----
    sleep 2
    print_title "Step $step/$total_steps: Installing Flutter SDK"
    
    # Run in subshell to allow script to continue if it exits
    ("${SCRIPT_DIR}/scripts/install_flutter_sdk.sh") || print_warning "Flutter SDK installation had issues (continuing anyway)"
    print_success "Step $step/$total_steps complete: Flutter SDK processed"
    step=$((step + 1))
    
    # ---- Step 9: Install Cider ----
    sleep 2
    print_title "Step $step/$total_steps: Installing Cider Music Player"
    
    # Run in subshell to allow script to continue if it exits
    ("${SCRIPT_DIR}/scripts/install_cider.sh") || print_warning "Cider installation had issues (continuing anyway)"
    print_success "Step $step/$total_steps complete: Cider processed"
    
    # ---- Calculate total time ----
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local minutes=$((duration / 60))
    local seconds=$((duration % 60))
    
    # ---- Final summary ----
    print_title "System Initialization Complete"
    print_info "Time taken: ${minutes}m ${seconds}s"
    echo ""
    print_info "Next steps:"
    echo "  1. Log out and back in for ZSH to take effect"
    echo "  2. Run: source ~/.zshrc"
    echo "  3. Configure Powerlevel10k: p10k configure"
    echo "  4. Verify all services: systemctl status disable-usb-wakeup.service"
    echo "  5. Check mounted drives: df -h"
    echo "  6. Check Flutter setup: flutter doctor -v"
    echo "  7. Accept Android licenses: flutter doctor --android-licenses"
    echo ""
}
