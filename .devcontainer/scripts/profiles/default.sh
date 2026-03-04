#!/bin/bash

# ============================================================================
# Source Shared Utilities
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_FILE="$SCRIPT_DIR/../common.sh"
if [ ! -f "$COMMON_FILE" ]; then
    echo "ERROR: Could not find common.sh at expected location: $COMMON_FILE" >&2
    exit 1
fi
source "$COMMON_FILE"

# ============================================================================
# Main Script
# ============================================================================
# Default profile — host SSH agent forwarding, no personal tooling
# SSH agent forwarding from the host is active (wired via devcontainer.json),
# so no SSH setup is needed here.
info_log "Configuring default profile..."
debug_log "Using host SSH agent forwarding"
debug_log "To use a repo-scoped deploy key instead, set DEVCONTAINER_USE_GITHUB_DEPLOY_KEY=true in host ~/.zshrc"

info_log "Default profile complete."
