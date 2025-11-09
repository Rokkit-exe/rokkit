#!/bin/bash


# Font download URLs
FONT_URLS=(
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/AdwaitaMono.zip"
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/FiraCode.zip"
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/JetBrainsMono.zip"
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Meslo.zip"
  "https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/Noto.zip"
)

# Determine install path (user vs system)
if [ "$EUID" -eq 0 ]; then
    FONT_DIR="/usr/share/fonts/nerd-fonts"
else
    FONT_DIR="$HOME/.local/share/fonts/nerd-fonts"
fi

if [ -d $FONT_DIR ]; then
  echo "Fonts already installed to: $FONT_DIR"
else
  # Create font directory
  mkdir -p "$FONT_DIR"
  TEMP_DIR=$(mktemp -d)

  echo "Installing fonts to: $FONT_DIR"
  echo "Temporary working directory: $TEMP_DIR"

  # Download, unzip, and move fonts
  for URL in "${FONT_URLS[@]}"; do
      FILENAME=$(basename "$URL")
      echo "Downloading $FILENAME..."
      curl -L -o "$TEMP_DIR/$FILENAME" "$URL"

      echo "Unzipping $FILENAME..."
      unzip -q "$TEMP_DIR/$FILENAME" -d "$TEMP_DIR"

      echo "Installing $FILENAME fonts..."
      find "$TEMP_DIR" -name "*.ttf" -exec cp {} "$FONT_DIR/" \;
      find "$TEMP_DIR" -name "*.otf" -exec cp {} "$FONT_DIR/" \;
  done

  # Set permissions (important if system-wide)
  if [ "$EUID" -eq 0 ]; then
      chmod -R 644 "$FONT_DIR"
      fc-cache -fv
  else
      fc-cache -fv "$FONT_DIR"
  fi

  # Cleanup
  rm -rf "$TEMP_DIR"

  echo "✅ Fonts installed and cache refreshed."
fi
