#!/bin/bash

# ============================================================================
# Source Shared Utilities
# ============================================================================
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_FILE="$SCRIPT_DIR/../scripts/common.sh"
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
debug_log "To use a repo-scoped deploy key instead, create a profile that calls configure-git-ssh.sh"

info_log "Default profile complete."
