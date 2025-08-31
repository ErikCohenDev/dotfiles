# Implementation Plan

This plan tracks how the dotfiles baseline is built and maintained. It favors small, verifiable steps with tight scope.

## Current State (Implemented)

- Safe installer with backups and optional linking via `link_if_exists`.
- Minimal default linking (only `dev` CLI); legacy tools opt‑in.
- Bitwarden helper module for secure secret use; auto‑lock timer; Keychain assist.
- History protection utilities and patterns.
- Unified `dev` CLI for Jira/GitHub flows; graceful dependency checks.
- Secret scanner tuned to avoid doc/helper false positives.
- Minimal Neovim config.
- Minimal `.zshrc` and `.gitconfig` with local override support.

## Near‑Term Backlog

1. Pre‑commit Hook (opt‑in)
   - Add `.githooks/pre-commit` that runs `tests/security/scan_secrets.sh`.
   - Document: `git config core.hooksPath .githooks`.

2. Enhanced Jira Queries
   - Support filters: assignee = currentUser(), status selection, project overrides.

3. PR Templates / Checklists
   - Optional PR body augmentation (risk checklist, test notes) when using `gh`.

4. CI Skeleton (Optional)
   - GitHub Actions to run secret scan on PRs (repo is public; keep minimal).

## Future Options (Exploratory)

- Bitwarden Secrets Manager integration in addition to CLI secure notes.
- Encrypted local overlays via `age`/`sops` for machine‑specific secrets/config.
- `dev` subcommands for common maintenance: `dev deps`, `dev lint`, `dev verify`.

## Design Guardrails

- Keep new features behind opt‑in flags or `dev` subcommands.
- Minimize persistent state; prefer cache over config when possible.
- Never store secrets or tokens in tracked files; use helpers.

## Rollout / Validation

- Validate installer on a clean macOS environment.
- Run the ticket→branch→commit→PR flow against a test repo with `gh` available.
- Confirm secret scans are green; confirm logs are redacted.

## Maintenance

- Periodically re‑run shellcheck; keep Bash readable; avoid clever one‑liners.
- Review docs for drift quarterly; prune features rather than accumulate bloat.
