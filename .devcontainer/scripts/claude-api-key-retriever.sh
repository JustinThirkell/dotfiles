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

TOKEN_RETRIEVER_FILE="$SCRIPT_DIR/op-service-account-token-retriever.sh"
if [ ! -f "$TOKEN_RETRIEVER_FILE" ]; then
    error_log "Could not find op-service-account-token-retriever.sh at expected location: $TOKEN_RETRIEVER_FILE"
    exit 1
fi
source "$TOKEN_RETRIEVER_FILE"

# ============================================================================
# Main Script
# ============================================================================
debug_log "Claude API Key Helper starting..."

# Get service account token using convention-based resolution
REPO_NAME=$(get_repo_name)
if [ -z "$REPO_NAME" ]; then
    error_log "Failed to determine repository name"
    exit 1
fi

debug_log "Repository name: $REPO_NAME"

# Resolve service account token from file
SERVICE_ACCOUNT_TOKEN=$(get_service_account_token "$REPO_NAME")
if [ -z "$SERVICE_ACCOUNT_TOKEN" ]; then
    error_log "Service account token not found for repository: $REPO_NAME"
    error_log "Expected token file: /workspace/.devcontainer/.op-service-account-token"
    error_log "This file should be created by the setup script"
    exit 1
fi

debug_log "Service account token found (length: ${#SERVICE_ACCOUNT_TOKEN})"

# Configure 1Password CLI to use service account
export OP_SERVICE_ACCOUNT_TOKEN="$SERVICE_ACCOUNT_TOKEN"
VAULT=$(get_repo_vault_name "$REPO_NAME")

info_log "Looking up API key for repository: $REPO_NAME in vault: $VAULT"

# Query 1Password for items in the vault with matching repo field
debug_log "Querying 1Password for items with repo='$REPO_NAME'..."

# First, get all items from the vault
ALL_ITEMS=$(op item list --vault "$VAULT" --format json 2>/dev/null)

if [ -z "$ALL_ITEMS" ]; then
    error_log "Failed to list items in vault: $VAULT"
    error_log "Please verify:"
    error_log "  1. Service account has access to vault '$VAULT'"
    error_log "  2. Vault name is correct"
    error_log "  3. Service account token is valid"
    exit 1
fi

debug_log "Retrieved $(echo "$ALL_ITEMS" | jq 'length') items from vault"

# Find items where the title matches the pattern "Claude API Key {repo-name} {date}"
ITEM_NAME_PATTERN="Claude API Key ${REPO_NAME}"
debug_log "Searching for items matching pattern: '$ITEM_NAME_PATTERN *'"

MATCHING_ITEMS=$(echo "$ALL_ITEMS" | jq -r --arg pattern "$ITEM_NAME_PATTERN" \
    '.[] | select(.title | startswith($pattern)) | .title' | sort -r)

if [ -z "$MATCHING_ITEMS" ]; then
    error_log "No API key found for repository: $REPO_NAME"
    error_log "Expected item name pattern: '$ITEM_NAME_PATTERN YYYYMMDD'"
    error_log "Vault: $VAULT"
    error_log ""
    error_log "To create an API key:"
    error_log "  1. Generate API key at https://console.anthropic.com"
    error_log "  2. Create item in 1Password vault '$VAULT' with:"
    error_log "     - Title: '$ITEM_NAME_PATTERN YYYYMMDD' (e.g., '$ITEM_NAME_PATTERN $(date +%Y%m%d)')"
    error_log "     - Field 'username': API key name"
    error_log "     - Field 'credential': The actual API key"
    error_log "     - Field 'repo': $REPO_NAME"
    error_log "     - Field 'valid from': Creation date"
    exit 1
fi

# Get the most recent item (first after reverse sort)
MOST_RECENT_ITEM=$(echo "$MATCHING_ITEMS" | head -n 1)
debug_log "Found $(echo "$MATCHING_ITEMS" | wc -l | tr -d ' ') matching item(s)"
info_log "Using API key: $MOST_RECENT_ITEM"

# Fetch the credential field from the item
debug_log "Fetching credential from item..."
API_KEY=$(op item get "$MOST_RECENT_ITEM" --vault "$VAULT" --fields label=credential --reveal 2>/dev/null)

if [ -z "$API_KEY" ]; then
    error_log "Failed to retrieve credential from item: $MOST_RECENT_ITEM"
    error_log "Please verify the item has a field labeled 'credential'"
    exit 1
fi

debug_log "Successfully retrieved API key (length: ${#API_KEY})"

# Strip quotes and newlines from API key
# The 1Password CLI sometimes wraps values in quotes, which breaks authentication
API_KEY=$(echo "$API_KEY" | tr -d '"\n\r ')

debug_log "After cleaning (length: ${#API_KEY})"

# Output the API key (this is what Claude Code will capture)
echo "$API_KEY"