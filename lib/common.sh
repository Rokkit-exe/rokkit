#!/usr/bin/env bash

# Rokkit Common Library
# Shared functions for all Rokkit scripts

# ---- Validation Functions ----

# Check if a command exists
require_command() {
    local cmd="$1"
    local package="${2:-$cmd}"
    
    if ! command -v "$cmd" &>/dev/null; then
        print_error "Required command '$cmd' not found"
        print_info "Install it with: sudo pacman -S $package"
        return 1
    fi
    return 0
}

# ---- Network Functions ----

# Download file with retry logic and progress
download_with_retry() {
    local url="$1"
    local output="$2"
    local max_attempts="${3:-3}"
    local timeout="${4:-30}"
    
    for attempt in $(seq 1 "$max_attempts"); do
        print_info "Downloading (attempt $attempt/$max_attempts)..."
        
        if timeout "$timeout" wget -q --show-progress --https-only -O "$output" "$url" 2>&1; then
            print_success "Download complete"
            return 0
        fi
        
        if [[ $attempt -lt $max_attempts ]]; then
            print_warning "Download failed, retrying in 5 seconds..."
            sleep 5
        fi
    done
    
    print_error "Download failed after $max_attempts attempts"
    return 1
}

# Verify file checksum (SHA256)
verify_checksum() {
    local file="$1"
    local expected_checksum="$2"
    
    if [[ -z "$expected_checksum" ]]; then
        print_warning "No checksum provided, skipping verification"
        return 0
    fi
    
    print_info "Verifying checksum..."
    
    local actual_checksum
    actual_checksum=$(sha256sum "$file" | awk '{print $1}')
    
    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
        print_success "Checksum verified"
        return 0
    else
        print_error "Checksum mismatch!"
        print_error "Expected: $expected_checksum"
        print_error "Got:      $actual_checksum"
        return 1
    fi
}

# ---- Disk Space Functions ----

# Check available disk space in MB
check_disk_space() {
    local path="$1"
    local required_mb="$2"
    
    local available_mb
    available_mb=$(df -BM "$path" | tail -n1 | awk '{print $4}' | sed 's/M//')
    
    if [[ $available_mb -lt $required_mb ]]; then
        print_error "Insufficient disk space"
        print_error "Required: ${required_mb}MB, Available: ${available_mb}MB"
        return 1
    fi
    
    print_info "Disk space check: ${available_mb}MB available (${required_mb}MB required)"
    return 0
}

# ---- File Operations ----

# Create backup of a file or directory
create_backup() {
    local source="$1"
    local backup_suffix="${2:-.backup.$(date +%s)}"
    
    if [[ ! -e "$source" ]]; then
        return 0  # Nothing to backup
    fi
    
    local backup="${source}${backup_suffix}"
    
    print_info "Creating backup: $backup"
    
    if cp -r "$source" "$backup" 2>/dev/null || sudo cp -r "$source" "$backup"; then
        print_success "Backup created"
        echo "$backup"  # Return backup path
        return 0
    else
        print_error "Failed to create backup"
        return 1
    fi
}

# Restore from backup
restore_backup() {
    local backup="$1"
    local target="$2"
    
    if [[ ! -e "$backup" ]]; then
        print_error "Backup not found: $backup"
        return 1
    fi
    
    print_info "Restoring from backup..."
    
    if cp -r "$backup" "$target" 2>/dev/null || sudo cp -r "$backup" "$target"; then
        print_success "Restored from backup"
        return 0
    else
        print_error "Failed to restore from backup"
        return 1
    fi
}

# ---- Process Management ----

# Check if script is already running
check_lock() {
    local lock_file="$1"
    local lock_dir
    lock_dir="$(dirname "$lock_file")"
    
    mkdir -p "$lock_dir"
    
    if [[ -f "$lock_file" ]]; then
        local pid
        pid=$(cat "$lock_file" 2>/dev/null)
        
        if [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null; then
            print_error "Another instance is already running (PID: $pid)"
            return 1
        else
            print_warning "Stale lock file found, removing..."
            rm -f "$lock_file"
        fi
    fi
    
    echo $$ > "$lock_file"
    return 0
}

# Release lock file
release_lock() {
    local lock_file="$1"
    rm -f "$lock_file"
}

# ---- Shell Configuration ----

# Determine shell RC file
get_shell_rc() {
    local shell_name
    shell_name="$(basename "${SHELL:-bash}")"
    
    if [[ "$shell_name" == "zsh" ]]; then
        echo "$HOME/.zshrc"
    else
        echo "$HOME/.bashrc"
    fi
}

# Add or update managed block in RC file
update_rc_block() {
    local rc_file="$1"
    local marker_start="$2"
    local marker_end="$3"
    local content="$4"
    
    if [[ ! -f "$rc_file" ]]; then
        touch "$rc_file"
    fi
    
    # Remove existing block if present
    if grep -qF "$marker_start" "$rc_file" 2>/dev/null; then
        awk -v s="$marker_start" -v e="$marker_end" '
            $0==s {skip=1}
            !skip {print}
            $0==e {skip=0; next}
        ' "$rc_file" > "$rc_file.tmp" && mv "$rc_file.tmp" "$rc_file"
    fi
    
    # Add new block
    {
        echo ""
        echo "$marker_start"
        echo "$content"
        echo "$marker_end"
    } >> "$rc_file"
}

# ---- Cleanup ----

# Setup cleanup trap
setup_cleanup() {
    local cleanup_function="$1"
    trap "$cleanup_function" EXIT INT TERM
}
