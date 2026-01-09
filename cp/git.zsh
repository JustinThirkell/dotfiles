# branch format is username/identifier-title
# Example: justin/86ew4x0vz-fix-the-bug
# PR title should be: "[86ew4x0vz] "Fix the bug"

git_checkout_task_branch() {
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
        echo "Usage: git_checkout_task_branch <task-id> [--debug]"
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
    echo "Usage: git_checkout_task_branch <task-id> [--debug]"
    echo "Example: git_checkout_task_branch 86ew4x0vz"
    return 1
  fi

  info "📝 Fetching task details for $task_id using ClickUp CLI"

  # Get task from ClickUp using our local clickup function
  local task
  task=$(clickup get-task "$task_id")

  if [[ $? -ne 0 || -z "$task" ]]; then
    error "Could not fetch task details from ClickUp for task ID: $task_id"
    info "Please check that the task exists, the ID is correct, and that you have proper access."
    return 1
  fi

  [[ "$DEBUG" == "true" ]] && debug "Received task from ClickUp: $task"

  # Sanitize JSON to handle any remaining control characters before jq parsing
  local sanitized_task
  sanitized_task=$(echo "$task" | tr -d '\000-\037')
  [[ "$DEBUG" == "true" ]] && debug "Sanitized task JSON"

  # Extract task name using jq
  local task_name
  task_name=$(echo "$sanitized_task" | jq -r '.name')

  if [[ -z "$task_name" || "$task_name" == "null" ]]; then
    error "Could not extract task name from ClickUp response for task ID: $task_id"
    [[ "$DEBUG" == "true" ]] && debug "Task details JSON was: $task"
    return 1
  fi

  info "Successfully fetched task name for $task_id: '$task_name'"
  [[ "$DEBUG" == "true" ]] && debug "Raw task name: $task_name"

  # Convert task name to branch-safe format:
  # - Convert to lowercase
  # - Replace spaces and special characters with dashes
  # - Collapse multiple consecutive dashes
  # - Remove leading/trailing dashes
  local branch_name_slug
  branch_name_slug=$(echo "$task_name" | \
    tr '[:upper:]' '[:lower:]' | \
    sed 's/[^a-z0-9]/-/g' | \
    sed 's/-\+/-/g' | \
    sed 's/^-\|-$//g')

  [[ "$DEBUG" == "true" ]] && debug "Branch name slug: $branch_name_slug"

  # Construct branch name: justin/{taskid}-{slug}
  local username="justin"
  local branch_name="${username}/${task_id}-${branch_name_slug}"

  info "Constructed branch name: $branch_name"
  [[ "$DEBUG" == "true" ]] && debug "Full branch name: $branch_name"

  # Check if branch already exists
  if git show-ref --verify --quiet refs/heads/"$branch_name"; then
    info "Branch $branch_name already exists, checking it out"
    git checkout "$branch_name"
    if [[ $? -ne 0 ]]; then
      error "Failed to checkout existing branch: $branch_name"
      return 1
    fi
    info "✅ Successfully checked out branch: $branch_name"
  else
    info "Creating and checking out new branch: $branch_name"
    git checkout -b "$branch_name"
    if [[ $? -ne 0 ]]; then
      error "Failed to create and checkout branch: $branch_name"
      info "This might be due to uncommitted changes or other git issues."
      return 1
    fi
    info "✅ Successfully created and checked out branch: $branch_name"
  fi
}

