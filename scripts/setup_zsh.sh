#!/usr/bin/env bash

set -euo pipefail

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Output functions
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

print_info() {
    echo -e "${BLUE}➜${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Detect distribution
DISTRO=$(grep ^PRETTY_NAME= /etc/os-release | cut -d= -f2 | tr -d '"')

# Install ZSH if not already installed
if ! command -v zsh &> /dev/null; then
    print_info "ZSH not found. Installing..."
    
    if [[ "$DISTRO" == *"Arch Linux"* ]]; then
        sudo pacman -S --noconfirm --needed zsh || {
            print_error "Failed to install ZSH"
            exit 1
        }
    elif [[ "$DISTRO" == *"Ubuntu"* ]] || [[ "$DISTRO" == *"Debian"* ]]; then
        sudo apt update && sudo apt install -y zsh || {
            print_error "Failed to install ZSH"
            exit 1
        }
    else
        print_error "Unsupported distribution: $DISTRO"
        print_info "Please install ZSH manually and run this script again"
        exit 1
    fi
    
    print_success "ZSH installed successfully"
else
    print_success "ZSH is already installed"
fi

# Get path to ZSH
ZSH_PATH="$(which zsh)"

# Set ZSH as default shell if not already set
if [[ "$SHELL" == "$ZSH_PATH" ]]; then
    print_success "ZSH is already the default shell"
else
    print_info "Setting ZSH as the default shell..."
    chsh -s "$ZSH_PATH" || {
        print_warning "Failed to set ZSH as default shell. You may need to run: chsh -s $ZSH_PATH"
    }
    print_success "ZSH set as default shell (log out and back in for changes to take effect)"
fi

# Install Oh-My-ZSH if not already installed
if [[ -d "$HOME/.oh-my-zsh" ]]; then
    print_success "Oh-My-ZSH is already installed"
else
    print_info "Installing Oh-My-ZSH..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
        print_error "Failed to install Oh-My-ZSH"
        exit 1
    }
    print_success "Oh-My-ZSH installed successfully"
fi

# Install ZSH plugins
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

print_info "Installing ZSH plugins..."

# zsh-syntax-highlighting
if [[ -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
    print_success "zsh-syntax-highlighting already installed"
else
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" && \
        print_success "zsh-syntax-highlighting installed" || \
        print_warning "Failed to install zsh-syntax-highlighting"
fi

# zsh-autosuggestions
if [[ -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]]; then
    print_success "zsh-autosuggestions already installed"
else
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions" && \
        print_success "zsh-autosuggestions installed" || \
        print_warning "Failed to install zsh-autosuggestions"
fi

# zsh-completions
if [[ -d "$ZSH_CUSTOM/plugins/zsh-completions" ]]; then
    print_success "zsh-completions already installed"
else
    git clone https://github.com/zsh-users/zsh-completions \
        "$ZSH_CUSTOM/plugins/zsh-completions" && \
        print_success "zsh-completions installed" || \
        print_warning "Failed to install zsh-completions"
fi

# Install Powerlevel10k theme
if [[ -d "$ZSH_CUSTOM/themes/powerlevel10k" ]]; then
    print_success "Powerlevel10k theme already installed"
else
    print_info "Installing Powerlevel10k theme..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
        "$ZSH_CUSTOM/themes/powerlevel10k" && \
        print_success "Powerlevel10k theme installed" || \
        print_warning "Failed to install Powerlevel10k theme"
fi

echo ""
print_success "ZSH setup complete!"
echo ""
print_info "Next steps:"
echo "  1. Log out and back in for shell changes to take effect"
echo "  2. Update your .zshrc to enable plugins:"
echo "     plugins=(git zsh-syntax-highlighting zsh-autosuggestions zsh-completions)"
echo "  3. Set Powerlevel10k theme in .zshrc:"
echo "     ZSH_THEME=\"powerlevel10k/powerlevel10k\""
echo "  4. Run: source ~/.zshrc"
echo "  5. Configure Powerlevel10k with: p10k configure"
echo ""
