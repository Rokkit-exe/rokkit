#!/bin/bash

# Get total CPU usage using top (average across all cores)
CPU_USAGE=$(top -bn1 | grep '%Cpu' | awk '{print int($2 + $4)}')

# Get CPU temperature (look for Package id 0 or highest value)
TEMP=$(grep -m 1 'Package id 0:' /proc/acpi/thermal_zone/*/thermal_zone*/temp 2>/dev/null | awk '{print int($2 / 1000)}')

# Fallback for AMD or alternative sensors
if [ -z "$TEMP" ]; then
  HWMON=$(readlink -f /sys/class/hwmon/hwmon*/temp1_input | head -n 1)
  TEMP_RAW=$(cat "$HWMON")
  TEMP=$((TEMP_RAW / 1000))
fi

# Output to Waybar
echo "CPU:  ${CPU_USAGE}%  ${TEMP}°C"
