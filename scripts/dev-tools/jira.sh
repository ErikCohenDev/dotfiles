#!/usr/bin/env bash
set -Eeo pipefail
# filepath: /Users/ecohen/dotfiles/scripts/dev-tools/jira.sh

###############################################################################
# Development Tools - Jira Integration
# Version: 1.0.0
#
# Functions for interacting with Jira API
###############################################################################

# Source core utilities if not already sourced (resolve symlinks)
if [[ -z "$CORE_SOURCED" ]]; then
  _resolve_script_dir_jira() {
    local src="${BASH_SOURCE[0]}"; local dir target
    while [ -h "$src" ]; do
      dir="$(cd -P "$(dirname "$src")" && pwd)"
      target="$(readlink "$src")"
      [[ $target != /* ]] && src="$dir/$target" || src="$target"
    done
    cd -P "$(dirname "$src")" && pwd
  }
  script_dir="$(_resolve_script_dir_jira)"
  source "$script_dir/core.sh"
  CORE_SOURCED=true
fi

# Check dependencies
check_dependencies curl jq || exit 1

# Jira configuration
setup_jira_config() {
  print_info "Setting up Jira configuration..."

  read -p "Jira domain (e.g., your-company.atlassian.net): " jira_domain
  save_config "jira_domain" "$jira_domain"

  read -p "Jira email: " jira_email
  save_config "jira_email" "$jira_email"

  echo -n "Jira API token (will not echo, leave blank to keep existing / store in keychain): "
  stty -echo; read jira_token; stty echo; echo ""
  if [[ -n "$jira_token" ]]; then
    # Offer to store securely in macOS keychain instead of config file
    if command -v security >/dev/null 2>&1 && confirm "Store token in macOS keychain (recommended)?" "Y"; then
      security add-generic-password -U -a "$USER" -s "jira_api_token" -w "$jira_token" >/dev/null 2>&1 || print_warning "Could not store token in keychain. Falling back to config file." && save_config "jira_api_token" "__KEYCHAIN__"
    else
      save_config "jira_api_token" "$jira_token"
    fi
  fi

  read -p "Jira project key (e.g., PROJ): " jira_project
  save_config "jira_project" "$jira_project"

  print_success "Jira configuration saved!"
}

# Get authentication header for Jira API
get_jira_auth_header() {
  local email token stored
  email=$(get_config "jira_email" "")
  stored=$(get_config "jira_api_token" "")
  if [[ "$stored" == "__KEYCHAIN__" ]] && command -v security >/dev/null 2>&1; then
    token=$(security find-generic-password -a "$USER" -s jira_api_token -w 2>/dev/null || true)
  else
    token="$stored"
  fi

  if [[ -z "$email" || -z "$token" ]]; then
    print_error "Jira credentials not configured"
    setup_jira_config
    email=$(get_config "jira_email" "")
    token=$(get_config "jira_api_token" "")
  fi

  echo "Basic $(echo -n "$email:$token" | base64)"
}

# Get tickets from Jira in Todo column of current sprint
get_jira_tickets() {
  print_info "Fetching Jira tickets from current sprint's Todo column..."

  local domain=$(get_config "jira_domain" "")
  local project=$(get_config "jira_project" "")

  if [[ -z "$domain" || -z "$project" ]]; then
    print_error "Jira configuration incomplete"
    setup_jira_config
    domain=$(get_config "jira_domain" "")
    project=$(get_config "jira_project" "")
  fi

  # JQL query for todo tickets in current sprint
  local jql="project = $project AND sprint in openSprints() AND status = 'To Do' ORDER BY priority DESC"
  # URL encode JQL safely (macOS: use python if available)
  local encoded_jql
  if command -v python3 >/dev/null 2>&1; then
    encoded_jql=$(python3 - <<'PY'
import urllib.parse,os,sys
print(urllib.parse.quote(os.environ['JQL']))
PY
)
  else
    # Fallback minimal encoding
    encoded_jql=$(echo "$jql" | sed -E 's/ /%20/g; s/=/%3D/g; s/"/%22/g; s/'"'"'/%27/g')
  fi

  # Call Jira API
  local auth_header=$(get_jira_auth_header)
  local response=$(curl -s -X GET \
    -H "Authorization: $auth_header" \
    -H "Content-Type: application/json" \
    "https://$domain/rest/api/3/search?jql=$encoded_jql&fields=summary,description,priority,issuetype")

  # Check if response contains errors
  if echo "$response" | jq -e '.errorMessages' > /dev/null 2>&1; then
    print_error "Error fetching tickets:"
    echo "$response" | jq -r '.errorMessages[]'
    return 1
  fi

  # Parse and display tickets
  print_success "Available tickets:"
  echo "$response" | jq -r '.issues[] | "\(.key) - \(.fields.summary)"' | nl -w2 -s'. '

  # Store ticket data for later use
  save_cache "jira_tickets.json" "$response"
}

# Select a ticket to work on
select_ticket() {
  local tickets=$(get_cache "jira_tickets.json")

  if [[ -z "$tickets" ]]; then
    print_error "No ticket data available. Fetch tickets first."
    return 1
  fi

  local ticket_count=$(echo "$tickets" | jq '.issues | length')
  if [[ $ticket_count -eq 0 ]]; then
    print_warning "No tickets available in Todo column."
    return 1
  fi

  read -p "Select ticket number (or 'q' to quit): " selection

  if [[ "$selection" == "q" ]]; then
    print_warning "Operation cancelled."
    return 1
  fi

  # Validate selection
  if ! [[ "$selection" =~ ^[0-9]+$ ]] || [[ $selection -lt 1 ]] || [[ $selection -gt $ticket_count ]]; then
    print_error "Invalid selection. Please choose a number between 1 and $ticket_count."
    return 1
  fi

  # Adjust for zero-based indexing
  local index=$((selection - 1))

  # Extract ticket information
  local ticket_key=$(echo "$tickets" | jq -r ".issues[$index].key")
  local ticket_title=$(echo "$tickets" | jq -r ".issues[$index].fields.summary")
  local ticket_desc=$(echo "$tickets" | jq -r ".issues[$index].fields.description.content[0].content[0].text // \"No description provided.\"" 2>/dev/null || echo "No description provided.")

  print_success "Selected ticket: $ticket_key - $ticket_title"
  print_info "Description: $ticket_desc"

  # Store selected ticket info
  local ticket_json=$(cat << EOF
{
  "key": "$ticket_key",
  "title": "$ticket_title",
  "description": "$ticket_desc"
}
EOF
)
  save_cache "selected_ticket.json" "$ticket_json"
  return 0
}

# Get ticket details
get_ticket_details() {
  local ticket_json=$(get_cache "selected_ticket.json")

  if [[ -z "$ticket_json" ]]; then
    print_error "No ticket selected."
    return 1
  fi

  echo "$ticket_json"
}

# Get comments for a ticket
get_ticket_comments() {
  local ticket_json=$(get_cache "selected_ticket.json")

  if [[ -z "$ticket_json" ]]; then
    print_error "No ticket selected."
    return 1
  fi

  local ticket_key=$(echo "$ticket_json" | jq -r ".key")
  local domain=$(get_config "jira_domain" "")

  print_info "Fetching comments for ticket $ticket_key..."

  local auth_header=$(get_jira_auth_header)
  local response=$(curl -s -X GET \
    -H "Authorization: $auth_header" \
    -H "Content-Type: application/json" \
    "https://$domain/rest/api/3/issue/$ticket_key/comment")

  # Check if response contains errors
  if echo "$response" | jq -e '.errorMessages' > /dev/null 2>&1; then
    print_error "Error fetching comments:"
    echo "$response" | jq -r '.errorMessages[]'
    return 1
  fi

  # Parse and display comments
  local comments_count=$(echo "$response" | jq '.comments | length')

  if [[ $comments_count -eq 0 ]]; then
    print_info "No comments found for this ticket."
    return 0
  fi

  print_success "Comments for $ticket_key:"
  echo "$response" | jq -r '.comments[] | "--- \(.author.displayName) on \(.created | sub("T"; " ") | sub("\\..*$"; "")) ---\n\(.body.content[0].content[0].text)\n"'

  # Store comments for later use
  save_cache "ticket_comments.json" "$response"
}

# Add command implementations as needed
jira_main() {
  # Ensure config exists
  if [[ ! -f "$CONFIG_FILE" ]] || [[ -z "$(get_config "jira_domain" "")" ]]; then
    setup_jira_config
  fi

  print_success "=== Jira Tool ==="

  PS3="Select Jira action: "
  options=("View tickets" "Select ticket" "View selected ticket" "Get ticket comments" "Setup configuration" "Exit")
  select opt in "${options[@]}"
  do
    case $opt in
      "View tickets")
        get_jira_tickets
        ;;
      "Select ticket")
        get_jira_tickets
        select_ticket
        ;;
      "View selected ticket")
        ticket=$(get_ticket_details)
        if [[ $? -eq 0 ]]; then
          echo "$ticket" | jq .
        fi
        ;;
      "Get ticket comments")
        get_ticket_comments
        ;;
      "Setup configuration")
        setup_jira_config
        ;;
      "Exit")
        print_success "Exiting Jira tool"
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
  jira_main
fi
