# Security Guidelines for Public Dotfiles

These dotfiles are intentionally public. Follow these practices to avoid leaking secrets or personal information.

## Golden Rules

1. Never commit API keys, tokens, passwords, or personal identity values.
2. Keep user–specific overrides in untracked files:
   - `~/.zshrc.local`
   - `~/.gitconfig.local`
3. Store all secrets in Bitwarden (CLI + macOS keychain assist) – never plaintext in repo.
4. Use helper commands (`dev`, Bitwarden functions) instead of ad‑hoc scripts with embedded secrets.

## Secret Storage Strategy

Layered approach:

- Long–lived secrets (API keys, tokens): Bitwarden vault items (secure note with `API_KEY=` line) or Bitwarden Secrets Manager.
- Jira / GitHub tokens: Prefer macOS Keychain (prompted during configuration). A marker `__KEYCHAIN__` is stored instead of the token.
- Transient shell export: Use `bwsecurekey`, `bwexportkey`, or `bwwithkey` (see `bw-secret-manager.sh`).

## Quick Secret Usage Patterns

Fetch & export (no history):

```bash
bwsecurekey "OpenAI API Key" OPENAI_API_KEY
```

One–off command execution:

```bash
bwsecurerun "GitHub Token" GITHUB_TOKEN gh repo list
```

Bulk load folder:

```bash
bwloadfolder "API Keys"
```

## Public Safety Checklist Before Commit

Run (future):

```bash
tests/security/scan_secrets.sh
```

Manual spot checks:

- `git diff --cached` – search for strings like `API_KEY`, `SECRET`, `TOKEN`, `password`, email addresses.
- `grep -R "API_KEY=" -n .` should return only Bitwarden helper code.

## Logging & Redaction

`core.sh` redacts obvious key patterns in logs. Avoid echoing raw secrets manually.

## History Protection

`history-manager.sh` adds patterns to ZSH `HISTORY_IGNORE` and provides:

- `histaudit` – identify risky commands
- `histclean` – remove leaked lines
- `private <cmd>` – run without history recording

## Reporting / Improvements

Open an issue (avoid putting real secret values). Provide a reproduction or obfuscated example.

## Future Enhancements (Planned)

- Automated secret scan pre-commit hook
- Optional integration with Bitwarden Secrets Manager tokens
- Support for age / sops encrypted local overlays

Stay disciplined: convenience functions exist so secrets never land on disk in plaintext.
