# Product Requirements Document (PRD)

## Summary

Public dotfiles focused on security and minimalism with a unified developer workflow. The system must be safe on day one, portable, and fast to operate.

## Goals

- Ship a minimal, secure baseline for macOS.
- Make common dev tasks (ticket → branch → commit → PR) consistent via `dev`.
- Keep secrets out of Git and shell history while staying ergonomic.

## Personas

- Individual Engineer: wants a hardened setup that doesn’t get in the way.
- Team Member: needs an onboarding baseline to file a PR on day one.

## Functional Requirements

R1. Installation
- Link existing files safely; back up conflicts; don’t fail on missing optional files.
- Minimal by default: link `dev`, not legacy tools unless `INSTALL_LEGACY_TOOLS=1`.

R2. Secrets
- Never store secrets in repo; provide Bitwarden helpers for retrieval and ephemeral use.
- Optional: Jira token in Keychain with config marker to avoid storing raw token.

R3. History Protection
- Maintain ignore patterns for sensitive commands; provide `histaudit`, `histclean`, `private`.

R4. Unified Dev CLI (`dev`)
- tickets/select: fetch Jira tickets, select one, and cache selection.
- branch: create branch with `<prefix>/<KEY>-<kebab-title>` and store branch name.
- commit: open editor with standardized message from ticket and wrapped body.
- pr: push and create PR (via `gh` if available) with useful defaults.

R5. Neovim Minimal Config
- Provide a small, modern setup that works out of the box.

R6. Documentation & Safety Checks
- Provide concise docs (README, VISION, ARCHITECTURE, PRD, IMPLEMENTATION_PLAN, SECURITY).
- Include a heuristic secret scanner runnable locally.

## Non‑Functional Requirements

- Security: config/logs chmod 600; redact obvious secrets in logs; ephemeral env use.
- Portability: macOS‑first; minimal dependencies; graceful degradation when deps missing.
- Usability: simple commands, clear errors, interactive confirmations for risky operations.

## Out of Scope

- Managing every shell/editor; keep scope minimal and composable.
- Cross‑platform parity beyond macOS.

## Acceptance Criteria

- Fresh clone + `./install.sh` completes without errors; creates backups if conflicts.
- Running `tests/security/scan_secrets.sh` returns clean on a fresh repo.
- `dev tickets/select/branch/commit/pr` flow works when deps/met credentials present.
- Sourcing `.zshrc` does not fail if optional tools are missing.

## Dependencies

- Required: `bash`, `git`.
- Common: `jq`, `curl` (Jira), `gh` (PRs), `bw` (Bitwarden), macOS `security`.

## Risks / Mitigations

- Secret exposure via logs/history → redaction + ignore patterns + `private` mode.
- Tooling drift → minimal footprint and clear docs to discourage bloat.
- Missing deps → check at call time and provide guidance.
