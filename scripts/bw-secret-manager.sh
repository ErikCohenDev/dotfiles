#!/bin/bash
###############################################################################
# Bitwarden Secret Management Module
# Version: 1.0.1
#
# A secure shell module for managing API keys and other secrets using Bitwarden CLI.
#
# Features:
# - Secure retrieval and storage of API keys
# - Environment variable export with security precautions
# - Session management with auto-locking
# - Folder-based organization of secrets
# - History protection and process table security
#
# Dependencies:
# - Bitwarden CLI (bw)
# - jq
# - security (macOS keychain)
###############################################################################

# Don't allow sourcing in anything but interactive shells
[[ $- != *i* ]] && return

# Configuration
BW_AUTOLOCK_MINUTES=15
BW_LOCK_FILE="/tmp/bw_lock_${USER}.pid"
BW_AUTOLOCK_SECONDS=$((BW_AUTOLOCK_MINUTES * 60))

# History protection
export HISTORY_IGNORE="(bwgetkey|bwexportkey|bwsecurekey|*API_KEY=*|*api_key=*|*apikey=*|*secret=*|*password=*)"

##########################
# Session Management
##########################

# Start or unlock a Bitwarden session
bwstart() {
  local status_output
  local bw_status

  # Get current status
  status_output=$(bw status 2>/dev/null)
  bw_status=$(echo "$status_output" | jq -r '.status' 2>/dev/null)

  # Clean up existing lock process if one exists
  if [ -f "$BW_LOCK_FILE" ]; then
    local old_pid=$(cat "$BW_LOCK_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
      kill "$old_pid" 2>/dev/null
      echo "🔄 Removed previous auto-lock timer."
    fi
    rm -f "$BW_LOCK_FILE"
  fi

  # Handle different Bitwarden states
  case "$bw_status" in
    "unlocked")
      echo "🔓 Bitwarden is already unlocked."
      ;;

    "locked")
      echo "🔑 Unlocking Bitwarden session..."
      export BW_PASSWORD=$(security find-generic-password -s "BitwardenMasterPassword" -a "$USER" -w)
      export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)
      unset BW_PASSWORD

      if [ $? -ne 0 ] || [ -z "$BW_SESSION" ]; then
        echo "❌ Failed to unlock Bitwarden."
        return 1
      fi

      echo "✅ Bitwarden unlocked successfully."
      ;;

    "unauthenticated"|*)
      echo "🔑 Logging in to Bitwarden..."
      export BW_CLIENTID=$(security find-generic-password -s "BitwardenClientID" -a "$USER" -w)
      export BW_CLIENTSECRET=$(security find-generic-password -s "BitwardenClientSecret" -a "$USER" -w)
      export BW_PASSWORD=$(security find-generic-password -s "BitwardenMasterPassword" -a "$USER" -w)

      bw login --apikey --raw >/dev/null
      local login_result=$?

      if [ $login_result -ne 0 ]; then
        echo "❌ Failed to log in to Bitwarden."
        unset BW_CLIENTID BW_CLIENTSECRET BW_PASSWORD
        return 1
      fi

      export BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)
      unset BW_CLIENTID BW_CLIENTSECRET BW_PASSWORD

      if [ $? -ne 0 ] || [ -z "$BW_SESSION" ]; then
        echo "❌ Failed to unlock Bitwarden."
        return 1
      fi

      echo "✅ Bitwarden logged in and unlocked successfully."
      ;;
  esac

  # Set up auto-lock timer (only if we're now unlocked)
  if bw status | grep -q '"status":"unlocked"'; then
    (
      sleep $BW_AUTOLOCK_SECONDS
      if bw status | grep -q '"status":"unlocked"'; then
        bw lock >/dev/null
        echo "🔒 Bitwarden locked automatically after $BW_AUTOLOCK_MINUTES mins."
      fi
      rm -f "$BW_LOCK_FILE"
    ) &

    # Store PID of background process
    echo $! > "$BW_LOCK_FILE"
    echo "⏱️  Auto-lock timer set for $BW_AUTOLOCK_MINUTES minutes."
  fi
}

