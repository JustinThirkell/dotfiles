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
PERSONAL_FILE="/workspace/.devcontainer/gitconfig.personal"

if [ ! -f "$GITCONFIG_FILE" ]; then
    error_log "Git configuration file not found: $GITCONFIG_FILE"
    exit 1
fi

# Validate gitconfig.personal exists and has required fields
if [ ! -f "$PERSONAL_FILE" ]; then
    error_log "gitconfig.personal not found: $PERSONAL_FILE"
    error_log ""
    error_log "Create this file with your git identity:"
    error_log "  [user]"
    error_log "      name = Claude Sonnet 4.5"
    error_log "      email = you+claudecode@example.com"
    error_log ""
    error_log "This file is gitignored — it stays local to your machine."
    exit 1
fi

# Check that name and email are set in gitconfig.personal
PERSONAL_NAME=$(git config --file "$PERSONAL_FILE" user.name 2>/dev/null || echo "")
PERSONAL_EMAIL=$(git config --file "$PERSONAL_FILE" user.email 2>/dev/null || echo "")

if [ -z "$PERSONAL_NAME" ] || [ -z "$PERSONAL_EMAIL" ]; then
    error_log "gitconfig.personal is missing required fields"
    error_log "Found: name='${PERSONAL_NAME}' email='${PERSONAL_EMAIL}'"
    error_log ""
    error_log "gitconfig.personal must contain:"
    error_log "  [user]"
    error_log "      name = Claude Sonnet 4.5"
    error_log "      email = you+claudecode@example.com"
    exit 1
fi

# IMPORTANT: Forcibly overwrite ~/.gitconfig to prevent VS Code's auto-sync
# VS Code's devcontainer extension automatically copies the host machine's .gitconfig
# into the container. We want our AI-specific configuration to take precedence.
# By running this on every container start (postStartCommand), we ensure our
# configuration always wins.

debug_log "Overwriting ~/.gitconfig with container-specific configuration..."
cp -f "$GITCONFIG_FILE" "$HOME/.gitconfig"
chmod 600 "$HOME/.gitconfig"

# Verify the configured identity
GIT_USER_NAME=$(git config --global user.name 2>/dev/null || echo "(not set)")
GIT_USER_EMAIL=$(git config --global user.email 2>/dev/null || echo "(not set)")

info_log "✓ Git identity configured as: $GIT_USER_NAME <$GIT_USER_EMAIL>"
info_log "Git user configuration complete!"
