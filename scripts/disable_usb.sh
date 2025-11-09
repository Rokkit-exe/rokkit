if [[ ! -f /usr/local/bin/disable-usb-wake.sh && ! -f /etc/systemd/system/disable-usb-wake.service ]]; then
  echo "Disabling USB wakeup for device XHC0, XHC1, XHC2..."
  # check /proc/acpi/wakeup to validate
  script_path="/home/frank/.local/share/chezmoi/dot_rokkit/scripts/disable_usb_wake.sh"
  service_path="/home/frank/.local/share/chezmoi/dot_rokkit/services/disable-usb-wakeup.service"
  sudo cp $script_path /usr/local/bin/disable-usb-wake.sh
  sudo chmod 755 /usr/local/bin/disable-usb-wake.sh
  sudo cp $service_path /etc/systemd/system/disable-usb-wake.service
  sudo chmod 644 /etc/systemd/system/disable-usb-wake.service
  sudo systemctl enable disable-usb-wake.service
  sudo systemctl start disable-usb-wake.service
  echo "USB wakeup disabled for device XHC0, XHC1, XHC2."
else
  echo "USB wakeup is already disabled for device XHC0, XHC1, XHC2."
fi