git_pr() {

  # Default options
  local SKIP_LLM=true
  local DEBUG=false

  # Process command line arguments
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --skip-llm)
      SKIP_LLM=true
      shift
      ;;
    --debug)
      DEBUG=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: git_pr [--skip-llm] [--debug]"
      return 1
      ;;
    esac
  done

  [[ "$DEBUG" == "true" ]] && echo "Debug mode enabled"
  [[ "$SKIP_LLM" == "true" ]] && echo "Skipping LLM description generation"

  # Check if upstream is already set for the current branch
  current_branch=$(git branch --show-current)
  if ! git rev-parse --abbrev-ref --symbolic-full-name @{upstream} &>/dev/null; then
    # No upstream set, so push with -u to set it
    echo "Setting upstream for branch $current_branch"
    git push --set-upstream origin $current_branch
  else
    # Upstream already configured, just push
    echo "Pushing changes to remote"
    git push
  fi

  # Get current branch name using zsh git alias
  branch=$(git branch --show-current)
  [[ "$DEBUG" == "true" ]] && echo "branch: $branch"

  # Extract the task ID from branch format: username/{taskid}-{slug}
  # Example: justin/86ew4x0vz-update-canvas-dependency -> 86ew4x0vz
  task_id_from_branch=$(echo "$current_branch" | sed 's|.*/||' | sed 's/-.*//')
  [[ "$DEBUG" == "true" ]] && debug "Extracted task_id_from_branch: $task_id_from_branch"

  if [[ -z $task_id_from_branch ]]; then
    error "No task ID detected in branch name. Expected format: username/{taskid}-{slug} (e.g. justin/86ew4x0vz-fix-the-bug)"
    info "Please use a branch with a valid task identifier."
    return 1
  fi

  info "📝 Fetching task details for $task_id_from_branch using ClickUp CLI"

  # Get task from ClickUp using our local clickup function
  local task
  task=$(clickup get-task "$task_id_from_branch")

  if [[ $? -ne 0 || -z "$task" ]]; then
    error "Could not fetch task details from ClickUp for task ID: $task_id_from_branch"
    info "Please check that the task exists, the ID is correct, and that you have proper access."
    return 1
  fi

  [[ "$DEBUG" == "true" ]] && debug "Received task from ClickUp: $task"

  # Sanitize JSON to handle any remaining control characters before jq parsing
  local sanitized_task
  sanitized_task=$(echo "$task" | tr -d '\000-\037')

  # Extract all task fields in a single jq call
  local task_name task_description task_url
  {
    read -r task_name
    read -r task_description
    read -r task_url
  } <<<"$(echo "$sanitized_task" | jq -r '.name, (.text_content // ""), .url')"

  if [[ -z "$task_name" || "$task_name" == "null" ]]; then
    error "Could not extract task name from ClickUp response for task ID: $task_id_from_branch"
    [[ "$DEBUG" == "true" ]] && debug "Task details JSON was: $task"
    return 1
  fi

  info "Successfully fetched task name for $task_id_from_branch: '$task_name'"

  # Keep task ID in lowercase (no uppercase conversion)
  local id
  id="$task_id_from_branch"
  [[ "$DEBUG" == "true" ]] && debug "id: $id"

  # Ensure the first letter of the task title is capitalized
  local title_capitalized
  title_capitalized=$(echo "$task_name" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
  [[ "$DEBUG" == "true" ]] && debug "title_capitalized: $title_capitalized"

  # Format the PR title with lowercase task ID and capitalized title
  pr_title="[$id] $title_capitalized"
  info "Generated PR title: $pr_title"

  # Generate PR description if LLM is not being skipped
  if [[ "$SKIP_LLM" != "true" ]]; then
    info "📝 Generating PR description (LLM step)"

    # Construct a more detailed task context string for the LLM
    local clickup_task_context="ClickUp Task ID: $id\nTitle: $task_name\nURL: $task_url\nDescription: $task_description"
    [[ "$DEBUG" == "true" ]] && debug "clickup_task_context for LLM: $clickup_task_context"

    local ollama_model="qwen3:8b"  # Gemma3
    [[ "$DEBUG" == "true" ]] && debug "ollama_model: $ollama_model"

    ollama_prompt="Based on the following git diff and the branch name '$current_branch', write a \
concise, informative, and detailed PR description that summarizes the changes. \
Here is the ClickUp task context for this PR:\n\n${clickup_task_context}. \
\nUse sections that are correctly formatted markdown:\
# Purpose -> concise overview of why the PR has been created.  Try to use the task title if available.\
## Context -> background information about the PR. USE task context if available, particularly the task description. 
\nUse line breaks to ensure they are correctly formatted markdown. \
Do not use emojis. \
At the end, include a note in italics stating that this summary was written by an LLM, and to tag Justin if you're not happy with it. \
Only return the PR description, don't return anything else."

    if [[ "$DEBUG" == "true" ]]; then
      debug "🔍 Here's the prompt that will be given to Ollama:"
      debug "-------------------------------------------------"
      debug "$ollama_prompt"
      debug "-------------------------------------------------"
    fi

    info "⏳ Now running Ollama... (this might take a while)"

    raw_description=$(git diff main | ollama run $ollama_model "$ollama_prompt" | sed "s/\"//g")
    [[ "$DEBUG" == "true" ]] && debug "raw_description: $raw_description"

    if [[ "$DEBUG" == "true" ]]; then
      debug "📄 Raw PR description before removing think tags:"
      debug "$raw_description"
      debug "----------------------------------------"
    fi

    info "🔍 Removing <think> tags"

    # Clean and escape the PR description
    pr_description=$(echo "$raw_description" |
      perl -0777 -pe 's/<think>.*?<\/think>//gs')

    info "🧹 Removing LLM output footer"
    # Remove the output footer that sometimes appears in LLM responses
    pr_description=$(echo "$pr_description" |
      perl -0777 -pe 's/\n\n---\n\n\*Note: This PR description is concise.*?instructions\.\*//gs')
  else
    info "⏭️ Skipping PR description generation (--skip-llm flag set)"
    # Create simple PR description with ClickUp task link and description
    if [[ -n "$task_url" && "$task_url" != "null" ]]; then
      if [[ -n "$task_description" && "$task_description" != "null" && "$task_description" != "" ]]; then
        pr_description="[ClickUp task]($task_url)

$task_description"
      else
        pr_description="[ClickUp task]($task_url)"
      fi
    else
      pr_description=""
    fi
    [[ "$DEBUG" == "true" ]] && debug "Generated PR description: $pr_description"
  fi

  # Check if a PR already exists for the current branch
  existing_pr=$(gh pr view --json number,title,body)

  if [ $? -eq 0 ]; then
    # PR exists, update it
    # Sanitize the JSON output before passing it to jq to handle control characters
    sanitized_pr=$(echo "$existing_pr" | tr -d '\000-\037')
    pr_number=$(echo "$sanitized_pr" | jq -r .number)

    if [[ "$SKIP_LLM" == "true" ]]; then
      if [[ -n "$pr_description" && "$pr_description" != "" ]]; then
        info "🔄 Updating existing PR #$pr_number"
        gh pr edit $pr_number --title "$pr_title" --body "$pr_description"
      else
        info "🔄 Updating existing PR #$pr_number (title only)"
        gh pr edit $pr_number --title "$pr_title"
      fi
    else
      info "🔄 Updating existing PR #$pr_number"
      gh pr edit $pr_number --title "$pr_title" --body "$pr_description"
    fi
    echo "🎉 Successfully updated PR"
  else
    # Create new PR
    if [[ "$SKIP_LLM" == "true" ]]; then
      if [[ -n "$pr_description" && "$pr_description" != "" ]]; then
        info "🆕 Creating new PR (with description)"
        gh pr create --title "$pr_title" --body "$pr_description" --web
      else
        info "🆕 Creating new PR (without description)"
        info "gh pr create --title \"$pr_title\" --web"
        gh pr create --title "$pr_title" --web
      fi
    else
      info "🆕 Creating new PR"
      gh pr create --title "$pr_title" --body "$pr_description" --web
    fi
    echo "🎉 Successfully created PR"
  fi
}
alias pr=git_pr
