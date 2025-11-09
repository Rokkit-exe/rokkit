#!/usr/bin/env bash

# Script to disable USB wake for specific devices
# This script is meant to be installed to /usr/local/bin/ and run by systemd service

for device in XHC0 XHC1 XHC2; do
    status=$(grep -P "^$device\b" /proc/acpi/wakeup 2>/dev/null | awk '{print $3}')
    if [[ "$status" == "*enabled" ]]; then
        echo "$device" >/proc/acpi/wakeup
    fi
done
