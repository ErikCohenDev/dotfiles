# Contributing to Secure Dotfiles

Thank you for considering contributing to our dotfiles repository! This document provides guidelines and workflow information to help make the contribution process smooth and effective.

## Code of Conduct

- Respect other contributors
- Be constructive in feedback
- Focus on the best solution, not personal preferences
- Maintain security as the highest priority

## Development Workflow

1. **Fork the repository** and clone your fork
2. **Create a feature branch** from `main`
   - Use descriptive names: `feature/description` or `fix/issue-description`
3. **Make your changes**, following the style guidelines below
4. **Test your changes** thoroughly
5. **Submit a pull request** to the `main` branch

## Branch Protection

The `main` branch is protected:

- Direct pushes are not allowed
- Pull requests require review
- All tests must pass before merging

## Style Guidelines

### Shell Scripts

- Use `shellcheck` to validate shell scripts
- Include descriptive comments
- Add a header comment block describing purpose and dependencies
- Use meaningful function and variable names
- Indent with 2 spaces
- Use `#!/bin/bash` shebang (not `sh`)
- Quote all variables unless word splitting is intentional

### Documentation

- Keep line length under 100 characters for readability
- Use Markdown for all documentation
- Follow consistent heading structure
- Update documentation when changing functionality

## Security Guidelines

1. **No secrets in code**:

   - Never commit API keys, passwords, or tokens
   - Use the Bitwarden secret management for all secrets

2. **Secure defaults**:

   - Scripts should fail securely
   - History protection for sensitive commands must be maintained
   - File permissions must be appropriate (e.g., `chmod 600` for sensitive files)

3. **Dependency management**:
   - Minimize external dependencies
   - Clearly document all required dependencies

## Testing

Before submitting a PR, ensure:

1. **All scripts work as expected**:

   - Run the installation script in a clean environment
   - Verify that all tools function correctly

2. **Security checks pass**:

   - Run the security tests in `tests/security/`
   - Verify no sensitive information is leaked

3. **All documentation is updated**:
   - README.md reflects any new features
   - REPOSITORY_OVERVIEW.md is accurate

## Submitting Pull Requests

1. **Create a descriptive PR title**:

   - Follow format: `[Component] Brief description`
   - Example: `[Dev Tools] Add Jira ticket filtering`

2. **Write a comprehensive description**:

   - What does this PR do?
   - Why is it needed?
   - How has it been tested?
   - Any screenshots or examples?

3. **Link to related issues** if applicable

4. **Respond to feedback** and make requested changes

## Review Process

PRs will be reviewed for:

- Code quality and style
- Security implications
- Test coverage
- Documentation completeness

## Getting Help

If you need assistance:

- Open an issue with questions
- Comment on the relevant PR or issue
- Contact the maintainers directly (see README)

Thank you for contributing!
