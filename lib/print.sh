#!/usr/bin/env bash

# Rokkit Common Library
# Shared functions for all Rokkit scripts

# ---- Output Functions ----

print_title() {
    gum style --padding "0 5" --bold --italic --border double --align center --border-foreground 4 "$1"
}

print_success() {
    gum style --foreground 2 --bold --italic "✓ $1"
}

print_info() {
    gum style --foreground 4 --bold "➜ $1"
}

print_warning() {
    gum style --foreground 3 --bold "⚠ $1"
}

print_error() {
    gum style --foreground 1 --bold "✗ $1"
}

separator(){ echo "----------------------------------------------------------------------"; }
