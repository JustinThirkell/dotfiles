##############################################################################################
# Linear
##############################################################################################

# 1. Define the user-configurable path, error if not set.
# User should set LINEAR_SDK_WRAPPER_PATH in env or here.
: "${LINEAR_SDK_WRAPPER_PATH:-"Need to set LINEAR_SDK_WRAPPER_PATH in .zshrc.local"}"

# Check if the path is the default placeholder or an empty string, if so, exit silently.
if [[ "$LINEAR_SDK_WRAPPER_PATH" == "Need to set LINEAR_SDK_WRAPPER_PATH in .zshrc.local" || -z "$LINEAR_SDK_WRAPPER_PATH" ]]; then
  return 1 # Stop sourcing .zfunctions if the path isn't properly set or is empty.
fi

# 2. Expand tilde (if any) and prepare the path for internal use.
# Functions will use _INTERNAL_EXPANDED_LINEAR_SDK_PATH.
_INTERNAL_EXPANDED_LINEAR_SDK_PATH="${LINEAR_SDK_WRAPPER_PATH/#\~/$HOME}"

# 3. Verify the script exists at the expanded path.
if [[ ! -f "$_INTERNAL_EXPANDED_LINEAR_SDK_PATH" ]]; then
  printf "\r\033[2K  [\033[0;31mFAIL\033[0m] %s\n" "Error: Linear SDK wrapper script not found at '$_INTERNAL_EXPANDED_LINEAR_SDK_PATH'" >&2
  printf "\r  [ \033[00;34m..\033[0m ] %s\n" "(Checked path was derived from LINEAR_SDK_WRAPPER_PATH: '$LINEAR_SDK_WRAPPER_PATH')" >&2
  return 1 # Stop sourcing .zfunctions
fi

# Ensure API key is available
: "${LINEAR_API_KEY:-"Need to set LINEAR_API_KEY in .zshrc.local"}"

# Define Linear IDs - some of these will cause an error if not set
LINEAR_DEFAULT_TEAM_ID="${LINEAR_DEFAULT_TEAM_ID:-"Need to set LINEAR_DEFAULT_TEAM_ID in .zshrc.local"}"
LINEAR_TEST_TEAM_ID="${LINEAR_TEST_TEAM_ID:-}"                                                                                                                     # Optional, kept as is
LINEAR_DEFAULT_PROJECT_ID="${LINEAR_DEFAULT_PROJECT_ID:-"Need to set LINEAR_DEFAULT_PROJECT_ID in .zshrc.local"}" # Now Mandatory
LINEAR_TEST_PROJECT_ID="${LINEAR_TEST_PROJECT_ID:-}"                                                                                                               # Optional
LINEAR_ADHOC_LABEL_ID="${LINEAR_ADHOC_LABEL_ID:-"Need to set LINEAR_ADHOC_LABEL_ID in .zshrc.local"}"             # Kept as Mandatory
LINEAR_USER_ID="${LINEAR_USER_ID:-"Need to set LINEAR_USER_ID in .zshrc.local"}"          # Now Mandatory

# Helper function to get issue details from Linear API using Node.js SDK wrapper
sdk_linear_get_issue() {

  local issue_identifier="$1"

  if [[ -z "$issue_identifier" ]]; then
    error "Issue identifier is required for sdk_linear_get_issue."
    return 1
  fi

  info "SDK: Fetching details for Linear issue: $issue_identifier"

  local response
  # Use the globally defined, expanded, and validated path
  response=$(node "${_INTERNAL_EXPANDED_LINEAR_SDK_PATH}" get-issue --id "$issue_identifier" 2>&1)
  local node_exit_code=$?

  if [[ $node_exit_code -ne 0 ]]; then
    error "SDK Node script failed for get-issue $issue_identifier with exit code $node_exit_code."
    error "SDK Node script output: $response"
    return 1
  fi

  # Use jq -Rrs 'fromjson | ...' to handle potential control characters in $response
  if jq -Rrs 'fromjson | .error // null' <<<"$response" | grep -qv "null"; then
    error "SDK Node script reported an error for get-issue $issue_identifier:"
    jq -Rrs 'fromjson | .error' <<<"$response" >&2
    return 1
  fi

  if ! jq -Rrs 'fromjson | .' <<<"$response" >/dev/null 2>&1 || [[ "$response" == "null" ]] || [[ -z "$response" ]]; then
    error "SDK Node script for get-issue $issue_identifier returned invalid or empty JSON."
    debug "Raw response was: $response"
    return 1
  fi

  debug "SDK: Successfully fetched details for $issue_identifier."
  # Output the valid JSON, which jq has now parsed and can re-serialize cleanly if needed by caller
  jq -Rrs 'fromjson | .' <<<"$response"
}

