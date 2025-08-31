#!/usr/bin/env bash

# Safe shell options (don't use -u because script tests for file existence; keep predictable failures)
set -eE -o pipefail

DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
DRY_RUN=${DRY_RUN:-0}

# Parse args
if [[ "${1:-}" == "--dry-run" ]]; then
  DRY_RUN=1
  shift || true
fi
BACKUP_DIR="$HOME/.dotfiles_backup/$(date +%Y%m%d-%H%M%S)"

# Create backup directory if needed
mkdir -p "$BACKUP_DIR"

# Create symbolic link with backup (required)
link_file() {
  local src="$1" dest="$2"
  if [ ! -e "$src" ]; then
    echo "❌ Source missing: $src" >&2
    return 1
  fi
  # Backup existing file if it exists and isn't already linked to desired source
  if [ -e "$dest" ] && { [ ! -L "$dest" ] || [ "$(readlink "$dest" 2>/dev/null)" != "$src" ]; }; then
    mkdir -p "$BACKUP_DIR"
    echo "⚠️  Backing up $dest → $BACKUP_DIR/"
    if [[ "$DRY_RUN" == "1" ]]; then
      echo "[dry-run] mv '$dest' '$BACKUP_DIR/'"
    else
      mv "$dest" "$BACKUP_DIR/" || return 1
    fi
  fi
  mkdir -p "$(dirname "$dest")"
  echo "🔗 Linking $src → $dest"
  if [[ "$DRY_RUN" == "1" ]]; then
    echo "[dry-run] ln -sfn '$src' '$dest'"
  else
    ln -sfn "$src" "$dest"
  fi
}

# Create symbolic link only if source exists (optional)
link_if_exists() {
  local src="$1" dest="$2"
  if [ ! -e "$src" ]; then
    echo "⏭️  Skipping missing optional source: $src" >&2
    return 0
  fi
  link_file "$src" "$dest"
}

# Link dotfiles
echo "🚀 Setting up dotfiles..."

# Create directories if needed
mkdir -p "$HOME/.config/nvim"
mkdir -p "$HOME/bin"
mkdir -p "$HOME/.config/dev-tools"
mkdir -p "$HOME/.cache/dev-tools"

# ZSH configuration (optional: repo may start minimal)
link_if_exists "$DOTFILES_DIR/home/.zshrc" "$HOME/.zshrc"

# Bitwarden Secret Manager
link_if_exists "$DOTFILES_DIR/scripts/bw-secret-manager.sh" "$HOME/.bw-secret-manager.sh"

# History Manager
link_if_exists "$DOTFILES_DIR/scripts/history-manager.sh" "$HOME/.history-manager.sh"

# Development Tools (minimal by default)
link_if_exists "$DOTFILES_DIR/scripts/dev-tools/dev.sh" "$HOME/bin/dev"

# Optionally link legacy interactive tools if requested
if [ "${INSTALL_LEGACY_TOOLS:-}" = "1" ]; then
  link_if_exists "$DOTFILES_DIR/scripts/dev-tools/workflow.sh" "$HOME/bin/dev-workflow"
  link_if_exists "$DOTFILES_DIR/scripts/dev-tools/jira.sh" "$HOME/bin/jira-tool"
  link_if_exists "$DOTFILES_DIR/scripts/dev-tools/github.sh" "$HOME/bin/github-tool"
fi

# LLM Tools
link_file "$DOTFILES_DIR/scripts/llm-tools.sh" "$HOME/.llm-tools.sh"

# Make the tools executable (ignore failures gracefully)
if [[ "$DRY_RUN" == "1" ]]; then
  echo "[dry-run] chmod +x '$DOTFILES_DIR/scripts/dev-tools/'*.sh"
  echo "[dry-run] chmod +x '$DOTFILES_DIR/scripts/llm-tools.sh'"
else
  chmod +x "$DOTFILES_DIR/scripts/dev-tools/"*.sh 2>/dev/null || true
  chmod +x "$DOTFILES_DIR/scripts/llm-tools.sh" 2>/dev/null || true
fi

# Git config (optional)
link_if_exists "$DOTFILES_DIR/home/.gitconfig" "$HOME/.gitconfig"

# Neovim config
link_file "$DOTFILES_DIR/config/nvim/init.lua" "$HOME/.config/nvim/init.lua"

if [[ "$DRY_RUN" == "1" ]]; then
  echo "✅ Dry-run complete. No changes were made."
else
  echo "✅ Dotfiles linked successfully!"
  echo "✅ Development tools installed!"
fi
echo "🔍 Ensure ~/bin is in PATH (echo $PATH | grep -q '~/bin' || echo 'Add export PATH=\"$HOME/bin:$PATH\" to ~/.zshrc')"
echo "🔄 Restart your terminal or run: source ~/.zshrc"
