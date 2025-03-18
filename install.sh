#!/bin/bash

DOTFILES_DIR="$HOME/dotfiles"
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"

# Create backup directory if needed
mkdir -p "$BACKUP_DIR"

# Create symbolic link with backup
link_file() {
  local src="$1"
  local dest="$2"

  # Backup existing file if it exists and isn't already linked correctly
  if [ -e "$dest" ] && [ ! -L "$dest" -o "$(readlink "$dest")" != "$src" ]; then
    echo "⚠️  Backing up $dest → $BACKUP_DIR/"
    mv "$dest" "$BACKUP_DIR/"
  fi

  # Create symbolic link
  echo "🔗 Linking $src → $dest"
  ln -sf "$src" "$dest"
}

# Link dotfiles
echo "🚀 Setting up dotfiles..."

# Create directories if needed
mkdir -p "$HOME/.config/nvim"

# ZSH configuration
link_file "$DOTFILES_DIR/home/.zshrc" "$HOME/.zshrc"

# Bitwarden Secret Manager
link_file "$DOTFILES_DIR/scripts/bw-secret-manager.sh" "$HOME/.bw-secret-manager.sh"

# History Manager
link_file "$DOTFILES_DIR/scripts/history-manager.sh" "$HOME/.history-manager.sh"

# Git config
link_file "$DOTFILES_DIR/home/.gitconfig" "$HOME/.gitconfig"

# Neovim config
link_file "$DOTFILES_DIR/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"

echo "✅ Dotfiles linked successfully!"
echo "🔄 Please restart your terminal or run 'source ~/.zshrc' to apply changes."