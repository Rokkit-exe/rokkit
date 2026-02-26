# Set the directory we want to store zinit and plugins
ZINIT_HOME="${XDG_DATA_HOME:-${HOME}/.local/share}/zinit/zinit.git"

# Download Zinit, if it's not there yet
if [ ! -d "$ZINIT_HOME" ]; then
   mkdir -p "$(dirname $ZINIT_HOME)"
   git clone https://github.com/zdharma-continuum/zinit.git "$ZINIT_HOME"
fi


# Source/Load zinit
source "${ZINIT_HOME}/zinit.zsh"

# Add in zsh plugins
zinit light zsh-users/zsh-syntax-highlighting
zinit light zsh-users/zsh-completions
zinit light zsh-users/zsh-autosuggestions
zinit light Aloxaf/fzf-tab

autoload -Uz compinit && compinit

zinit cdreplay -q

# History
HISTSIZE=5000
HISTFILE=~/.zsh_history
SAVEHIST=$HISTSIZE
HISTDUP=erase
setopt appendhistory
setopt sharehistory
setopt hist_ignore_space
setopt hist_ignore_all_dups
setopt hist_save_no_dups
setopt hist_ignore_dups
setopt hist_find_no_dups

# Completion styling
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Za-z}'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'ls --color $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'ls --color $realpath'

# Shell integrations
# fuzzy finder
eval "$(fzf --zsh)"
# cd replacement
eval "$(zoxide init --cmd cd zsh)"
# theming
eval "$(starship init zsh)"

# Disable vim mode, use emacs mode
bindkey -e

# aliases
alias python='python3'
alias pip='pip3'

# networking
alias public-ip='curl ipinfo.io/ip'
alias ports='netstat -tulanp'

# alternatives
alias cat='bat'
alias grep='rg'
alias ls='ls --color'
alias cheat='rokkit-cheatsheet'

# Directories
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'


# Golang
if [[ ":PATH:" != *":/usr/local/go/bin:"* ]]; then
  export PATH=$PATH:/usr/local/go/bin
fi
if [[ ":PATH:" != *":$(go env GOPATH)/bin:"* ]]; then
  export PATH="$PATH:$(go env GOPATH)/bin"
fi

if [[ ":PATH:" != *"$HOME/.local/share/rokkit/bin:"* ]]; then
  export PATH=$PATH:$HOME/coding/rokkit/bin
fi

