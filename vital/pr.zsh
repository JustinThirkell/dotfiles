git_pr() {
  # branch format is username/identifier-title, per https://vital-software.slack.com/archives/C0129SCDG6M/p1741743391470719?thread_ts=1741149220.086069&cid=C0129SCDG6M
  # Example: justint/jt-32-foo
  # PR title should be: [JT-32] "Issue title"

  # Default options
  local SKIP_LLM=false
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
    error "No issue ID detected in branch name. Expected format: username/identifier-title (e.g., jt-32 or feature/jt-32-some-title)"
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

    ollama_prompt="Based on the following git diff and the branch name '$current_branch', write a \
concise, informative, and detailed PR description that summarizes the changes. \
Here is the Linear issue context for this PR:\n\n${linear_issue_context}. \
\nUse sections that are correctly formatted markdown:\
# Purpose -> concise overview of why the PR has been created.  Try to use the issue title if available.\
## Context -> background information about the PR. USE issue context if available, particularly the issue description. \
# Approach -> how the PR achieves the goal. IMPORTANT: in this section, only mention files that actually appear in the git diff. DO NOT invent or fabricate any file names. First EXTRACT the exact file names from the git diff, then only reference those specific files. If you're unsure about a file name, do not mention it at all. DOUBLE CHECK that each file you mention is present in the git diff before including it. If you list file names, use EXACT file paths from the git diff, not made-up ones or shortened versions. If no files are modified in the git diff, then describe the changes without referencing specific files. \
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

    raw_description=$(git diff main | ollama run gemma3 "$ollama_prompt" | sed "s/\"//g")
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

# Function to set up git worktree and open Cursor IDE for PR review
pr_review_worktree() {
  if [ -z "$1" ]; then
    error "Error: Branch name required"
    error "Usage: pr-review <branch-name>"
    return 1
  fi

  local branch_name="$1"
  local worktree_path=$VITAL_DIR/katoa.worktrees/$branch_name

  # Check if worktree already exists
  if [ -d "$worktree_path" ]; then
    error "Error: Worktree directory already exists at $worktree_path"
    return 1
  fi

  # Add the worktree using the origin remote branch
  git worktree add -b $branch_name "$worktree_path" "origin/$branch_name"

  if [ $? -eq 0 ]; then
    # Open Cursor IDE
    cursor $worktree_path

    info "Successfully set up worktree at $worktree_path"
  else
    error "Error: Failed to create git worktree"
    return 1
  fi
}
alias review='pr_review_worktree'
