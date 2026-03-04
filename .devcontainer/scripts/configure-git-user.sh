#!/bin/bash
set -euo pipefail

# ============================================================================
# Source Shared Utilities
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_FILE="$SCRIPT_DIR/common.sh"
if [ ! -f "$COMMON_FILE" ]; then
  echo "ERROR: Could not find common.sh at expected location: $COMMON_FILE" >&2
  exit 1
fi
source "$COMMON_FILE"

# ============================================================================
# Main Script
# ============================================================================
info_log "Configuring git identity for AI agent..."

GITCONFIG_FILE="/workspace/.devcontainer/gitconfig"

if [ ! -f "$GITCONFIG_FILE" ]; then
  error_log "Git configuration file not found: $GITCONFIG_FILE"
  exit 1
fi

# Read git identity from config.local
GIT_USER_NAME=$(get_git_user_name)
GIT_USER_EMAIL=$(get_git_user_email)

if [ -z "$GIT_USER_NAME" ] || [ -z "$GIT_USER_EMAIL" ]; then
  error_log "Git identity not configured in config.local"
  error_log "Found: name='${GIT_USER_NAME}' email='${GIT_USER_EMAIL}'"
  error_log ""
  error_log "Add these lines to .devcontainer/config.local:"
  error_log "  GIT_USER_NAME=Claude (for Your Name)"
  error_log "  GIT_USER_EMAIL=you+claude@example.com"
  exit 1
fi

# IMPORTANT: Forcibly overwrite ~/.gitconfig to prevent VS Code's auto-sync
# VS Code's devcontainer extension automatically copies the host machine's .gitconfig
# into the container. We want our AI-specific configuration to take precedence.
# This runs on every attach (postAttachCommand) so our configuration always wins.

debug_log "Overwriting ~/.gitconfig with container-specific configuration..."
cp -f "$GITCONFIG_FILE" "$HOME/.gitconfig"
chmod 600 "$HOME/.gitconfig"

# Directly set user identity — git config --global does not expand [include]
# by default in Git 2.39+ (requires --includes flag).
git config --global user.name "$GIT_USER_NAME"
git config --global user.email "$GIT_USER_EMAIL"

# Verify the configured identity
RESULTING_GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "(not set)")
RESULTING_GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "(not set)")

info_log "✓ Git identity configured as: $RESULTING_GIT_USER_NAME <$RESULTING_GIT_USER_EMAIL>"
info_log "Git user configuration complete!"
