#!/bin/bash

cp /usr/share/hyprland/hyprland.conf "/home/$USER_NAME/.config/hypr/"

chown -R "$USER_NAME:$USER_NAME" "/home/$USER_NAME/.config/hypr/"
print_success "Hyprland configuration copied to /home/$USER_NAME/.config/hypr/"
