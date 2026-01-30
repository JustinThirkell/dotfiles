cp_new_task() {
  local title=""
  local description=""
  local DEBUG=false

  while [[ $# -gt 0 ]]; do
    case "$1" in
    --debug)
      DEBUG=true
      shift
      ;;
    *)
      if [[ -z "$title" ]]; then
        title="$1"
      elif [[ -z "$description" ]]; then
        description="$1"
      else
        error "Unknown option or too many arguments: $1"
        echo "Usage: cp_new_task <title> <description> [--debug]"
        return 1
      fi
      shift
      ;;
    esac
  done

  if [[ -z "$title" ]]; then
    error "Title is required"
    echo "Usage: cp_new_task <title> <description> [--debug]"
    echo "Example: cp_new_task \"Fix login bug\" \"Description of the fix\""
    return 1
  fi

  if [[ -z "$description" ]]; then
    error "Description is required"
    echo "Usage: cp_new_task <title> <description> [--debug]"
    return 1
  fi

  # Create new ClickUp task with title and description
  info "📝 Creating ClickUp task: $title"
  local create_result
  create_result=$(clickup create-task "$title" "$description")
  local create_exit=$?

  if [[ $create_exit -ne 0 ]]; then
    error "Failed to create ClickUp task"
    return 1
  fi

  [[ "$DEBUG" == "true" ]] && debug "Raw create-task output: $create_result"

  local sanitized_result
  sanitized_result=$(echo "$create_result" | tr -d '\000-\037')
  local task_id
  task_id=$(echo "$sanitized_result" | jq -r '.id')

  if [[ -z "$task_id" || "$task_id" == "null" ]]; then
    error "Could not extract task ID from create-task response"
    echo "Raw output was:" >&2
    echo "$create_result" >&2
    return 1
  fi

  # Copy task ID to clipboard
  echo -n "$task_id" | pbcopy

  info "✅ Created ClickUp task: $task_id (copied to clipboard)"
  info "💡 Run: cp_start_task $task_id"
}

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
    echo "Example: cp_start_task https://app.clickup.com/t/86ewdbtbh"
    return 1
  fi

  # If task_id looks like a ClickUp URL, extract the task ID
  if [[ "$task_id" == *"/t/"* ]]; then
    local resolved_id
    resolved_id=$(clickup_infer-task-id "$task_id")
    if [[ -z "$resolved_id" ]]; then
      error "Could not extract task ID from URL: $task_id"
      return 1
    fi
    [[ "$DEBUG" == "true" ]] && debug "Resolved URL to task ID: $resolved_id"
    task_id="$resolved_id"
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

cp_pr_task() {
  # Default options
  local DEBUG=false

  # Process command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --debug)
      DEBUG=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: cp_pr_task [--debug]"
      return 1
      ;;
    esac
  done

  [[ "$DEBUG" == "true" ]] && echo "Debug mode enabled"

  # Get current branch name
  local current_branch
  current_branch=$(git branch --show-current)

  if [[ -z "$current_branch" ]]; then
    error "Not on a git branch"
    return 1
  fi

  # Extract the task ID from branch using git_infer_task_id function
  local task_id
  task_id=$(git_infer_task_id "$current_branch" "$DEBUG")

  if [[ -z "$task_id" ]]; then
    error "Failed to extract task ID from branch name"
    return 1
  fi

  [[ "$DEBUG" == "true" ]] && debug "Extracted task ID from branch: $task_id"

  # First, create/update the PR
  info "📝 Creating/updating PR for task $task_id"
  if [[ "$DEBUG" == "true" ]]; then
    git_pr_task_branch --debug
  else
    git_pr_task_branch
  fi

  local pr_exit_code=$?

  if [[ $pr_exit_code -ne 0 ]]; then
    error "Failed to create/update PR for task $task_id"
    return 1
  fi

  # Then, mark the task as in review in ClickUp
  info "🚀 Marking task $task_id as IN REVIEW in ClickUp"
  local pr_task_result
  pr_task_result=$(clickup pr-task "$task_id" 2>&1)
  local pr_task_exit_code=$?

  if [[ $pr_task_exit_code -ne 0 ]]; then
    error "Failed to mark task $task_id as IN REVIEW"
    [[ "$DEBUG" == "true" ]] && debug "pr-task output: $pr_task_result"
    info "PR creation/update was successful, but task status update failed."
    info "You may want to manually update the task status in ClickUp."
    return 1
  fi

  [[ "$DEBUG" == "true" ]] && debug "pr-task result: $pr_task_result"
  info "✅ Successfully marked task $task_id as IN REVIEW"
  info "✅ PR created/updated and task $task_id is now in review!"
}

alias pr=cp_pr_task