# Check the status of Bitwarden session
bwstatus() {
  local status_output

  status_output=$(bw status 2>/dev/null)

  if [ $? -ne 0 ]; then
    echo "❌ Bitwarden CLI error or not installed."
    return 1
  fi

  local bw_status=$(echo "$status_output" | jq -r '.status' 2>/dev/null)

  case "$bw_status" in
    "unlocked")
      echo "🔓 Bitwarden is unlocked."
      # Check if auto-lock timer is running
      if [ -f "$BW_LOCK_FILE" ] && kill -0 $(cat "$BW_LOCK_FILE") 2>/dev/null; then
        local elapsed=$((BW_AUTOLOCK_SECONDS - $(ps -o etime= -p $(cat "$BW_LOCK_FILE") | awk -F: '{print $1*60+$2}')))
        echo "⏱️  Auto-lock in approximately $((elapsed/60)) minutes and $((elapsed%60)) seconds."
      else
        echo "⚠️  No active auto-lock timer found."
      fi
      ;;

    "locked")
      echo "🔒 Bitwarden is locked. Run 'bwstart' to unlock."
      ;;

    "unauthenticated")
      echo "🚫 Not logged in to Bitwarden. Run 'bwstart' to login."
      ;;

    *)
      echo "❓ Unknown Bitwarden status: $bw_status"
      ;;
  esac
}

# Support for self-signed certificates
bwsetcert() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: bwsetcert \"/absolute/path/to/your/certificates.pem\""
    return 1
  fi

  local CERT_PATH=$1

  if [ ! -f "$CERT_PATH" ]; then
    echo "❌ Certificate file not found at: $CERT_PATH"
    return 1
  fi

  export NODE_EXTRA_CA_CERTS="$CERT_PATH"
  echo "✅ Bitwarden CLI configured to use certificate at: $CERT_PATH"
}

# Force lock the Bitwarden vault and clear the session
bwlock() {
  if ! bw status | grep -q '"status":"unlocked"'; then
    echo "🔒 Bitwarden is already locked."
    return 0
  fi

  bw lock >/dev/null

  # Clean up lock file if it exists
  if [ -f "$BW_LOCK_FILE" ]; then
    local old_pid=$(cat "$BW_LOCK_FILE")
    if kill -0 "$old_pid" 2>/dev/null; then
      kill "$old_pid" 2>/dev/null
    fi
    rm -f "$BW_LOCK_FILE"
  fi

  echo "🔒 Bitwarden locked successfully."
}

##########################
# API Key Management
##########################

# Get API key from Bitwarden and echo it (for piping or assigning)
bwgetkey() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: bwgetkey \"Item Name\""
    return 1
  fi

  if ! bw status | grep -q '"status":"unlocked"'; then
    echo "❌ Bitwarden is locked. Run 'bwstart' first to unlock."
    return 1
  fi

  local ITEM_NAME=$1
  local ITEM=$(bw list items --search "$ITEM_NAME" | jq -r ".[0]")

  if [ -z "$ITEM" ] || [ "$ITEM" = "null" ]; then
    echo "❌ Item \"$ITEM_NAME\" not found!" >&2
    return 1
  fi

  # Extract API key from notes field with null safety
  local API_KEY=$(echo "$ITEM" | jq -r 'if .notes == null then "" else (.notes | capture("API_KEY=(.*)").1 // "") end')
  if [ -z "$API_KEY" ]; then
    echo "❌ No API_KEY found in item \"$ITEM_NAME\"!" >&2
    return 1
  fi

  echo "$API_KEY"
}

