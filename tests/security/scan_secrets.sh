#!/usr/bin/env bash
set -Eeo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

echo "[Secret Scan] Checking for common secret patterns in tracked files..." >&2

cd "$ROOT_DIR"

# Grep patterns (broad, but exclude known safe helper scripts)
PATTERNS='API_KEY|SECRET_KEY|AWS_SECRET|PASS(WORD)?=|TOKEN=|xox[baprs]-|ghp_[A-Za-z0-9]{30,}|sk-[A-Za-z0-9]'

# File path regexes to skip (examples and helper code that intentionally mentions patterns)
SKIP_RE='^(README\.md|docs/|scripts/bw-secret-manager\.sh|scripts/history-manager\.sh|scripts/llm-tools\.sh)'

FAILED=0

while IFS= read -r file; do
  # Skip known doc/example and helper files
  if printf "%s" "$file" | grep -Eq "$SKIP_RE"; then
    continue
  fi
  # Skip missing files (race conditions) and binary / large files heuristically
  if [[ ! -f "$file" ]]; then
    continue
  fi
  # Skip binary / large files heuristically
  if file "$file" | grep -qiE 'binary|image|audio'; then
    continue
  fi
  if grep -qE "$PATTERNS" "$file"; then
    echo "⚠️  Potential secret match in: $file" >&2
    # Show lines but filter common placeholders
    grep -nE "$PATTERNS" "$file" | grep -v "sk-your-secret-key" >&2 || true
    FAILED=1
  fi
done < <(git ls-files)

if [[ $FAILED -eq 1 ]]; then
  echo "❌ Secret scan found potential issues." >&2
  exit 1
fi

echo "✅ No obvious secrets found." >&2
exit 0
