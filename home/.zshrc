# Minimal ZSH configuration for secure dotfiles

# Ensure ~/bin comes first
export PATH="$HOME/bin:$PATH"

# Source optional helpers if present
[ -f "$HOME/.bw-secret-manager.sh" ] && source "$HOME/.bw-secret-manager.sh"
[ -f "$HOME/.history-manager.sh" ] && source "$HOME/.history-manager.sh"

# Local overrides (not tracked)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"

# Aliases
alias ll='ls -la'
alias dev='dev'

