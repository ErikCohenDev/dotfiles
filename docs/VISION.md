# Vision

Build a secure, minimal, and ergonomic dotfiles stack that makes a fresh macOS machine production‑ready in minutes — without ever storing secrets in the repo. The setup should feel invisible day‑to‑day, yet provide powerful helpers (Bitwarden‑backed secrets and a unified dev CLI) the moment they’re needed.

## Why This Exists

- Most public dotfiles drift into bloat or leak sensitive data.
- Security tooling is often an afterthought and hard to use consistently.
- Dev workflows (Jira → branch → commit → PR) are repetitive and error‑prone.

This repo solves those problems with sane defaults, explicit security layers, and a small set of high‑impact tools.

## Principles

1. Security by Default: never commit secrets; prefer Bitwarden + Keychain; redact logs.
2. Minimalism: fewer, sharper tools; one primary entrypoint (`dev`).
3. Ergonomics: helpers that save time without locking you in; graceful fallbacks.
4. Portability: bias toward macOS defaults; minimize external deps.
5. Auditability: readable scripts, clear docs, simple secret scanning.

## What “Good” Looks Like

- Fresh install links only what exists, backs up conflicts, and just works.
- No secrets in Git history; `tests/security/scan_secrets.sh` is clean.
- Secrets flow from Bitwarden to processes without touching disk or history.
- Common workflow (select ticket → branch → commit → PR) is one `dev` away.
- Docs are short, accurate, and kept up‑to‑date.

## Non‑Goals

- Comprehensive shell/plugin frameworks; keep scope tight and composable.
- Managing every editor/terminal; ship a minimal Neovim and stop there.
- Cross‑platform parity; prioritize macOS for simplicity.

## Target Users

- Individual engineers who want a hardened, no‑nonsense setup.
- Teams who need a reference dotfiles baseline for new machines.

## Near‑Term Roadmap

- Pre‑commit secret scan hook (optional, opt‑in).
- Optional Bitwarden Secrets Manager integration.
- Encrypted local overlays with `age`/`sops` (opt‑in).

## Success Metrics (KPI Snapshot)

- Zero secrets committed; green secret scans in CI and locally.
- “Time to first PR” reduced (ticket → PR) via `dev` CLI.
- Low surface area (few scripts, small config) retained over time.
