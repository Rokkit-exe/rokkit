#!/usr/bin/env bash

# Rokkit - Backup Command
# Backs up dotfiles listed in dotfiles.conf

set -euo pipefail

backup_dotfiles() {
    print_info "Starting dotfiles backup..."
    
    # Check if config file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    # Create dotfiles directory if it doesn't exist
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        print_info "Creating dotfiles directory: $DOTFILES_DIR"
        mkdir -p "$DOTFILES_DIR"
    fi
    
    local backed_up=0
    local skipped=0
    local failed=0
    
    # Read config file and process each dotfile
    while IFS= read -r line || [[ -n "$line" ]]; do
        # Skip empty lines and comments
        [[ -z "$line" ]] && continue
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        
        # Remove leading/trailing whitespace
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "$line" ]] && continue
        
        # Construct full path
        local source_path="$HOME/$line"
        local dest_path="$DOTFILES_DIR/$line"
        local dest_dir=$(dirname "$dest_path")
        
        # Check if source exists
        if [[ ! -e "$source_path" ]]; then
            print_warning "Skipping $line (not found)"
            skipped=$((skipped + 1))
            continue
        fi
        
        # Create destination directory if needed
        mkdir -p "$dest_dir"
        
        # Copy the file or directory
        if cp -r "$source_path" "$dest_path"; then
            print_success "Backed up: $line"
            backed_up=$((backed_up + 1))
        else
            print_error "Failed to backup: $line"
            failed=$((failed + 1))
        fi
        
    done < "$CONFIG_FILE"
    
    # Summary
    echo ""
    print_info "Backup complete!"
    echo "  Backed up: $backed_up"
    [[ $skipped -gt 0 ]] && echo "  Skipped: $skipped"
    [[ $failed -gt 0 ]] && echo "  Failed: $failed"
}
