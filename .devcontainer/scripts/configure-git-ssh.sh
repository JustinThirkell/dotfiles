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
info_log "Starting GitHub SSH configuration..."

# Determine repository name from git
REPO_NAME=$(get_repo_name)

if [ -z "$REPO_NAME" ]; then
    error_log "Failed to determine repository name"
    error_log "Not in a git repository or could not detect repository name"
    exit 1
fi

info_log "Configuring SSH for repository: $REPO_NAME"

# Fetch private key from 1Password
HELPER_SCRIPT="/workspace/.devcontainer/scripts/github-ssh-key-retriever.sh"

if [ ! -x "$HELPER_SCRIPT" ]; then
    error_log "GitHub SSH helper script not found or not executable: $HELPER_SCRIPT"
    exit 1
fi

debug_log "Fetching private key from 1Password..."
PRIVATE_KEY=$("$HELPER_SCRIPT")
HELPER_EXIT=$?

if [ $HELPER_EXIT -ne 0 ]; then
    error_log "Failed to fetch private key from 1Password"
    error_log "Helper output: $PRIVATE_KEY"
    exit 1
fi

if [ -z "$PRIVATE_KEY" ]; then
    error_log "Private key is empty"
    exit 1
fi

debug_log "Private key retrieved successfully (length: ${#PRIVATE_KEY})"

# Create .ssh directory if it doesn't exist
SSH_DIR="$HOME/.ssh"
mkdir -p "$SSH_DIR"
chmod 700 "$SSH_DIR"
debug_log "Created SSH directory: $SSH_DIR"

# Write private key to file
KEY_FILE="$SSH_DIR/id_ed25519_${REPO_NAME}"
echo "$PRIVATE_KEY" > "$KEY_FILE"
chmod 600 "$KEY_FILE"

# Validate the key file is properly formatted (should start with -----BEGIN)
if ! head -n 1 "$KEY_FILE" | grep -q "^-----BEGIN"; then
    error_log "Written key file does not appear to be valid"
    error_log "First line: $(head -n 1 "$KEY_FILE")"
    error_log "This may indicate an encoding issue. Check the key file contents."
    rm -f "$KEY_FILE"
    exit 1
fi

info_log "✓ Wrote private key to: $KEY_FILE"

# Configure SSH config
SSH_CONFIG="$SSH_DIR/config"
HOST_ALIAS="github.com-${REPO_NAME}"

debug_log "Configuring SSH config file: $SSH_CONFIG"

# Remove existing configuration for this host alias if present
if [ -f "$SSH_CONFIG" ]; then
    # Create temp file without the old config block
    sed "/^Host ${HOST_ALIAS}$/,/^$/d" "$SSH_CONFIG" > "${SSH_CONFIG}.tmp"
    mv "${SSH_CONFIG}.tmp" "$SSH_CONFIG"
fi

# Append new configuration
cat >> "$SSH_CONFIG" << EOF

Host ${HOST_ALIAS}
    HostName github.com
    User git
    IdentityFile ${KEY_FILE}
    IdentitiesOnly yes
    StrictHostKeyChecking accept-new
EOF

chmod 600 "$SSH_CONFIG"
info_log "✓ Updated SSH config with host alias: $HOST_ALIAS"

# Update git remote URL to use SSH alias
debug_log "Updating git remote URL..."
CURRENT_REMOTE=$(git config --get remote.origin.url)
debug_log "Current remote: $CURRENT_REMOTE"

# Check if already using our SSH alias
if [[ "$CURRENT_REMOTE" =~ git@${HOST_ALIAS}: ]]; then
    info_log "✓ Git remote already configured with SSH alias: $HOST_ALIAS"
else
    # Extract owner/repo from current URL (handles both SSH and HTTPS formats)
if [[ "$CURRENT_REMOTE" =~ github\.com[:/]([^/]+)/([^/]+)(\.git)?$ ]]; then
    OWNER="${BASH_REMATCH[1]}"
    REPO="${BASH_REMATCH[2]}"
    REPO="${REPO%.git}"  # Remove .git if present

    NEW_REMOTE="git@${HOST_ALIAS}:${OWNER}/${REPO}.git"
    debug_log "New remote: $NEW_REMOTE"

    git remote set-url origin "$NEW_REMOTE"
    info_log "✓ Updated git remote to: $NEW_REMOTE"
    else
        error_log "Could not parse GitHub owner/repo from remote URL: $CURRENT_REMOTE"
        error_log "Expected format: git@github.com:owner/repo.git or https://github.com/owner/repo.git"
        exit 1
    fi
fi

# ============================================================================
# GitHub CLI Configuration
# ============================================================================

info_log "Configuring GitHub CLI..."

# Configure gh to use SSH protocol (will use our configured SSH keys)
gh config set git_protocol ssh --host github.com 2>/dev/null || true

# Test GitHub CLI authentication
if gh auth status &>/dev/null; then
    info_log "✓ GitHub CLI authenticated successfully"
else
    # gh will use git's SSH credentials automatically
    debug_log "GitHub CLI will use SSH authentication via git credentials"
fi

info_log "GitHub SSH configuration complete!"
