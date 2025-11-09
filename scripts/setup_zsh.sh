#!/bin/bash

DISTRO=$(grep ^PRETTY_NAME= /etc/os-release | cut -d= -f2 | tr -d '"')

if [[ "$DISTRO" == *"Arch Linux"* ]]; then
  echo "Installing ZSH..."
  sudo pacman -S --noconfirm --needed zsh
elif [[ "$DISTRO" == *"Ubuntu"* ]]; then
  sudo apt install -y zsh
fi

# Get path to ZSH
ZSH_PATH="$(which zsh)"

# Check if ZSH is already the default shell
if [[ "$SHELL" == "$ZSH_PATH" ]]; then
  echo "✅ ZSH is already the default shell. Skipping installation..."
else
  echo "🛠️ Setting ZSH as the default shell..."
  chsh -s "$ZSH_PATH"
  echo "✅ ZSH set as default shell (you may need to log out and back in)."

  # Install ZSH if it's not installed (optional check)
  if ! command -v zsh &> /dev/null; then
    echo "Installing ZSH..."
    sudo apt install -y zsh
  fi

  echo "🎉 Installing Oh-My-ZSH..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

  echo "🔌 Installing ZSH plugins..."
  git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"

  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"

  git clone https://github.com/zsh-users/zsh-completions \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-completions"

  echo "🎨 Installing Powerlevel10k theme..."
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
    "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

  echo "✅ ZSH, Oh-My-ZSH, plugins, and theme installed."
fi

