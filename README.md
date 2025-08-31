# Secure Dotfiles with Bitwarden Secret Management

A minimalist, secure dotfiles repository with integrated Bitwarden secret management and developer workflow tools.

## 🔑 Key Features

- **Secure API Key Management**: Store and retrieve API keys via Bitwarden CLI
- **Secure Environment Variables**: Prevent leaks through history and process listing
- **Development Workflow Tools**: Integrated Jira and GitHub tools for efficient development
- **Minimal Configuration**: Focus on essential tools (ZSH, Neovim, Git)
- **Easy Deployment**: Simple installation script with automatic backups

## 📊 Project KPIs

### Security

- ✅ No secrets in Git repository
- ✅ API keys managed via Bitwarden
- ✅ History protection for sensitive commands
- ✅ Auto-locking sessions
- ✅ Secure environment variable handling

### Maintainability

- ✅ Modular architecture
- ✅ Comprehensive documentation
- ✅ Consistent naming conventions
- ✅ Minimal dependencies

### Usability

- ✅ Simple installation process
- ✅ Clear error messages
- ✅ Comprehensive help system
- ✅ Automatic backups
- ✅ Streamlined development workflow

### Portability

- ✅ Works across macOS environments
- ✅ Minimal system-specific code
- ✅ Local customization options

## 🛠️ Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/yourusername/dotfiles.git ~/dotfiles
   ```

2. Run the installation script:

   ```bash
   cd ~/dotfiles
   chmod +x install.sh
   ./install.sh
   ```

   Optional:

   - Dry-run (preview actions): `./install.sh --dry-run`
   - Link legacy interactive tools: `INSTALL_LEGACY_TOOLS=1 ./install.sh`

3. Set up Bitwarden credentials:

   ```bash
   # Store master password (you'll be prompted)
   security add-generic-password -s "BitwardenMasterPassword" -a "$USER" -w

   # If using API key authentication, also store:
   security add-generic-password -s "BitwardenClientID" -a "$USER" -w
   security add-generic-password -s "BitwardenClientSecret" -a "$USER" -w
   ```

4. Ensure `~/bin` is in your PATH:

   ```bash
   echo 'export PATH="$HOME/bin:$PATH"' >> ~/.zshrc.local
   ```

5. Reload your shell:
   ```bash
   source ~/.zshrc
   ```

## 🔐 Using Bitwarden Secret Manager

Start a session:

```bash
bwstart
```

Store an API key:

```bash
bwstorekey "OpenAI API Key" "sk-your-secret-key" "API Keys"
```

Use a key securely:

```bash
bwsecurerun "GitHub Token" GITHUB_TOKEN gh repo list
```

View all available commands:

```bash
bwhelp
```

## 🚀 Development Workflow Tools

### Unified CLI (Recommended)

The `dev` command provides concise subcommands:

```bash
dev tickets      # fetch Jira tickets
dev select       # select a ticket (stores metadata for branch/commit)
dev branch       # create properly named branch
dev commit       # guided commit message (opens editor)
dev pr           # push and create PR (uses gh if available)
dev workflow     # legacy interactive menu (full assistant)
dev verify       # self-check: symlinks + secret scan
dev init         # first-time guided setup (core, Jira, GitHub)
```

### Legacy Individual Tools

Still available for direct use:

- `jira-tool` (interactive Jira)
- `github-tool` (interactive Git/GitHub)
- `dev-workflow` (integrated menu; superseded by `dev`)

## 🔧 Customization

Add local customizations:

- ZSH: Create `~/.zshrc.local` (not tracked by git)
- Git: Create `~/.gitconfig.local` (not tracked by git)
  
  
      ```ini
      [user]
         name = Your Name
         email = your.email@example.com
      ```

- Neovim: Edit `~/dotfiles/config/nvim/init.lua`

## 📚 Components

- **Bitwarden Secret Manager**: Secure API key management
- **ZSH Configuration**: Shell setup with security features
- **Development Workflow Tools**: Jira and GitHub integration
- **Neovim Configuration**: Modern editor setup
- **Git Configuration**: Version control defaults and aliases
- **Installation Script**: Easy deployment with backups

## 🔍 Security Best Practices

1. Never commit secrets to the repository
2. Use `bwsecurekey` instead of direct environment variables
3. Keep your Bitwarden vault locked when not in use
4. Regularly update your master password
5. Use folder organization in Bitwarden for easier management

## 📦 Dependencies

- [Bitwarden CLI](https://bitwarden.com/help/cli/)
- [jq](https://stedolan.github.io/jq/)
- macOS `security` command (pre-installed)
- [GitHub CLI](https://cli.github.com/) (optional, for PR creation)
- `curl` (for Jira API calls)

## 🔐 Secret Management Quick Commands



```bash
bwstart                                 # unlock/login Bitwarden
bwsecurekey "OpenAI API Key" OPENAI_API_KEY   # export key w/o history
bwsecurerun "GitHub Token" GITHUB_TOKEN gh repo list
bwloadfolder "API Keys"                 # bulk export folder entries
```

See `SECURITY.md` for comprehensive guidance.

## 🧪 Safety Checks

Secret scanning (heuristic):
```bash
tests/security/scan_secrets.sh
```

Git pre-commit hook (optional):
```bash
git config core.hooksPath .githooks
```
This runs the secret scan on every commit; bypass with `--no-verify` if needed.

## 🤝 Contributing

Please see CONTRIBUTING.md for details on how to contribute to this project.
