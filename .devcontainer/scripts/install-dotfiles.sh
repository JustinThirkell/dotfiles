#!/bin/bash

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
info_log "install-dotfiles.sh: not yet implemented, skipping"
# Intended approach:
# - Each container gets its own read-only deploy key for the dotfiles repo
# - This script uses that key to clone the dotfiles repo
# - The AI can reach the dotfiles repo and nothing else
#
# VS Code's built-in dotfiles support is intentionally not used — it requires
# SSH agent forwarding, which grants the agent access to your entire SSH keyring.
#
# This is deferred. Revisit if missing shell utilities actually blocks agent work.

