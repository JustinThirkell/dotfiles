#!/bin/bash
set -e

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
# Orchestrator for postStartCommand / postCreateCommand.
# Runs shared infrastructure setup then delegates to a profile script.

CLAUDE_AUTH_MODE=$(get_claude_auth_mode)
PROFILE=$(get_devcontainer_profile)
export DEVCONTAINER_CLAUDE_AUTH_MODE="$CLAUDE_AUTH_MODE"

info_log "Configuring shared environment (claude_auth: $CLAUDE_AUTH_MODE, profile: $PROFILE)..."

/workspace/.devcontainer/scripts/configure-git-user.sh
/workspace/.devcontainer/scripts/configure-claude.sh

PROFILE_SCRIPT="/workspace/.devcontainer/profiles/${PROFILE}.sh"
debug_log "Profile script: $PROFILE_SCRIPT"
info_log "Configuring ${PROFILE} profile..."

if [ -f "$PROFILE_SCRIPT" ]; then
    info_log "Running profile: ${PROFILE}"
    bash "$PROFILE_SCRIPT"
else
    info_log "Profile '${PROFILE}' not found, using default"
    bash "/workspace/.devcontainer/profiles/default.sh"
fi
