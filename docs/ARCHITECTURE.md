# Architecture

This repo is a small set of composable shell scripts and configs with explicit security boundaries. It favors readable Bash, minimal dependencies, and macOS‑native facilities.

## Components

- install.sh: idempotent linker with backups; minimal by default.
- scripts/bw-secret-manager.sh: interactive Bitwarden helpers (only sourced in interactive shells) for secure API key use.
- scripts/history-manager.sh: adds safe ZSH history ignore patterns + utilities (`histaudit`, `histclean`, `private`).
- scripts/dev-tools/
  - core.sh: shared utilities (logging with redaction, config/cache/confirm helpers).
  - jira.sh: Jira fetch/select ticket (Keychain token option), stores selection in cache.
  - github.sh: branch naming, standardized commits, PR creation via `gh` if available.
  - dev.sh: unified CLI wrapper (`dev tickets|select|branch|commit|pr|workflow`).
  - workflow.sh: legacy integrated menu (optional).
- config/nvim/init.lua: minimal Neovim config.
- tests/security/scan_secrets.sh: heuristic scanner to keep repo clean.
- home/.zshrc, home/.gitconfig: minimal, source local overrides.

## Data & Files

- Config: `$HOME/.config/dev-tools/config.json` (600). Keys like `editor`, `max_line_length`, `jira_*`, `github_repo`.
- Cache: `$HOME/.cache/dev-tools/` ephemeral state (e.g., `selected_ticket.json`, `current_branch`).
- Logs: `$HOME/.config/dev-tools/dev-tools.log` (600) with best‑effort redaction of obvious key patterns.

## Security Boundaries

- Secrets: never stored in Git; fetched at runtime from Bitwarden; Jira token optionally in macOS Keychain.
- History: sensitive patterns added to ZSH `HISTORY_IGNORE`; `private` function for one‑off execution.
- Environment: ephemeral exports via subshells/`env` to reduce exposure in process listings.
- Permissions: config/logs chmod 600; installer uses backups; symlinks preferred for single source of truth.

## External Dependencies

- Core: `bash`, `git`.
- Utilities: `jq`, `curl` (Jira), `gh` (optional PRs), `bw` (Bitwarden).
- macOS: `security` keychain commands.

## Key Flows (Text Diagrams)

1) Ticket → Branch → Commit → PR

   Jira (curl+jq) → select_ticket → cache:selected_ticket.json
   ↓
   github.create_branch uses ticket key + title → git checkout -b <prefix/key-title>
   ↓
   github.create_commit opens editor, formats body, commits (optionally --no-verify)
   ↓
   github.push_and_create_pr → `git push` → `gh pr create` (fallback: echo URL)

2) Secret Use

   bwstart → unlock (Keychain creds) → BW_SESSION
   ↓
   bwgetkey/bwexportkey/bwsecurerun → set env for subcommand only → run cmd → unset

3) Install / Linking

   install.sh → link_if_exists (~/.zshrc, ~/.gitconfig, dev CLI, optional legacy tools)
   ↓
   create dirs (~/.config/dev-tools, ~/.cache/dev-tools, ~/.config/nvim)
   ↓
   chmod 600 for logs/config where applicable

## Extensibility Guidelines

- Keep new tools behind the `dev` CLI or as optional `INSTALL_LEGACY_TOOLS=1` links.
- Store user config via `save_config`/`get_config` and avoid bespoke dotfiles.
- Respect the security model: no secrets on disk; use Bitwarden helpers for any token flows.
- Keep dependencies optional; check at call time and degrade gracefully.
