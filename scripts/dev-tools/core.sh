#!/usr/bin/env bash
set -Eeo pipefail
# filepath: /Users/ecohen/dotfiles/scripts/dev-tools/core.sh

###############################################################################
# Development Tools - Core Utilities
# Version: 1.0.0
#
# Core functions and utilities for development workflow
###############################################################################

# Configuration paths
CONFIG_DIR="$HOME/.config/dev-tools"
CONFIG_FILE="$CONFIG_DIR/config.json"
CACHE_DIR="$HOME/.cache/dev-tools"
LOG_FILE="$CONFIG_DIR/dev-tools.log"

# Ensure directories exist
mkdir -p "$CONFIG_DIR"
mkdir -p "$CACHE_DIR"
touch "$LOG_FILE"
chmod 600 "$LOG_FILE" 2>/dev/null || true

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Log message with timestamp (redact obvious secrets)
log_message() {
  local msg="$1"
  # Basic redaction for patterns like KEY=****, token: **** etc.
  msg=$(echo "$msg" | sed -E 's/([A-Za-z0-9_]*(KEY|TOKEN|SECRET|PASSWORD)[A-Za-z0-9_]*=)[^ ]+/\1REDACTED/gI')
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $msg" >> "$LOG_FILE"
}

# Print colored output
print_info() {
  echo -e "${BLUE}$1${NC}"
}

print_success() {
  echo -e "${GREEN}$1${NC}"
}

print_warning() {
  echo -e "${YELLOW}$1${NC}"
}

print_error() {
  echo -e "${RED}$1${NC}"
  log_message "ERROR: $1"
}

# Config management
# Ensure essential dependencies for config helpers are present when used
get_config() {
  local key="$1"
  local default="$2"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "$default"
    return
  fi

  if ! command_exists jq; then
    echo "$default"
    return
  fi

  value=$(jq -r ".$key // \"\"" "$CONFIG_FILE" 2>/dev/null)
  if [[ -z "$value" || "$value" == "null" ]]; then
    echo "$default"
  else
    echo "$value"
  fi
}

save_config() {
  local key="$1"
  local value="$2"

  if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "{}" > "$CONFIG_FILE"
  fi

  # Create temporary file
  local tmp_file=$(mktemp)

  # Update config
  if command_exists jq; then
    jq ".$key = \"$value\"" "$CONFIG_FILE" > "$tmp_file"
  else
    # Fallback: naive update (overwrites file with only this key)
    printf '{"%s":"%s"}\n' "$key" "$value" > "$tmp_file"
  fi
  mv "$tmp_file" "$CONFIG_FILE"

  chmod 600 "$CONFIG_FILE"
}

# Cache management
save_cache() {
  local key="$1"
  local value="$2"

  echo "$value" > "$CACHE_DIR/$key"
}

get_cache() {
  local key="$1"
  local cache_file="$CACHE_DIR/$key"

  if [[ -f "$cache_file" ]]; then
    cat "$cache_file"
  else
    echo ""
  fi
}

# Format text to not exceed max line length
format_text() {
  local text="$1"
  local max_length=${2:-100}

  echo "$text" | fold -s -w "$max_length"
}

# Check if command exists
command_exists() { command -v "$1" >/dev/null 2>&1; }

# Check required dependencies
check_dependencies() {
  local need=() missing=0
  for cmd in "$@"; do command_exists "$cmd" || need+=("$cmd"); done
  if ((${#need[@]})); then
    for m in "${need[@]}"; do print_error "Missing dependency: $m"; done
    print_error "Install the above before continuing."; return 1; fi
}

# Setup configuration interactively
setup_core_config() {
  print_info "Setting up core configuration..."

  read -p "Max line length for commit messages [100]: " input
  local max_length=${input:-100}
  save_config "max_line_length" "$max_length"

  read -p "Default editor [vim]: " input
  local editor=${input:-vim}
  save_config "editor" "$editor"

  print_success "Core configuration saved!"
}

# Get user confirmation
confirm() {
  local message="$1"
  local default="${2:-Y}"

  if [[ "$default" == "Y" ]]; then
    read -p "$message [Y/n]: " response
    [[ -z "$response" || "$response" =~ ^[Yy] ]]
  else
    read -p "$message [y/N]: " response
    [[ "$response" =~ ^[Yy] ]]
  fi
}

# Export functions to be used in other scripts
export -f log_message
export -f print_info print_success print_warning print_error
export -f get_config save_config
export -f save_cache get_cache
export -f format_text
export -f command_exists check_dependencies
export -f confirm
