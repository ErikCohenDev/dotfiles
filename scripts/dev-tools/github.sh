#!/usr/bin/env bash
set -Eeo pipefail
# filepath: /Users/ecohen/dotfiles/scripts/dev-tools/github.sh

###############################################################################
# Development Tools - GitHub Integration
# Version: 1.0.0
#
# Functions for interacting with GitHub/Git
###############################################################################

# Source core utilities if not already sourced (resolve symlinks)
if [[ -z "$CORE_SOURCED" ]]; then
  _resolve_script_dir_git() {
    local src="${BASH_SOURCE[0]}"; local dir target
    while [ -h "$src" ]; do
      dir="$(cd -P "$(dirname "$src")" && pwd)"
      target="$(readlink "$src")"
      [[ $target != /* ]] && src="$dir/$target" || src="$target"
    done
    cd -P "$(dirname "$src")" && pwd
  }
  script_dir="$(_resolve_script_dir_git)"
  source "$script_dir/core.sh"
  CORE_SOURCED=true
fi

# Check dependencies
check_dependencies git jq || exit 1

# GitHub configuration
setup_github_config() {
  print_info "Setting up GitHub configuration..."

  read -p "GitHub repository (username/repo): " repo
  save_config "github_repo" "$repo"

  read -p "Default branch prefix [feature]: " input
  local branch_prefix=${input:-"feature"}
  save_config "branch_prefix" "$branch_prefix"

  read -p "Run local checks before commits? [Y/n]: " run_checks
  if [[ "$run_checks" =~ ^[Nn]$ ]]; then
    save_config "run_local_checks" "false"
  else
    save_config "run_local_checks" "true"
  fi

  print_success "GitHub configuration saved!"
}

# Create git branch for the ticket
create_branch() {
  local ticket_json=$(get_cache "selected_ticket.json")

  if [[ -z "$ticket_json" ]]; then
    print_error "No ticket selected."
    return 1
  fi

  local ticket_key=$(echo "$ticket_json" | jq -r ".key")
  local ticket_title=$(echo "$ticket_json" | jq -r ".title")
  local branch_prefix=$(get_config "branch_prefix" "feature")

  # Convert ticket title to kebab-case for branch name
  local normalized_title=$(echo "$ticket_title" | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:] -' | tr ' ' '-')
  normalized_title=$(echo "$normalized_title" | sed -E 's/-+/-/g; s/^-|-$//g')
  local branch_raw="${branch_prefix}/${ticket_key}-${normalized_title}"
  # Enforce length without adding ellipsis which creates invalid refs
  local branch_name=${branch_raw:0:60}

  # Check if we're in a git repository
  if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    print_error "Not in a git repository."
    return 1
  fi

  # Check if branch already exists
  if git show-ref --quiet "refs/heads/$branch_name"; then
    print_warning "Branch '$branch_name' already exists."
    if confirm "Do you want to use this branch?" "Y"; then
      git checkout "$branch_name"
      print_success "Switched to branch '$branch_name'"
    else
      return 1
    fi
  else
    # Create and checkout new branch from current branch
    git checkout -b "$branch_name"
    print_success "Created and switched to new branch '$branch_name'"
  fi

  # Store branch name for later use
  save_cache "current_branch" "$branch_name"
}

# Create commit with standardized message
create_commit() {
  local ticket_json=$(get_cache "selected_ticket.json")

  if [[ -z "$ticket_json" ]]; then
    print_error "No ticket selected."
    return 1
  fi

  local ticket_key=$(echo "$ticket_json" | jq -r ".key")
  local ticket_title=$(echo "$ticket_json" | jq -r ".title")
  local ticket_desc=$(echo "$ticket_json" | jq -r ".description")

  # Format commit message
  local commit_title="$ticket_key $ticket_title"
  local max_length=$(get_config "max_line_length" "100")
  local formatted_desc=$(format_text "$ticket_desc" "$max_length")

  # Create temporary commit message file
  local commit_file=$(mktemp)
  echo "$commit_title" > "$commit_file"
  echo "" >> "$commit_file"
  echo "$formatted_desc" >> "$commit_file"

  # Open editor to allow user to adjust commit message
  print_info "Opening editor to finalize commit message..."
  local editor=$(get_config "editor" "vim")
  $editor "$commit_file"

  # Stage all changes
  print_info "Staging changes..."
  git add .

  # Show changes to be committed
  print_info "Files to be committed:"
  git status --short

  if ! confirm "Proceed with commit?" "Y"; then
    print_warning "Commit cancelled."
    rm "$commit_file"
    return 1
  fi

  # Create commit
  local commit_options=""
  local run_checks=$(get_config "run_local_checks" "true")
  if [[ "$run_checks" == "false" ]]; then
    commit_options="--no-verify"
    print_warning "Skipping pre-commit hooks (--no-verify)"
  fi

  git commit $commit_options -F "$commit_file"
  local commit_status=$?

  rm "$commit_file"

  if [[ $commit_status -eq 0 ]]; then
    print_success "Changes committed successfully!"
  else
    print_error "Commit failed. Please check the errors above."
    return 1
  fi
}

# Push changes and create PR
push_and_create_pr() {
  local branch=$(get_cache "current_branch")

  if [[ -z "$branch" ]]; then
    print_error "No branch information found."
    return 1
  fi

  local ticket_json=$(get_cache "selected_ticket.json")
  local ticket_key=$(echo "$ticket_json" | jq -r ".key")
  local ticket_title=$(echo "$ticket_json" | jq -r ".title")
  local ticket_desc=$(echo "$ticket_json" | jq -r ".description")

  # Push changes
  print_info "Pushing changes to origin/$branch..."
  git push -u origin "$branch"

  if [[ $? -ne 0 ]]; then
    print_error "Failed to push changes."
    return 1
  fi

  # Create PR
  print_info "Creating PR..."

  # Format PR title and body
  local pr_title="$ticket_key: $ticket_title"
  local max_length=$(get_config "max_line_length" "100")
  local formatted_desc=$(format_text "$ticket_desc" "$max_length")
  local pr_body="$formatted_desc

Fixes: $ticket_key"

  # Create PR using GitHub CLI if available
  if command_exists gh; then
    print_info "Using GitHub CLI to create PR..."

    # Create temporary PR file
    local pr_file=$(mktemp)
    echo "$pr_body" > "$pr_file"

    gh pr create --title "$pr_title" --body-file "$pr_file"
    local pr_status=$?

    rm "$pr_file"

    if [[ $pr_status -eq 0 ]]; then
      print_success "PR created successfully!"
      print_warning "Pre-submit jobs should take approximately 27 minutes."
    else
      print_error "Failed to create PR using GitHub CLI."
      print_warning "Please create the PR manually."
      return 1
    fi
  else
    print_warning "GitHub CLI (gh) not found. Please create the PR manually."
    print_info "PR Title: $pr_title"
    print_info "PR Body:"
    echo "$pr_body"

    # If user has GitHub repo configured, provide URL
    local repo=$(get_config "github_repo" "")
    if [[ -n "$repo" ]]; then
      print_info "Create PR at: https://github.com/$repo/pull/new/$branch"
    fi
  fi
}

# Main GitHub/Git tool workflow
github_main() {
  # Ensure config exists
  if [[ ! -f "$CONFIG_FILE" ]] || [[ -z "$(get_config "github_repo" "")" ]]; then
    setup_github_config
  fi

  print_success "=== GitHub Tool ==="

  PS3="Select GitHub action: "
  options=("Create branch" "View changes" "Commit changes" "Push and create PR" "Setup configuration" "Exit")
  select opt in "${options[@]}"
  do
    case $opt in
      "Create branch")
        create_branch
        ;;
      "View changes")
        git status
        ;;
      "Commit changes")
        create_commit
        ;;
      "Push and create PR")
        push_and_create_pr
        ;;
      "Setup configuration")
        setup_github_config
        ;;
      "Exit")
        print_success "Exiting GitHub tool"
        break
        ;;
      *)
        print_error "Invalid option $REPLY"
        ;;
    esac
  done
}

# If script is executed directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  github_main
fi