# Helper function to create a Linear issue using Node.js SDK wrapper
sdk_linear_create_issue() {
  # Ensure API key is available (already checked at top, but kept for robustness if functions are moved/isolated)
  : "${LINEAR_API_KEY:?Error: LINEAR_API_KEY is not set. Please ensure it is defined in your environment.}"
  # Ensure Node wrapper script path is set (already checked at top)
  : "${_INTERNAL_EXPANDED_LINEAR_SDK_PATH:?Error: _INTERNAL_EXPANDED_LINEAR_SDK_PATH is not set or script not found.}"

  local title="$1"
  local team_id="$2"
  local description="${3:-}"   # Optional
  local project_id="${4:-}"    # Optional
  local label_ids_str="${5:-}" # Optional, comma-separated string
  local assignee_id="${6:-}"   # Optional

  if [[ -z "$title" || -z "$team_id" ]]; then
    error "Title and Team ID are required for sdk_linear_create_issue."
    return 1
  fi

  # Use the globally defined, expanded, and validated path
  local args=("${_INTERNAL_EXPANDED_LINEAR_SDK_PATH}" "create-issue" "--title" "$title" "--teamId" "$team_id")

  if [[ -n "$description" ]]; then
    args+=("--description" "$description")
  fi
  if [[ -n "$project_id" ]]; then
    args+=("--projectId" "$project_id")
  fi
  if [[ -n "$label_ids_str" ]]; then
    args+=("--labelIds" "$label_ids_str") # Wrapper script handles comma-separated string
  fi
  if [[ -n "$assignee_id" ]]; then
    args+=("--assigneeId" "$assignee_id")
  fi

  info "SDK: Creating Linear issue titled '$title' in team $team_id"
  debug "SDK: Node script args: ${args[*]}"

  local response
  response=$(node "${args[@]}" 2>&1)
  local node_exit_code=$?

  if [[ $node_exit_code -ne 0 ]]; then
    error "SDK Node script failed for create-issue with exit code $node_exit_code."
    error "SDK Node script output: $response"
    return 1
  fi

  # Use jq -Rrs 'fromjson | ...' to handle potential control characters
  if jq -Rrs 'fromjson | .error // null' <<<"$response" | grep -qv "null"; then
    error "SDK Node script reported an error for create-issue:"
    jq -Rrs 'fromjson | .error' <<<"$response" >&2
    return 1
  fi

  if ! jq -Rrs 'fromjson | .id // null' <<<"$response" | grep -qv "null"; then # Check for .id as success indicator
    error "SDK Node script for create-issue returned invalid JSON or did not include an issue ID."
    debug "Raw response was: $response"
    return 1
  fi

  local created_issue_id
  created_issue_id=$(jq -Rrs 'fromjson | .id' <<<"$response")
  local created_issue_identifier
  created_issue_identifier=$(jq -Rrs 'fromjson | .identifier' <<<"$response")

  info "SDK: Successfully created Linear issue: $created_issue_identifier ($created_issue_id)"
  debug "SDK: Full creation response JSON:"
  debug "$(jq -Rrs 'fromjson | .' <<<"$response")" # Pretty print for debug
  jq -Rrs 'fromjson | .' <<<"$response"            # Output the full JSON of the created issue
}