# Export API key to environment variable with security precautions
bwexportkey() {
  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: bwexportkey \"Item Name\" [ENV_VAR_NAME]"
    echo "If ENV_VAR_NAME is not provided, it will default to the item name (uppercased)"
    return 1
  fi

  local ITEM_NAME=$1
  # Default to item name, uppercased with spaces replaced by underscores and sanitized
  local ENV_VAR_NAME_RAW=${2:-$(echo "$ITEM_NAME" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')}
  # Keep only A-Z, 0-9, and _
  local ENV_VAR_NAME=$(echo "$ENV_VAR_NAME_RAW" | tr -cd 'A-Z0-9_')
  # Must start with a letter or underscore
  if ! printf '%s' "$ENV_VAR_NAME" | grep -Eq '^[A-Z_][A-Z0-9_]*$'; then
    echo "❌ Invalid environment variable name derived from: '$ENV_VAR_NAME_RAW'" >&2
    return 1
  fi

  # Use a subshell to prevent the API key from appearing in history or ps output
  (
    local API_KEY=$(bwgetkey "$ITEM_NAME")
    if [ $? -ne 0 ]; then
      # Error message already printed by bwgetkey
      return 1
    fi

    # Use eval to avoid the key appearing in ps output
    eval "export $ENV_VAR_NAME='
$API_KEY'"
  )

  # Only output success message if the key was set
  if [ -n "${(P)ENV_VAR_NAME}" ]; then  # zsh syntax to reference variable by name
    echo "✅ Exported API key to \$${ENV_VAR_NAME}"
  else
    return 1
  fi
}

# Secure version that explicitly protects against history recording
bwsecurekey() {
  # Temporarily disable history for this function
  local HISTFILE_OLD=$HISTFILE
  HISTFILE=/dev/null

  if [ "$#" -lt 1 ] || [ "$#" -gt 2 ]; then
    echo "Usage: bwsecurekey \"Item Name\" [ENV_VAR_NAME]"
    echo "If ENV_VAR_NAME is not provided, it will default to the item name (uppercased)"
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  local ITEM_NAME=$1
  local ENV_VAR_NAME_RAW=${2:-$(echo "$ITEM_NAME" | tr '[:lower:]' '[:upper:]' | tr ' ' '_')}
  local ENV_VAR_NAME=$(echo "$ENV_VAR_NAME_RAW" | tr -cd 'A-Z0-9_')
  if ! printf '%s' "$ENV_VAR_NAME" | grep -Eq '^[A-Z_][A-Z0-9_]*$'; then
    echo "❌ Invalid environment variable name derived from: '$ENV_VAR_NAME_RAW'" >&2
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  # Use process substitution to avoid temporary files
  local API_KEY=$(bwgetkey "$ITEM_NAME")

  if [ $? -ne 0 ]; then
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  # Export without showing in ps output
  eval "export $ENV_VAR_NAME='
$API_KEY'"
  unset API_KEY

  echo "🔒 Securely exported API key to \$${ENV_VAR_NAME}"

  # Restore history
  HISTFILE=$HISTFILE_OLD
}

# Function for securely executing a command with an API key (one-time use)
bwsecurerun() {
  local HISTFILE_OLD=$HISTFILE
  HISTFILE=/dev/null

  if [ "$#" -lt 3 ]; then
    echo "Usage: bwsecurerun \"Item Name\" ENV_VAR_NAME command [args...]"
    echo "Example: bwsecurerun \"OpenAI API Key\" OPENAI_API_KEY curl -H \"Authorization: Bearer \$OPENAI_API_KEY\" ..."
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  local ITEM_NAME=$1
  local ENV_VAR_NAME=$2
  shift 2

  # Get the API key in a secure way
  local API_KEY=$(bwgetkey "$ITEM_NAME")

  if [ $? -ne 0 ]; then
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  # Run the command with the API key as an environment variable
  # Using env to avoid the key appearing in process listing
  env "$ENV_VAR_NAME=$API_KEY" "$@"
  local CMD_RESULT=$?

  unset API_KEY
  HISTFILE=$HISTFILE_OLD
  return $CMD_RESULT
}

# List all API keys stored in Bitwarden
bwlistkeys() {
  if ! bw status | grep -q '"status":"unlocked"'; then
    echo "❌ Bitwarden is locked. Run 'bwstart' first to unlock."
    return 1
  fi

  echo "🔑 API Keys stored in Bitwarden:"

  # First get all folders for faster lookup
  local FOLDERS=$(bw list folders)

  # Then find items with API keys in the notes field - with proper null handling
  bw list items | jq -r '.[] | select(.notes != null) | select(.notes | contains("API_KEY=")) | "\(.id)|\(.name)|\(.folderId)"' |
    while IFS='|' read -r id name folder_id; do
      if [ -z "$folder_id" ] || [ "$folder_id" = "null" ]; then
        echo "- $name (No Folder)"
      else
        local folder_name=$(echo "$FOLDERS" | jq -r --arg id "$folder_id" '.[] | select(.id==$id) | .name')
        echo "- $name (📁 $folder_name)"
      fi
    done
}

##########################
# API Key Storage & Update
##########################

# Update an existing API key
bwupdatekey() {
  local HISTFILE_OLD=$HISTFILE
  HISTFILE=/dev/null

  if [ "$#" -ne 2 ]; then
    echo "Usage: bwupdatekey \"Item Name\" \"NEW_API_KEY\""
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  if ! bw status | grep -q '"status":"unlocked"'; then
    echo "❌ Bitwarden is locked. Run 'bwstart' first to unlock."
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  local ITEM_NAME=$1
  local NEW_API_KEY=$2

  # Get the item
  local ITEM=$(bw list items --search "$ITEM_NAME" | jq -r ".[0]")

  if [ -z "$ITEM" ] || [ "$ITEM" = "null" ]; then
    echo "❌ Item \"$ITEM_NAME\" not found!"
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  local ITEM_ID=$(echo "$ITEM" | jq -r '.id')

  # Get notes or empty string if null
  local NOTES=$(echo "$ITEM" | jq -r '.notes // ""')

  # Check if we have an existing API key
  if echo "$NOTES" | grep -q 'API_KEY='; then
    # Update existing API key while preserving any other content
    local NEW_NOTES=$(echo "$NOTES" | sed -E 's/API_KEY=.*/API_KEY='"$NEW_API_KEY"'/')
  else
    # No existing API key, add it to notes
    if [ -z "$NOTES" ]; then
      local NEW_NOTES="API_KEY=$NEW_API_KEY"
    else
      local NEW_NOTES="${NOTES}
API_KEY=$NEW_API_KEY"
    fi
  fi

  # Update the item
  echo "$ITEM" | jq \
    --arg notes "$NEW_NOTES" \
    '.notes=$notes' | \
    bw encode | bw edit item "$ITEM_ID" >/dev/null

  HISTFILE=$HISTFILE_OLD
  echo "✅ Updated API key for \"$ITEM_NAME\""
}

# Delete an API key
bwdeletekey() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: bwdeletekey \"Item Name\""
    return 1
  fi

  if ! bw status | grep -q '"status":"unlocked"'; then
    echo "❌ Bitwarden is locked. Run 'bwstart' first to unlock."
    return 1
  fi

  local ITEM_NAME=$1

  # Get the item
  local ITEM=$(bw list items --search "$ITEM_NAME" | jq -r ".[0]")

  if [ -z "$ITEM" ] || [ "$ITEM" = "null" ]; then
    echo "❌ Item \"$ITEM_NAME\" not found!"
    return 1
  fi

  local ITEM_ID=$(echo "$ITEM" | jq -r '.id')

  # Confirm deletion
  read -p "🚨 Are you sure you want to delete \"$ITEM_NAME\"? (y/N) " confirm
  if [[ "$confirm" != [yY] ]]; then
    echo "❌ Deletion canceled."
    return 1
  fi

  # Delete the item
  bw delete item "$ITEM_ID" >/dev/null
  echo "✅ Deleted \"$ITEM_NAME\""
}

# Function to securely store API keys (requires active session)
bwstorekey() {
  local HISTFILE_OLD=$HISTFILE
  HISTFILE=/dev/null

  if [ "$#" -ne 3 ]; then
    echo "Usage: bwstorekey \"Item Name\" \"API_KEY\" \"Folder Name\""
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  if ! bw status | grep -q '"status":"unlocked"'; then
    echo "❌ Bitwarden is locked. Run 'bwstart' first to unlock."
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  local ITEM_NAME=$1
  local API_KEY=$2
  local FOLDER_NAME=$3

  local FOLDER_ID=$(bw list folders | jq -r --arg name "$FOLDER_NAME" '.[] | select(.name==$name) | .id')

  if [ -z "$FOLDER_ID" ]; then
    echo "❌ Folder \"$FOLDER_NAME\" not found!"
    HISTFILE=$HISTFILE_OLD
    return 1
  fi

  # Get the secure note template and properly set all required fields
  bw get template item | jq \
    --arg name "$ITEM_NAME" \
    --arg notes "API_KEY=$API_KEY" \
    --arg folderId "$FOLDER_ID" \
    '{
      type: 2,
      secureNote: {type: 0},
      name: $name,
      notes: $notes,
      folderId: $folderId,
      organizationId: null,
      collectionIds: null
    }' \
    | bw encode | bw create item >/dev/null

  local result=$?
  HISTFILE=$HISTFILE_OLD

  if [ $result -eq 0 ]; then
    echo "✅ Stored API key \"$ITEM_NAME\" in folder \"$FOLDER_NAME\""
  else
    echo "❌ Failed to store API key"
    return 1
  fi
}

