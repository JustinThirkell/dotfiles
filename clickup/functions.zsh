##############################################################################################
# ClickUp CLI Wrapper
##############################################################################################

# Path to the clickup.ts script (relative to this file)
_CLICKUP_SCRIPT_PATH="${0:A:h}/clickup.ts"

# Main clickup function that dispatches to subcommands
clickup() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: clickup <command> [options]"
    echo ""
    echo "Available commands:"
    echo "  issue <task-id>                 - Get detailed info for an issue"
    echo ""
    echo "Examples:"
    echo "  clickup issue 86ew4x0vz"
    echo "  clickup issue 86ew4x0vz --debug"
    return 1
  fi

  # Check if clickup.ts exists
  if [[ ! -f "$_CLICKUP_SCRIPT_PATH" ]]; then
    echo "Error: ClickUp script not found at $_CLICKUP_SCRIPT_PATH" >&2
    return 1
  fi

  # Pass all arguments directly to the clickup.ts script
  npx tsx "$_CLICKUP_SCRIPT_PATH" "$@"
}

# Individual command functions for direct access
clickup_issue() {
  clickup issue "$@"
}

