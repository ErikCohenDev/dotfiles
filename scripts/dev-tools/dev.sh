#!/usr/bin/env bash
set -Eeo pipefail

# Unified dev helper entrypoint

# Resolve script directory even when invoked via symlink (macOS-compatible)
_resolve_script_dir() {
  local src="${BASH_SOURCE[0]}"
  while [ -h "$src" ]; do
    local dir
    dir="$(cd -P "$(dirname "$src")" && pwd)"
    local target
    target="$(readlink "$src")"
    [[ $target != /* ]] && src="$dir/$target" || src="$target"
  done
  cd -P "$(dirname "$src")" && pwd
}

script_dir="$(_resolve_script_dir)"
repo_root="$(cd "$script_dir/../.." && pwd)"

source "$script_dir/core.sh"

usage() {
  cat <<EOF
Unified Dev Tool

Usage: dev <command> [args]

Commands:
  jira         Launch interactive Jira tool
  github       Launch interactive Git/GitHub tool
  workflow     Launch full integrated workflow assistant
  init         First-time guided setup
  branch       Create branch from selected ticket
  commit       Create standardized commit
  pr           Push and create PR
  tickets      Fetch Jira tickets
  select       Select a Jira ticket
  ticket       Show currently selected ticket
  verify       Run repo self-check (links, secrets scan)
  deps         Check required dependencies
  help         Show this help

Examples:
  dev tickets
  dev select
  dev branch
  dev commit
  dev pr
EOF
}

# Lazy source heavy scripts only when needed
ensure_jira() { [[ -n "$JIRA_LOADED" ]] || { source "$script_dir/jira.sh"; JIRA_LOADED=1; }; }
ensure_github() { [[ -n "$GITHUB_LOADED" ]] || { source "$script_dir/github.sh"; GITHUB_LOADED=1; }; }
ensure_workflow() { source "$script_dir/workflow.sh"; }

check_link() {
  local dest="$1" src_expected="$2"
  if [[ -L "$dest" ]]; then
    local actual
    actual="$(readlink "$dest")"
    if [[ "$actual" == "$src_expected" ]]; then
      print_success "OK: $dest → $actual"
    else
      print_warning "MISMATCH: $dest → $actual (expected $src_expected)"
    fi
  elif [[ -e "$dest" ]]; then
    print_warning "FILE EXISTS (not a symlink): $dest"
  else
    print_warning "MISSING: $dest"
  fi
}

verify() {
  print_info "Verifying dotfiles setup..."

  # Check dependencies
  check_dependencies git jq curl || true

  # Symlink checks (optional files may be skipped)
  check_link "$HOME/.zshrc" "$repo_root/home/.zshrc"
  check_link "$HOME/.gitconfig" "$repo_root/home/.gitconfig"
  check_link "$HOME/.config/nvim/init.lua" "$repo_root/config/nvim/init.lua"
  check_link "$HOME/.bw-secret-manager.sh" "$repo_root/scripts/bw-secret-manager.sh"
  check_link "$HOME/.history-manager.sh" "$repo_root/scripts/history-manager.sh"
  check_link "$HOME/bin/dev" "$repo_root/scripts/dev-tools/dev.sh"

  # Secret scan
  if [[ -x "$repo_root/tests/security/scan_secrets.sh" ]]; then
    print_info "Running secret scan..."
    if bash "$repo_root/tests/security/scan_secrets.sh"; then
      print_success "Secret scan passed."
    else
      print_error "Secret scan failed. Review findings above."
    fi
  else
    print_warning "Secret scan script not found or not executable."
  fi
}

init_configs() {
  print_info "Starting first-time configuration..."
  setup_core_config
  ensure_jira; setup_jira_config
  ensure_github; setup_github_config
  print_success "Initial configuration complete."
}

cmd=${1:-help}; shift || true

case "$cmd" in
  jira) ensure_jira; jira_main ;;
  github) ensure_github; github_main ;;
  workflow) ensure_workflow; workflow_main ;;
  branch) ensure_jira; ensure_github; create_branch ;;
  commit) ensure_github; create_commit ;;
  pr) ensure_github; push_and_create_pr ;;
  tickets) ensure_jira; get_jira_tickets ;;
  select) ensure_jira; select_ticket ;;
  ticket) ensure_jira; get_ticket_details | jq . 2>/dev/null || true ;;
  deps) check_dependencies git curl jq || exit 1 ;;
  verify) verify ;;
  init) init_configs ;;
  help|--help|-h) usage ;;
  *) print_error "Unknown command: $cmd"; usage; exit 1 ;;
esac