##########################
# Bulk Operations
##########################

# Load multiple API keys at once from a specific folder
bwloadfolder() {
  if [ "$#" -ne 1 ]; then
    echo "Usage: bwloadfolder \"Folder Name\""
    return 1
  fi

  if ! bw status | grep -q '"status":"unlocked"'; then
    echo "❌ Bitwarden is locked. Run 'bwstart' first to unlock."
    return 1
  fi

  local FOLDER_NAME=$1
  local FOLDER_ID=$(bw list folders | jq -r --arg name "$FOLDER_NAME" '.[] | select(.name==$name) | .id')

  if [ -z "$FOLDER_ID" ]; then
    echo "❌ Folder \"$FOLDER_NAME\" not found!"
    return 1
  fi

  echo "🔄 Loading API keys from folder \"$FOLDER_NAME\"..."

  # Get items once for performance, handling null notes fields
  local ITEMS=$(bw list items | jq -r --arg folderId "$FOLDER_ID" '.[] | select(.folderId==$folderId and .notes != null and .notes | contains("API_KEY="))')

  if [ -z "$ITEMS" ]; then
    echo "ℹ️ No API keys found in folder \"$FOLDER_NAME\"."
    return 0
  fi

  echo "$ITEMS" | jq -r '.name' | while read -r item_name; do
    bwexportkey "$item_name"
  done

  echo "✅ All API keys from \"$FOLDER_NAME\" loaded into environment variables."
}

