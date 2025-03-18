# Dotfiles Repository Overview

This document provides a comprehensive overview of the repository structure, components, and design principles for LLM ingestion.

## Repository Structure

```
dotfiles/
├── home/               # Files that go directly in home directory
│   ├── .zshrc          # ZSH configuration
│   └── .gitconfig      # Git configuration
├── config/             # App-specific configurations
│   └── nvim/           # Neovim configuration
│       └── init.lua    # Main Neovim config file
├── scripts/            # Utility scripts
│   ├-- bw-secret-manager.sh  # Bitwarden secret management
│   └── history-manager.sh    # Manages command history
├── install.sh          # Installation script
├── README.md           # User documentation
└── REPOSITORY_OVERVIEW.md  # This file - detailed documentation for LLMs
```

## Key Performance Indicators (KPIs)

### Security

- All secrets are managed via Bitwarden CLI, never stored in plain text
- History protection for sensitive commands
- Auto-locking sessions after configurable timeouts
- Secure environment variable handling
- API key isolation in subshells

### Maintainability

- Modular design with clear separation of concerns
- Comprehensive documentation and comments
- Consistent naming conventions
- Minimal dependencies (only requires: bw CLI, jq, security)

### Usability

- Clear error messages with helpful suggestions
- Command completion and help functions
- Consistent interface for commands
- Automatic backups during installation
- Comprehensive help system via `bwhelp`

### Portability

- Works across macOS environments
- Minimal system-specific code
- Dependencies clearly documented
- Easy installation and setup

## Core Components

### Bitwarden Secret Manager

- API key storage and retrieval
- Secure environment variable export
- Session management
- Folder-based organization
- Bulk operations support

### ZSH Configuration

- Sources the Bitwarden secret manager
- Sets up core environment variables
- Configures history protection for sensitive commands

### Installation System

- Backs up existing files
- Creates necessary directories
- Creates symbolic links
- Generates documentation

## Design Decisions

- Using symbolic links to maintain single source of truth
- Storing API keys in Bitwarden for security and portability
- Using macOS keychain for Bitwarden credentials
- Implementing history protection for sensitive commands
