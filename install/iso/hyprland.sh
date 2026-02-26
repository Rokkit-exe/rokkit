#!/bin/bash

mkdir -p "/home/$USER_NAME/.config/hypr/"
cp /usr/share/hypr/hyprland.conf "/home/$USER_NAME/.config/hypr/"
cp /usr/share/hypr/hypridle.conf "/home/$USER_NAME/.config/hypr/"
cp /usr/share/hypr/hyprlock.conf "/home/$USER_NAME/.config/hypr/"

chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME/.config/hypr/"
print_success "Hyprland configuration copied to /home/$USER_NAME/.config/hypr/"
