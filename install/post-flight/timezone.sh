#!/bin/bash

# Auto-detect timezone
TIMEZONE=$(curl -s https://ipapi.co/json | jq -r '.timezone')

if [ -z "$TIMEZONE" ]; then
    echo "Failed to detect timezone, using UTC"
    TIMEZONE="UTC"
fi

echo "Setting timezone to: $TIMEZONE"
ln -sf "/usr/share/zoneinfo/$TIMEZONE" /etc/localtime
hwclock --systohc

# making sure system clock is accurate
timedatectl
