# Aliases
alias ll='ls -la'
alias v='nvim'

# pyenv
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
eval "$(pyenv init --path)"
eval "$(pyenv init -)"

# Path to Oh My Zsh installation
export ZSH="$HOME/.oh-my-zsh"

# Set theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Define plugins BEFORE loading Oh My Zsh
plugins=(
  git
  fzf
  vi-mode
  zsh-syntax-highlighting
  zsh-autosuggestions
)

# Load Oh My Zsh first to set up environment
source $ZSH/oh-my-zsh.sh
[[ -f ~/.p10k.zsh ]] && source ~/.p10k.zsh

# AFTER Oh My Zsh, load security tools
if [ -f ~/.bw-secret-manager.sh ]; then
  source ~/.bw-secret-manager.sh
fi

if [ -f ~/.history-manager.sh ]; then
  source ~/.history-manager.sh
fi

# Add dotfiles directory to PATH for custom scripts
if [ -d ~/dotfiles/scripts ]; then
  export PATH="$HOME/dotfiles/scripts:$PATH"
fi

# Source local customizations if they exist (not tracked in git)
if [ -f ~/.zshrc.local ]; then
  source ~/.zshrc.local
fi