#!/bin/bash
#
# History Manager - Prevent leaks of sensitive information in shell history
#
# This script provides functions to better manage shell history and prevent
# accidental leakage of API keys, tokens, and other sensitive information.

##########################
# History Configuration
##########################

# History storage settings (overrides zsh defaults if needed)
export HISTSIZE=10000                # Lines of history to keep in memory
export SAVEHIST=10000                # Lines of history to save to disk
export HISTFILE=~/.zsh_history       # History file location

# These patterns will be excluded from history (in addition to existing HISTORY_IGNORE)
SENSITIVE_PATTERNS=(
  "*key=*" "*KEY=*"
  "*token=*" "*TOKEN=*"
  "*secret=*" "*SECRET=*"
  "*password=*" "*PASSWORD=*"
  "*credential=*" "*CREDENTIAL=*"
  "bwstorekey*" "bwupdatekey*"
  "curl -u *" "curl --user *"
  "wget --password=*"
  "ssh-add *" "ssh-keygen *"
  "openssl *private*"
  "*authorization:*" "*Authorization:*"
  "*Bearer *"
)

# Combine with existing patterns if any
if [[ -z "$HISTORY_IGNORE" ]]; then
  HISTORY_IGNORE_LIST="${SENSITIVE_PATTERNS[@]}"
else
  HISTORY_IGNORE_LIST="$HISTORY_IGNORE|${SENSITIVE_PATTERNS[@]}"
fi

# Convert array to pipe-delimited string for HISTORY_IGNORE
HISTORY_IGNORE_LIST=${HISTORY_IGNORE_LIST// /|}
export HISTORY_IGNORE="($HISTORY_IGNORE_LIST)"

##########################
# History Management Functions
##########################

# Clean sensitive information from history
histclean() {
  echo "🧹 Cleaning shell history of sensitive patterns..."

  local BACKUP_FILE="$HISTFILE.bak"
  cp "$HISTFILE" "$BACKUP_FILE"

  # Build a properly escaped grep pattern
  local GREP_PATTERN=""
  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    # Escape regex metacharacters and convert shell globs to regex
    pattern=$(echo "$pattern" | sed 's/[][^$.*+?(){}|\\]/\\&/g' | sed 's/\\\*/\.\*/g')

    if [[ -z "$GREP_PATTERN" ]]; then
      GREP_PATTERN="$pattern"
    else
      GREP_PATTERN="$GREP_PATTERN|$pattern"
    fi
  done

  grep -v -E "$GREP_PATTERN" "$BACKUP_FILE" > "$HISTFILE" 2>/dev/null || cp "$BACKUP_FILE" "$HISTFILE"

  # Reload history
  fc -R "$HISTFILE"

  echo "✅ History cleaned! Backup saved at $BACKUP_FILE"
}

# Delete history entirely and start fresh
histreset() {
  local BACKUP_FILE="$HISTFILE.bak.$(date +%Y%m%d-%H%M%S)"

  echo "⚠️  Warning: This will delete your current history!"
  read -q "REPLY?Are you sure you want to continue? (y/n) "
  echo

  if [[ $REPLY =~ ^[Yy]$ ]]; then
    # Backup current history
    cp "$HISTFILE" "$BACKUP_FILE"

    # Clear history file
    echo -n > "$HISTFILE"

    # Clear current session history
    history -c

    echo "✅ History reset! Backup saved at $BACKUP_FILE"
  else
    echo "🛑 Operation canceled."
  fi
}

# Run a command without recording it in history
private() {
  # Save current HISTFILE and disable history
  local OLD_HISTFILE="$HISTFILE"
  HISTFILE=/dev/null

  echo "🔒 Running command with history disabled..."

  # Execute the command
  eval "$@"

  # Restore history settings
  HISTFILE="$OLD_HISTFILE"

  echo "✅ Command executed. Nothing was recorded in history."
}

# Check history for potentially sensitive information
histaudit() {
  echo "🔍 Auditing history for potentially sensitive information..."

  # Build a properly escaped grep pattern
  local GREP_PATTERN=""
  for pattern in "${SENSITIVE_PATTERNS[@]}"; do
    # Escape regex metacharacters and convert shell globs to regex
    pattern=$(echo "$pattern" | sed 's/[][^$.*+?(){}|\\]/\\&/g' | sed 's/\\\*/\.\*/g')

    if [[ -z "$GREP_PATTERN" ]]; then
      GREP_PATTERN="$pattern"
    else
      GREP_PATTERN="$GREP_PATTERN|$pattern"
    fi
  done

  local RESULTS=$(grep -E "$GREP_PATTERN" "$HISTFILE" 2>/dev/null || echo "")

  if [[ -n "$RESULTS" ]]; then
    echo "⚠️  Found potentially sensitive information in history:"
    echo "$RESULTS"
    echo "Consider running 'histclean' to remove these entries."
  else
    echo "✅ No obvious sensitive information found in history."
  fi
}

##########################
# Helper Functions
##########################

# Show help for history management
histhelp() {
  cat <<EOF
History Management Help:

🧹 Cleaning Functions:
  histclean      - Clean sensitive information from history
  histreset      - Delete history entirely and start fresh
  histaudit      - Check history for potentially sensitive information

🔒 Preventive Functions:
  private        - Run a command without recording it in history
                   Example: private aws configure

📋 Information:
  histhelp       - Show this help message

To use these functions, simply source this script in your .zshrc:
  source ~/.history-manager.sh
EOF
}

# Alert user that history management is enabled
echo "🔒 History protection enabled ($(echo ${#SENSITIVE_PATTERNS[@]}) patterns blocked)"