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
    echo "  get-task <task-id>              - Get detailed info for a task"
    echo "  start-task <task-id>            - Update task status to \"IN PROGRESS\""
    echo "  pr-task <task-id>               - Update task status to \"IN REVIEW\""
    echo ""
    echo "Examples:"
    echo "  clickup get-task 86ew4x0vz"
    echo "  clickup get-task 86ew4x0vz --debug"
    echo "  clickup start-task 86ew4x0vz"
    echo "  clickup pr-task 86ew4x0vz"
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
clickup_get-task() {
  clickup get-task "$@"
}

clickup_start-task() {
  clickup start-task "$@"
}

clickup_pr-task() {
  clickup pr-task "$@"
}

