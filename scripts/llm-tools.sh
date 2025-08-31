#!/usr/bin/env bash
set -Eeo pipefail
###############################################################################
# LLM Integration Tools
# Version: 1.0.0
#
# Functions for interacting with LLM services
###############################################################################

# Source core utilities if not already sourced (resolve symlinks)
if [[ -z "$CORE_SOURCED" ]]; then
  _resolve_script_dir_llm() {
    local src="${BASH_SOURCE[0]}"; local dir target
    while [ -h "$src" ]; do
      dir="$(cd -P "$(dirname "$src")" && pwd)"
      target="$(readlink "$src")"
      [[ $target != /* ]] && src="$dir/$target" || src="$target"
    done
    cd -P "$(dirname "$src")" && pwd
  }
  script_dir="$(_resolve_script_dir_llm)"
  # This file lives in scripts/, core is in scripts/dev-tools/core.sh
  if [ -f "$script_dir/dev-tools/core.sh" ]; then
    source "$script_dir/dev-tools/core.sh"
    CORE_SOURCED=true
  elif [ -f "$HOME/dotfiles/scripts/dev-tools/core.sh" ]; then
    # Fallback to conventional repo location
    source "$HOME/dotfiles/scripts/dev-tools/core.sh"
    CORE_SOURCED=true
  fi
fi

# Do not hard-exit on shell load if gh is missing; check at call time instead

# LLM Command Helper
# Human friendly helper (invoked as '?? "question"') using alias instead of invalid bash function name
_llm_explain() {
  if [ -z "$1" ]; then
    echo "Usage: ?? 'your question about a command'"
    return 1
  fi

  # Check if GITHUB_COPILOT_CLI_TOKEN is set
  if [ -z "$GITHUB_COPILOT_CLI_TOKEN" ]; then
    echo "⚠️  GitHub Copilot CLI token not found."
    echo "Please set GITHUB_COPILOT_CLI_TOKEN using:"
    echo "bwstorekey 'GitHub Copilot CLI Token' 'your-token' 'API Keys'"
    return 1
  fi

  if ! command_exists gh; then
    echo "❌ GitHub CLI (gh) is not installed."
    return 1
  fi

  echo "🤔 Thinking..."
  # Use bwsecurerun if available; otherwise pass token via env for this invocation
  if command -v bwsecurerun >/dev/null 2>&1; then
    bwsecurerun "GitHub Copilot CLI Token" GITHUB_COPILOT_CLI_TOKEN gh copilot suggest -t shell "$*"
  else
    env GITHUB_COPILOT_CLI_TOKEN="$GITHUB_COPILOT_CLI_TOKEN" gh copilot suggest -t shell "$*"
  fi
}

# Provide alias if interactive
if [[ $- == *i* ]]; then
  alias '??'='_llm_explain'
fi

export -f _llm_explain
