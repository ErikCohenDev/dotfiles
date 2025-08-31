#!/bin/bash
set -Eeo pipefail
# filepath: /Users/ecohen/dotfiles/scripts/dev-tools/workflow.sh

###############################################################################
# Development Workflow Assistant
# Version: 1.0.0
#
# Integrates Jira and GitHub tools into a cohesive workflow
###############################################################################

# Get the directory of this script (resolve symlinks)
_resolve_script_dir_workflow() {
  local src="${BASH_SOURCE[0]}"; local dir target
  while [ -h "$src" ]; do
    dir="$(cd -P "$(dirname "$src")" && pwd)"
    target="$(readlink "$src")"
    [[ $target != /* ]] && src="$dir/$target" || src="$target"
  done
  cd -P "$(dirname "$src")" && pwd
}
script_dir="$(_resolve_script_dir_workflow)"

# Source component scripts
source "$script_dir/core.sh"
source "$script_dir/jira.sh"
source "$script_dir/github.sh"

print_header() {
  echo "=============================================="
  print_success "       Development Workflow Assistant      "
  echo "=============================================="
}

show_workflow_help() {
  cat << EOF
Development Workflow Assistant helps you streamline your development process:

1. View and select tickets from your Jira sprint
2. Create a properly named Git branch for your work
3. Make changes to the code
4. Commit changes with standardized commit messages
5. Push changes and create Pull Requests

You can also use the Jira and GitHub tools individually:
- Run 'jira-tool' for Jira-specific operations
- Run 'github-tool' for Git/GitHub-specific operations

EOF
}

# Main workflow
workflow_main() {
  print_header
  show_workflow_help

  # Check all dependencies first
  check_dependencies git curl jq || exit 1

  # First-time setup if needed
  if [[ ! -f "$CONFIG_FILE" ]]; then
    print_info "First-time setup"
    setup_core_config
    setup_jira_config
    setup_github_config
  fi

  while true; do
    echo ""
    print_info "Development Workflow"
    echo "---------------------------------------------"
    PS3="Select action: "
    options=(
      "View tickets"
      "Select ticket"
      "Create branch"
      "Make changes"
      "Commit changes"
      "Push and create PR"
      "Configure tools"
      "Help"
      "Exit"
    )
    select opt in "${options[@]}"
    do
      case $opt in
        "View tickets")
          get_jira_tickets
          break
          ;;
        "Select ticket")
          select_ticket
          break
          ;;
        "Create branch")
          create_branch
          break
          ;;
        "Make changes")
          print_info "Make your code changes now."
          print_info "When ready, select 'Commit changes' to proceed."
          break
          ;;
        "Commit changes")
          create_commit
          break
          ;;
        "Push and create PR")
          push_and_create_pr
          break
          ;;
        "Configure tools")
          configure_submenu
          break
          ;;
        "Help")
          show_workflow_help
          break
          ;;
        "Exit")
          print_success "Exiting Development Workflow Assistant. Goodbye!"
          exit 0
          ;;
        *)
          print_error "Invalid option $REPLY"
          break
          ;;
      esac
    done
  done
}

configure_submenu() {
  PS3="Select configuration: "
  options=("Core settings" "Jira settings" "GitHub settings" "Back to main menu")
  select opt in "${options[@]}"
  do
    case $opt in
      "Core settings")
        setup_core_config
        break
        ;;
      "Jira settings")
        setup_jira_config
        break
        ;;
      "GitHub settings")
        setup_github_config
        break
        ;;
      "Back to main menu")
        break
        ;;
      *)
        print_error "Invalid option $REPLY"
        break
        ;;
    esac
  done
}

# Run main workflow if executed directly
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  workflow_main
fi
