# Secure Dotfiles with Bitwarden Secret Management

A minimalist, secure dotfiles repository with integrated Bitwarden secret management.

## 🔑 Key Features

- **Secure API Key Management**: Store and retrieve API keys via Bitwarden CLI
- **Secure Environment Variables**: Prevent leaks through history and process listing
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

3. Set up Bitwarden credentials:

   ```bash
   # Store master password (you'll be prompted)
   security add-generic-password -s "BitwardenMasterPassword" -a "$USER" -w

   # If using API key authentication, also store:
   security add-generic-password -s "BitwardenClientID" -a "$USER" -w
   security add-generic-password -s "BitwardenClientSecret" -a "$USER" -w
   ```

4. Reload your shell:
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

## 🚀 Customization

Add local customizations:

- ZSH: Create `~/.zshrc.local` (not tracked by git)
- Git: Create `~/.gitconfig.local` (not tracked by git)
  The repository contains a template `.gitconfig` that includes a local config file.
  Create `~/.gitconfig.local` with your personal information:
  ```ini
  [user]
     name = Your Name
     email = your.email@example.com
  ```
- Neovim: Edit `~/dotfiles/config/nvim/init.lua`

## 📚 Components

- **Bitwarden Secret Manager**: Secure API key management
- **ZSH Configuration**: Shell setup with security features
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
