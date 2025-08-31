#!/bin/bash
#
# History Manager - Prevent leaks of sensitive information in shell history
# Version: 2.0 - Safer implementation that preserves history

##########################
# History Configuration
##########################

# DON'T override ZSH's history settings - only augment them
# Let Oh My Zsh manage the history file and sizes

# Define sensitive patterns for history exclusion
_SENSITIVE_PATTERNS=(
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

# SAFER pattern handling that won't break history
# Add our patterns to ZSH's HISTORY_IGNORE without overriding it
_add_history_ignore_patterns() {
  # Create a proper ZSH pattern string with | as separator
  local patterns_str
  patterns_str=$(printf "|%s" "${_SENSITIVE_PATTERNS[@]}")
  patterns_str=${patterns_str:1}  # Remove leading |

  # Only set if ZSH is active (avoid errors in other shells)
  if [[ -n "$ZSH_VERSION" ]]; then
    # Append to existing patterns if any
    if [[ -z "$HISTORY_IGNORE" ]]; then
      export HISTORY_IGNORE="($patterns_str)"
    else
      # Only add if not already there (prevent duplication)
      if [[ "$HISTORY_IGNORE" != *"$patterns_str"* ]]; then
        export HISTORY_IGNORE="${HISTORY_IGNORE%)}|$patterns_str)"
      fi
    fi

    # Let ZSH know something changed
    fc -R
  fi
}

# Apply the patterns safely
_add_history_ignore_patterns

##########################
# History Management Functions
##########################

# Clean sensitive information from history - safe implementation
_glob_to_regex() {
  # Convert a minimal glob pattern to regex: escape regex metachars, then * -> .*
  # Handles characters: [](){}.^$+?|\
  local s="$1"
  s=$(printf '%s' "$s" | sed -E 's/([][(){}.^$+?|\\])/\\\\\1/g')
  s=$(printf '%s' "$s" | sed 's/\*/.*/g')
  echo "$s"
}

histclean() {
  echo "🧹 Cleaning shell history of sensitive patterns..."

  # Safety checks
  if [[ ! -f "$HISTFILE" ]]; then
    echo "❌ History file not found: $HISTFILE"
    return 1
  fi

  local BACKUP_FILE="$HISTFILE.bak.$(date +%Y%m%d-%H%M%S)"
  cp "$HISTFILE" "$BACKUP_FILE"

  # Build the grep pattern safely
  local GREP_PATTERN=""
  for pattern in "${_SENSITIVE_PATTERNS[@]}"; do
    local regex_pattern=$(_glob_to_regex "$pattern")
    if [[ -z "$GREP_PATTERN" ]]; then
      GREP_PATTERN="$regex_pattern"
    else
      GREP_PATTERN="$GREP_PATTERN|$regex_pattern"
    fi
  done

  # Use temporary file for safe processing
  local TEMP_FILE=$(mktemp)
  grep -v -E "$GREP_PATTERN" "$BACKUP_FILE" > "$TEMP_FILE" 2>/dev/null

  # Only replace if grep was successful and file is not empty
  if [[ $? -eq 0 && -s "$TEMP_FILE" ]]; then
    cp "$TEMP_FILE" "$HISTFILE"
    rm "$TEMP_FILE"

    # Reload history without clearing current session
    fc -R "$HISTFILE"

    echo "✅ History cleaned! Backup saved at $BACKUP_FILE"
  else
    rm "$TEMP_FILE"
    echo "⚠️ Error in pattern matching or empty result. History unchanged."
    echo "   Your backup is at $BACKUP_FILE"
  fi
}

# Audit history without modifying it
histaudit() {
  echo "🔍 Auditing history for potentially sensitive information..."

  # Safety check
  if [[ ! -f "$HISTFILE" ]]; then
    echo "❌ History file not found: $HISTFILE"
    return 1
  fi

  # Build the grep pattern safely
  local GREP_PATTERN=""
  for pattern in "${_SENSITIVE_PATTERNS[@]}"; do
    local regex_pattern=$(_glob_to_regex "$pattern")
    if [[ -z "$GREP_PATTERN" ]]; then
      GREP_PATTERN="$regex_pattern"
    else
      GREP_PATTERN="$GREP_PATTERN|$regex_pattern"
    fi
  done

  local count=$(grep -E "$GREP_PATTERN" "$HISTFILE" 2>/dev/null | wc -l)

  if [[ $count -gt 0 ]]; then
    echo "⚠️ Found $count potentially sensitive entries in history."
    echo "To see them, run: grep -E \"$GREP_PATTERN\" \"$HISTFILE\""
    echo "To clean them, run: histclean"
  else
    echo "✅ No sensitive patterns found in history."
  fi
}

# Run a command privately (without recording in history)
private() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: private <command>"
    echo "Runs a command without recording it in history"
    return 1
  fi

  # Save current history file
  local OLD_HISTFILE="$HISTFILE"
  # Temporarily disable history
  HISTFILE=/dev/null

  echo "🔒 Running command privately: $@"
  eval "$@"
  local result=$?

  # Restore history file
  HISTFILE="$OLD_HISTFILE"

  echo "✅ Command completed with status: $result"
  return $result
}

# Reset history (with confirmation) - EXPLICIT USER ACTION ONLY
histreset() {
  echo "⚠️ WARNING: This will PERMANENTLY DELETE your command history!"
  echo "    Your current history will be backed up first."
  read -p "Are you SURE you want to continue? (type 'yes' to confirm): " confirm

  if [[ "$confirm" != "yes" ]]; then
    echo "🛑 Operation canceled."
    return 1
  fi

  local BACKUP_FILE="$HISTFILE.RESET.$(date +%Y%m%d-%H%M%S)"

  if [[ -f "$HISTFILE" ]]; then
    cp "$HISTFILE" "$BACKUP_FILE"
    echo "📁 History backed up to: $BACKUP_FILE"

    # Clear history file
    echo -n > "$HISTFILE"

    # Clear current session history if in ZSH
    if [[ -n "$ZSH_VERSION" ]]; then
      history -c
      fc -R
    fi

    echo "✅ History has been reset."
  else
    echo "❌ History file not found: $HISTFILE"
    return 1
  fi
}

# Show help for history management
histhelp() {
  cat <<EOF
🔒 History Protection Tool

Commands:
  histaudit      - Check history for sensitive information
  histclean      - Safely remove sensitive entries from history
  private <cmd>  - Run a command without recording it in history
  histreset      - Delete all history (requires confirmation)
  histhelp       - Show this help message

Protection status:
  ${#_SENSITIVE_PATTERNS[@]} patterns are currently being blocked from history
EOF
}

# Only show a simple message on load, don't disrupt terminal startup
echo "🔒 History protection active (${#_SENSITIVE_PATTERNS[@]} patterns blocked)"
