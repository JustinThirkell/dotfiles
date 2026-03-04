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
info_log "Configuring Claude Code settings..."

MODE=$(get_devcontainer_mode)
debug_log "Devcontainer mode: $MODE"

CLAUDE_SETTINGS_FILE="/workspace/.devcontainer/claude-settings.json"
CLAUDE_CONFIG_DIR="$HOME/.claude"

if [ -f "$CLAUDE_SETTINGS_FILE" ]; then
    mkdir -p "$CLAUDE_CONFIG_DIR"

    # IMPORTANT: Always overwrite settings.json on container start
    # -------------------------------------------------------------
    # The ~/.claude directory is mounted as a persistent Docker volume to preserve
    # conversation history and session state across container rebuilds. However,
    # we want SETTINGS to be version-controlled in git (not persisted in the volume).
    #
    # By forcibly copying settings.json from claude-settings.json on every container start, we ensure:
    # 1. Settings changes in git are immediately applied on next restart
    # 2. Settings are version-controlled and documented
    # 3. Conversation history is still preserved in the volume
    #
    # This is a hybrid approach: ephemeral settings + persistent history.

    debug_log "Overwriting Claude settings from version-controlled config..."
    cp -f "$CLAUDE_SETTINGS_FILE" "$CLAUDE_CONFIG_DIR/settings.json"

    if [ "$MODE" = "standard" ]; then
        # Standard mode: remove apiKeyHelper so Claude prompts for browser login
        info_log "Standard mode: removing apiKeyHelper (browser login)"
        if command -v jq &>/dev/null; then
            jq 'del(.apiKeyHelper)' "$CLAUDE_CONFIG_DIR/settings.json" > "$CLAUDE_CONFIG_DIR/settings.json.tmp"
            mv "$CLAUDE_CONFIG_DIR/settings.json.tmp" "$CLAUDE_CONFIG_DIR/settings.json"
        else
            # sed fallback: remove the apiKeyHelper line
            sed -i '/^\s*"apiKeyHelper"/d' "$CLAUDE_CONFIG_DIR/settings.json"
        fi
    else
        info_log "Locked-down mode: apiKeyHelper active (1Password retrieves API key)"
    fi

    chmod 600 "$CLAUDE_CONFIG_DIR/settings.json"
    info_log "Claude Code settings configured"
else
    debug_log "Claude settings file not found at $CLAUDE_SETTINGS_FILE (optional)"
fi

info_log "Claude Code configuration complete!"
