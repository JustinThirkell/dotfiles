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

  # Extract the issue identifier (only take the first match)
  issue_id_from_branch="$(echo $current_branch | grep -o -E '[a-zA-Z]+-[0-9]+' | head -1)"
  [[ "$DEBUG" == "true" ]] && debug "Extracted issue_id_from_branch: $issue_id_from_branch"

  if [[ -z $issue_id_from_branch ]]; then
    error "No issue ID detected in branch name. Expected format: username/identifier-title (e.g. justin/86ew4x0vz-fix-the-bug)"
    info "Please use a branch with a valid issue identifier."
    return 1
  fi

  info "📝 Fetching issue details for $issue_id_from_branch using Linear CLI"

  # Get issue from Linear using our local linear function
  local issue
  issue=$(linear issue "$issue_id_from_branch")

  if [[ $? -ne 0 || -z "$issue" ]]; then
    error "Could not fetch issue details from Linear for issue ID: $issue_id_from_branch"
    info "Please check that the issue exists, the ID is correct, and that you have proper access."
    return 1
  fi

  debug "Received issue from SDK: $issue"

  # Sanitize JSON to handle any remaining control characters before jq parsing
  local sanitized_issue
  sanitized_issue=$(echo "$issue" | tr -d '\000-\037')

  # Extract all issue fields in a single jq call
  local title description url
  {
    read -r title
    read -r description
    read -r url
  } <<<"$(echo "$sanitized_issue" | jq -r '.title, .description, .url')"

  if [[ -z "$title" || "$title" == "null" ]]; then
    error "Could not extract issue title from Linear response for issue ID: $issue_id_from_branch"
    debug "Issue details JSON was: $issue"
    return 1
  fi

  info "Successfully fetched title for $issue_id_from_branch: '$title'"

  # Convert issue_id_from_branch to uppercase for PR title
  local id
  id=$(echo "$issue_id_from_branch" | tr '[:lower:]' '[:upper:]')
  [[ "$DEBUG" == "true" ]] && debug "id: $id"

  # Ensure the first letter of the issue title is capitalized
  local title_capitalized
  title_capitalized=$(echo "$title" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
  [[ "$DEBUG" == "true" ]] && debug "title_capitalized: $title_capitalized"

  # Format the PR title with uppercase issue ID and capitalized title
  pr_title="[$id] $title_capitalized"
  info "Generated PR title: $pr_title"

  # Generate PR description if LLM is not being skipped
  if [[ "$SKIP_LLM" != "true" ]]; then
    info "📝 Generating PR description (LLM step)"

    # Construct a more detailed issue context string for the LLM
    local linear_issue_context="Linear Issue ID: $id\nTitle: $title\nURL: $url\nDescription: $description"
    [[ "$DEBUG" == "true" ]] && debug "linear_issue_context for LLM: $linear_issue_context"

    local ollama_model="qwen3:8b"  # Gemma3
    [[ "$DEBUG" == "true" ]] && debug "ollama_model: $ollama_model"

    ollama_prompt="Based on the following git diff and the branch name '$current_branch', write a \
concise, informative, and detailed PR description that summarizes the changes. \
Here is the Linear issue context for this PR:\n\n${linear_issue_context}. \
\nUse sections that are correctly formatted markdown:\
# Purpose -> concise overview of why the PR has been created.  Try to use the issue title if available.\
## Context -> background information about the PR. USE issue context if available, particularly the issue description. 
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
  fi

  # Check if a PR already exists for the current branch
  existing_pr=$(gh pr view --json number,title,body)

  if [ $? -eq 0 ]; then
    # PR exists, update it
    # Sanitize the JSON output before passing it to jq to handle control characters
    sanitized_pr=$(echo "$existing_pr" | tr -d '\000-\037')
    pr_number=$(echo "$sanitized_pr" | jq -r .number)

    if [[ "$SKIP_LLM" == "true" ]]; then
      info "🔄 Updating existing PR #$pr_number (title only)"
      gh pr edit $pr_number --title "$pr_title"
    else
      info "🔄 Updating existing PR #$pr_number"
      gh pr edit $pr_number --title "$pr_title" --body "$pr_description"
    fi
    echo "🎉 Successfully updated PR"
  else
    # Create new PR
    if [[ "$SKIP_LLM" == "true" ]]; then
      info "🆕 Creating new PR (without description)"
      info "gh pr create --title \"$pr_title\" --web"
      gh pr create --title "$pr_title" --web
    else
      info "🆕 Creating new PR"
      gh pr create --title "$pr_title" --body "$pr_description" --web
    fi
    echo "🎉 Successfully created PR"
  fi
}
alias pr=git_pr
