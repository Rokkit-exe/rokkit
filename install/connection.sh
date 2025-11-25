#!/bin/bash


source ../lib/print.sh

print_info "Checking Network"

# Check wired
if ip addr | grep -E "eth|enp|ens" | grep "inet " > /dev/null; then
    print_success "✓ Wired connection active"
    ip addr show | grep -E "eth|enp|ens" -A 1 | grep inet
else
    print_info "✗ No wired connection"
    echo
    print_info "Available WiFi"
    
    # Check if wifi interface exists
    if ! ip link show | grep -E "wlan|wlp" > /dev/null; then
        print_error "No wireless interfaces found."
        exit 1
    fi
    
    wifi_interface=$(ip link show | grep -E "wlan|wlp" | awk '{print $2}' | sed 's/:$//' | head -1)
    # Scan for networks (required before get-networks works)
    iwctl station "$wifi_interface" scan
    gum spin --spinner dot --title "Scanning nearby wifi networks for $wifi_interface:" -- sleep 3
    
    # Get list of networks and format for gum
    networks=$(iwctl station "$wifi_interface" get-networks | tail -n +6 | awk '{print $1}')
    
    if [ -z "$networks" ]; then
        print_error "No WiFi networks found."
        exit 1
    fi
    
    # Use gum to select network
    selected=$(echo "$networks" | gum choose --header "Choose a WiFi network")
    
    if [ -z "$selected" ]; then
        print_error "No network selected."
        exit 1
    fi
    
    print_info "Connecting to $selected..."
    iwctl station "$wifi_interface" connect "$selected"
fi
