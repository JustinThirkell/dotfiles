#!/bin/bash
set -euo pipefail

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
info_log "Applying Justin's personal profile..."

# Set up repo-scoped deploy key from 1Password (replaces host SSH agent)
/workspace/.devcontainer/scripts/configure-git-ssh.sh

# Install personal zsh config, aliases, shell preferences etc here...

info_log "Justin's profile complete."
