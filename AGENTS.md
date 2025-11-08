# Rokkit - Agent Guidelines

## Project Overview
Rokkit is a bash CLI tool for backing up and managing dotfiles. Pure bash scripts, no build system.

## Commands
- **Run CLI**: `./rokkit backup` or `./rokkit help`
- **Make executable**: `chmod +x rokkit` or `chmod +x scripts/*.sh`
- **No tests/linting**: This is a simple bash project without formal test infrastructure

## Code Style
- **Shebang**: Use `#!/usr/bin/env bash` for all scripts
- **Error handling**: Use `set -e` (rokkit) or `set -euo pipefail` (scripts) at top of files
- **Variables**: UPPER_CASE for constants/config, lower_case for local vars, always quote: `"$VAR"`
- **Functions**: snake_case naming, define before use
- **Output functions**: Use helper functions for consistent output (print_success, print_error, msg, err)
- **Colors**: Define at top: `GREEN='\033[0;32m'`, `NC='\033[0m'`, use with `echo -e`
- **Comments**: Use `#` for inline comments, `# ----` separators for sections, heredoc for help text
- **Conditionals**: Use `[[ ]]` for tests (not `[ ]`), prefer `if [[ ]]; then` on same line
- **Paths**: Use `SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"` for script location
- **Error exit**: Exit with non-zero code on errors: `exit 1`

## Project Structure
- `rokkit` - Main CLI entry point
- `config/dotfiles.conf` - User dotfile configuration
- `dotfiles/` - Backup destination (git-ignored during backups)
- `scripts/` - Utility installation scripts