create_adhoc_issue_and_branch() {

  local title="$1"
  local description="${2:-Generated by create_adhoc_issue_and_branch}" # Optional description, with a default
  # Team ID, Project ID, Label ID, and Assignee ID will come from global vars or sensible defaults

  if [[ -z "$title" ]]; then
    error "Issue title is required for create_adhoc_issue_and_branch."
    echo 'Usage: create_adhoc_issue_and_branch "<title>" ["<description>"]' >&2
    return 1
  fi

  info "Creating adhoc Linear issue: $title"

  # Use global LINEAR_DEFAULT_TEAM_ID, LINEAR_ADHOC_LABEL_ID.
  # Optionally use LINEAR_DEFAULT_PROJECT_ID if set.
  # Optionally use LINEAR_USER_ID for assignee if set.
  local created_issue_json
  created_issue_json=$(
    sdk_linear_create_issue \
      "$title" \
      "$LINEAR_DEFAULT_TEAM_ID" \
      "$description" \
      "${LINEAR_DEFAULT_PROJECT_ID:-}" \
      "$LINEAR_ADHOC_LABEL_ID" \
      "${LINEAR_USER_ID:-}"
  )

  if [[ $? -ne 0 || -z "$created_issue_json" ]]; then
    error "Failed to create adhoc Linear issue via SDK."
    # sdk_linear_create_issue should have logged details
    return 1
  fi

  local issue_identifier issue_id issue_branch_name_from_api
  issue_identifier=$(echo "$created_issue_json" | jq -r '.identifier')
  issue_id=$(echo "$created_issue_json" | jq -r '.id')                           # UUID
  issue_branch_name_from_api=$(echo "$created_issue_json" | jq -r '.branchName') # Usually includes user/IDENTIFIER-title

  if [[ -z "$issue_identifier" || "$issue_identifier" == "null" ]]; then
    error "Failed to extract identifier from created adhoc issue."
    debug "SDK Create issue response: $created_issue_json"
    return 1
  fi

  info "SDK: Successfully created adhoc Linear issue: $issue_identifier ($issue_id)"

  # Construct the branch name: username/identifier-short-title
  local user_git_config_raw
  user_git_config_raw=$(git config user.name)
  local user_git_name_processed # try to get 'justin' from 'Justin Tung' or 'justin.tung' etc.
  user_git_name_processed=$(echo "$user_git_config_raw" | awk '{print $1}' | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9].*//')
  [[ -z "$user_git_name_processed" ]] && user_git_name_processed="user" # Fallback

  # Sanitize title for branch name (lowercase, alphanumeric, hyphens, limited length)
  local short_title
  short_title=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr -cs '[:alnum:]' '-' | sed -e 's/--+/-/g' -e 's/^-//' -e 's/-$//' | cut -c1-50)

  local branch_name="${user_git_name_processed}/${issue_identifier}-${short_title}"

  # Fallback to API suggested branchName if our construction is problematic (e.g. empty)
  if [[ -z "$branch_name" || "$branch_name" == "${user_git_name_processed}/-" || "$branch_name" == "${user_git_name_processed}/${issue_identifier}-" ]]; then
    if [[ -n "$issue_branch_name_from_api" && "$issue_branch_name_from_api" != "null" ]]; then
      info "Using API suggested branch name: $issue_branch_name_from_api"
      branch_name="$issue_branch_name_from_api"
    else
      error "Could not construct a valid branch name, and API did not provide one."
      return 1
    fi
  fi

  info "Attempting to create and checkout new branch: $branch_name"
  if git checkout -b "$branch_name"; then
    info "Switched to new branch: $branch_name"
    info "You can now start working on issue $issue_identifier. URL: $(echo "$created_issue_json" | jq -r '.url')"
  else
    error "Failed to create or checkout branch $branch_name."
    # Check if branch already exists, perhaps from a previous attempt or API suggestion
    if git rev-parse --verify "$branch_name" >/dev/null 2>&1; then
      info "Branch '$branch_name' already exists. Attempting to switch to it."
      if git checkout "$branch_name"; then
        info "Successfully switched to existing branch '$branch_name'."
      else
        error "Failed to switch to existing branch '$branch_name'."
        return 1
      fi
    else
      return 1
    fi
  fi
}
alias adhoc='create_adhoc_issue_and_branch'
