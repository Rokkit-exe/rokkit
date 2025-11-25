#!/bin/bash

source ../lib/print.sh

choose_locale() {
    local locales=("en_CA.UTF-8" "fr_CA.UTF-8")
    LOCALE=$(choose "Choose a locale:" "${locales[@]}")
}


choose_layout() {
    local layouts=("us" "ca")
    KEYBOARD_LAYOUT=$(choose "Choose a keyboard layout:" "${layouts[@]}")
}

choose_mirrorlist() {
    local mirrorlists=("Canada" "United States")
    MIRRORLIST=$(choose "Choose a mirrorlist:" "${mirrorlists[@]}")
}

choose_drive() {
    # show full drive info for selection
    lsblk | cat 
    drives_info=()

    while IFS= read -r line; do
      drives_info+=("$line")
    done < <(lsblk -d -n -o NAME,SIZE,MODEL)

    DISK_SELECTION=$(choose "Choose the target disk for installation:" "${drives_info[@]}")
    DISK=$(echo "/dev/$DISK_SELECTION" | awk '{print $1}')
    echo "Selected disk: $DISK"
}

choose_hostname() {
    HOST_NAME=$(gum input --header.foreground 4 --header "Enter the hostname for your system:" --placeholder "rokkitos")
    print_info "Setting hostname to $HOST_NAME"
}

choose_username() {
    print_info "Enter a username for the new user:"
    USER_NAME=$(gum input --placeholder "rokkit")
    print_info "Setting username to $USER_NAME"
}

choose_password() {
   while true; do
       PASSWORD=$(gum input --header.foreground 4 --header "Set a password for user $USER_NAME:" --placeholder "password" --password)
       PASSWORD_CONFIRM=$(gum input --header.foreground 4 --header "Confirm the password for user $USER_NAME:" --placeholder "password" --password)
       if [ "$PASSWORD" == "$PASSWORD_CONFIRM" ]; then
           print_info "Password set for user $USER_NAME"
           break
       else
           gum style --foreground red --bold "Error: Passwords do not match. Please try again."
           sleep 2
       fi
   done
}

choose_same_password() {
    SAME_PASSWORD=$(choose "Do you want to set the same password for root user?" "Yes" "No")
}

choose_root_password() {
  while true; do
      ROOT_PASS=$(gum input --header.foreground 4 --header "Set a password for root user:" --placeholder "root password" --password)
      ROOT_PASS_CONFIRM=$(gum input --header.foreground 4 --header "Confirm the root password:" --placeholder "root password" --password)
      if [ "$ROOT_PASS" == "$ROOT_PASS_CONFIRM" ]; then
          print_info "Root password set"
          break
      else
          gum style --foreground red --bold "Error: Root passwords do not match. Please try again."
          sleep 2
      fi
  done
}

choose_git_info() {
  GIT_NAME=$(gum input --header.foreground 4 --header "Enter full name for Git user:" --placeholder "rokkit user")
  print_info "Setting Git user.name to $GIT_NAME"
  GIT_EMAIL=$(gum input --header.foreground 4 --header "Enter email for Git user:" --placeholder "rokkit@me.com")
}
print_info() {
    gum style --foreground 4 --bold "➜ $1"
}

confirm_settings() {
  echo
  gum format -t markdown -- << EOF

| Setting | Value |
|---------|-------|
| Hostname | $HOST_NAME |
| Username | $USER_NAME |
| Locale | $LOCALE |
| Keyboard Layout | $KEYBOARD_LAYOUT |
| Git Name | $GIT_NAME |
| Git Email | $GIT_EMAIL |
| Target Disk | $DISK |

EOF
echo
CONFIRM=$(choose "Are these settings correct?" "Yes" "No")
}


clear 
print_logo
echo
choose_locale

clear
print_logo
echo
choose_layout

clear
print_logo
echo
choose_mirrorlist

clear
print_logo
echo
choose_drive

clear
print_logo
echo
choose_hostname

clear
print_logo
echo
choose_username

clear
print_logo
echo
choose_password

clear
print_logo
echo
choose_same_password

if [ "$SAME_PASSWORD" == "No" ]; then
    clear
    print_logo
    choose_root_password
else
    ROOT_PASS=$PASSWORD
fi

clear
print_logo
choose_git_info

clear
print_logo
confirm_settings

if [ "$CONFIRM" == "No" ]; then
    exec ./install.sh
fi

print_info "All settings confirmed. Proceeding with installation..."



