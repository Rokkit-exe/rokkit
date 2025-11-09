#!/bin/bash

for device in XHC0 XHC1 XHC2; do
  status=$(grep -P "^$device\b" /proc/acpi/wakeup | awk '{print $3}')
  if [[ "$status" == "*enabled" ]]; then
    echo "$device" >/proc/acpi/wakeup
  fi
done
