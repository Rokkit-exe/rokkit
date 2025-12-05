#!/bin/bash

# Rokkit Common Library
# Shared functions for all Rokkit scripts

# ---- Output Functions ----
#
PRE_FLIGHT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${PRE_FLIGHT_DIR}/.." && pwd)"
echo "ROOT_DIR is $ROOT_DIR"

set -eu

clear() {
    printf "\033c"
}

print_logo() {
  while IFS= read -r line; do
      gum style --foreground 4 "$line"
  done < "$ROOT_DIR/logo.txt"
}

print_title() {
    gum style --padding "0 5" --bold --italic --border double --align center --border-foreground 4 "$1"
    echo
}

print_success() {
    echo
    gum style --foreground 2 --bold --italic "✓ $1"
    echo
}

print_info() {
    echo
    gum style --foreground 4 --bold "➜ $1"
    echo
}

print_warning() {
    echo
    gum style --foreground 3 --bold "⚠ Warning: $1"
    echo
}

print_error() {
    echo
    gum style --foreground 1 --bold "✗ Error: $1"
    echo
}

choose() {
    gum choose --item.foreground 4 --header.foreground 4 --cursor.foreground 2 --selected.foreground 2 --header "$1" "${@:2}"
}

input() {
    gum input --header.foreground 4 --header "$1" --placeholder "$2" "${@:3}"
}

separator(){ gum style --foreground 4 bold "----------------------------------------------------------------------"; }
