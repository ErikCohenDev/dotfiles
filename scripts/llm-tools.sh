#!/bin/bash
###############################################################################
# LLM Integration Tools
# Version: 1.0.0
#
# Functions for interacting with LLM services
###############################################################################

# Source core utilities if not already sourced
if [[ -z "$CORE_SOURCED" ]]; then
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  source "$script_dir/dev-tools/core.sh"
  CORE_SOURCED=true
fi

# Check dependencies
check_dependencies gh || exit 1

# LLM Command Helper
??() {
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

  echo "🤔 Thinking..."
  # Use bwsecurerun to safely use the token
  bwsecurerun "GitHub Copilot CLI Token" GITHUB_COPILOT_CLI_TOKEN gh copilot suggest -t shell "$*"
}

# Export the function to be available in shell
export -f ??