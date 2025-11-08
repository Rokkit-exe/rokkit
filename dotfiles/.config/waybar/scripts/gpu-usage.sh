#!/bin/bash

# GPU core usage
USAGE=$(radeontop -d - -l 1 -c 1 | grep -m 1 "gpu" | awk '{print int($2)}')

# VRAM usage (card1)
VRAM_USED=$(cat /sys/class/drm/card1/device/mem_info_vram_used)
VRAM_TOTAL=$(cat /sys/class/drm/card1/device/mem_info_vram_total)

VRAM_USED_MB=$((VRAM_USED / 1024 / 1024))
VRAM_TOTAL_MB=$((VRAM_TOTAL / 1024 / 1024))
VRAM_PERCENT=$((100 * VRAM_USED_MB / VRAM_TOTAL_MB))

# GPU temperature (from hwmon under card1)
HWMON_PATH=$(readlink -f /sys/class/drm/card1/device/hwmon/hwmon*)
TEMP_RAW=$(cat "$HWMON_PATH/temp1_input")
TEMP_C=$((TEMP_RAW / 1000))

# Output to Waybar
echo "GPU:  ${USAGE}%  ${VRAM_PERCENT}%  ${TEMP_C}°C"
