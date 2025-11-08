#!/usr/bin/env bash

# Rokkit - Restore Command
# Restores dotfiles from backup to your system

set -euo pipefail

restore_dotfiles() {
    print_info "Starting dotfiles restore..."
    
    # Check if config file exists
    if [[ ! -f "$CONFIG_FILE" ]]; then
        print_error "Configuration file not found: $CONFIG_FILE"
        exit 1
    fi
    
    # Check if dotfiles directory exists
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        print_error "Dotfiles directory not found: $DOTFILES_DIR"
        print_error "Run 'rokkit backup' first to create a backup"
        exit 1
    fi
    
    # Warning prompt
    echo ""
    print_warning "This will replace your existing dotfiles with the backed up versions!"
    echo -n "Are you sure you want to continue? (yes/no): "
    read -r confirmation
    
    if [[ "$confirmation" != "yes" ]]; then
        print_info "Restore cancelled"
        exit 0
    fi
    
    local restored=0
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
        local source_path="$DOTFILES_DIR/$line"
        local dest_path="$HOME/$line"
        local dest_dir=$(dirname "$dest_path")
        
        # Check if backup exists
        if [[ ! -e "$source_path" ]]; then
            print_warning "Skipping $line (not found in backup)"
            skipped=$((skipped + 1))
            continue
        fi
        
        # Create destination directory if needed
        mkdir -p "$dest_dir"
        
        # Remove existing file/directory if it exists
        if [[ -e "$dest_path" ]]; then
            # Safety check: refuse to remove critical directories
            if [[ "$dest_path" == "$HOME" ]] || [[ "$dest_path" == "/" ]] || [[ "$dest_path" == "/home" ]]; then
                print_error "Refusing to remove critical directory: $dest_path"
                failed=$((failed + 1))
                continue
            fi
            rm -rf "$dest_path"
        fi
        
        # Copy the file or directory from backup
        if cp -r "$source_path" "$dest_path"; then
            print_success "Restored: $line"
            restored=$((restored + 1))
        else
            print_error "Failed to restore: $line"
            failed=$((failed + 1))
        fi
        
    done < "$CONFIG_FILE"
    
    # Summary
    echo ""
    print_info "Restore complete!"
    echo "  Restored: $restored"
    [[ $skipped -gt 0 ]] && echo "  Skipped: $skipped"
    [[ $failed -gt 0 ]] && echo "  Failed: $failed"
}
