cp_start_task() {
  # Default options
  local DEBUG=false
  local task_id=""

  # Process command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --debug)
      DEBUG=true
      shift
      ;;
    *)
      if [[ -z "$task_id" ]]; then
        task_id="$1"
      else
        error "Unknown option or multiple task IDs provided: $1"
        echo "Usage: cp_start_task <task-id> [--debug]"
        return 1
      fi
      shift
      ;;
    esac
  done

  [[ "$DEBUG" == "true" ]] && echo "Debug mode enabled"
  [[ "$DEBUG" == "true" ]] && debug "Task ID: $task_id"

  # Validate task ID is provided
  if [[ -z "$task_id" ]]; then
    error "Task ID is required"
    echo "Usage: cp_start_task <task-id> [--debug]"
    echo "Example: cp_start_task 86ew4x0vz"
    return 1
  fi

  # First, checkout the git branch
  info "📦 Checking out git branch for task $task_id"
  if [[ "$DEBUG" == "true" ]]; then
    git_checkout_task_branch "$task_id" --debug
  else
    git_checkout_task_branch "$task_id"
  fi

  local checkout_exit_code=$?

  if [[ $checkout_exit_code -ne 0 ]]; then
    error "Failed to checkout branch for task $task_id"
    return 1
  fi

  # Then, mark the task as in progress in ClickUp
  info "🚀 Marking task $task_id as IN PROGRESS in ClickUp"
  local start_result
  start_result=$(clickup start-task "$task_id" 2>&1)
  local start_exit_code=$?

  if [[ $start_exit_code -ne 0 ]]; then
    error "Failed to mark task $task_id as IN PROGRESS"
    [[ "$DEBUG" == "true" ]] && debug "start-task output: $start_result"
    info "Branch checkout was successful, but task status update failed."
    info "You may want to manually update the task status in ClickUp."
    return 1
  fi

  [[ "$DEBUG" == "true" ]] && debug "start-task result: $start_result"
  info "✅ Successfully marked task $task_id as IN PROGRESS"
  info "✅ Task $task_id is now ready for work!"
}