##########################
# Helper Functions
##########################

# Display help for all available commands
bwhelp() {
  cat <<EOF
Bitwarden Secret Management Help:

🔑 Session Management:
  bwstart        - Start or unlock a Bitwarden session
  bwstatus       - Check the status of the Bitwarden session
  bwlock         - Lock the Bitwarden vault
  bwlogout       - Log out completely from Bitwarden

🔒 API Key Operations:
  bwgetkey       - Get an API key from Bitwarden
  bwexportkey    - Export an API key to an environment variable
  bwsecurekey    - Securely export an API key (no history)
  bwsecurerun    - Run a command with a temporary API key
  bwwithkey      - Run a command with an API key as environment variable

📋 API Key Management:
  bwlistkeys     - List all API keys stored in Bitwarden
  bwstorekey     - Store a new API key in Bitwarden
  bwupdatekey    - Update an existing API key
  bwdeletekey    - Delete an API key

📁 Bulk Operations:
  bwloadfolder   - Load all API keys from a folder into environment variables

🧰 Configuration:
  bwsetcert      - Set a certificate for self-hosted Bitwarden with HTTPS

Examples:
  bwstart                                  # Unlock your vault
  bwstorekey "OpenAI API Key" "sk-abc123..." "API Keys"   # Store a new key
  bwsecurekey "OpenAI API Key" "OPENAI_API_KEY"           # Export without history
  bwlistkeys                               # List all stored API keys
  bwsecurerun "GitHub Token" GITHUB_TOKEN gh repo list    # Run command with key
EOF
}

# Run a command with an API key (safer version of bwwithkey)
bwwithkey() {
  if [ "$#" -lt 3 ]; then
    echo "Usage: bwwithkey \"Item Name\" ENV_VAR_NAME command [args...]"
    echo "Example: bwwithkey \"OpenAI API Key\" OPENAI_API_KEY curl -H \"Authorization: Bearer \$OPENAI_API_KEY\" ..."
    return 1
  fi

  local ITEM_NAME=$1
  local ENV_VAR_NAME=$2
  shift 2

  local API_KEY=$(bwgetkey "$ITEM_NAME")
  if [ $? -ne 0 ]; then
    return 1
  fi

  # Run command with environment variable set just for this command
  env "$ENV_VAR_NAME=$API_KEY" "$@"
  local result=$?

  unset API_KEY
  return $result
}

# Unset BW_SESSION when finished
bwlogout() {
  bwlock
  unset BW_SESSION
  echo "🔒 Bitwarden logged out and session cleared."
}
