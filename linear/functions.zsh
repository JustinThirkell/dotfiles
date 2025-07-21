##############################################################################################
# Linear CLI Wrapper
##############################################################################################

# Path to the linear.ts script (relative to this file)
_LINEAR_SCRIPT_PATH="${0:A:h}/linear.ts"

# Main linear function that dispatches to subcommands
linear() {
  if [[ $# -eq 0 ]]; then
    echo "Usage: linear <command> [options]"
    echo ""
    echo "Available commands:"
    echo "  teams                              - List teams you're a member of"
    echo "  teams --all                        - List all teams"
    echo "  projects                           - List all projects"
    echo "  projects --teamId <id>             - List projects for a specific team"
    echo "  issues --teamId <id>               - List open issues in a team"
    echo "  issues --projectId <id>            - List open issues in a project"
    echo "  issue <identifier>                 - Get detailed info for an issue"
    echo "  me                                 - Get current user info and teams"
    echo "  set-userId                         - Set your Linear user ID in zshrc.local"
    echo ""
    echo "Examples:"
    echo "  linear me"
    echo "  linear teams"
    echo "  linear issue VIT-364"
    echo "  linear issues --teamId abc123"
    echo "  linear issues --projectId def456"
    return 1
  fi

  # Check if linear.ts exists
  if [[ ! -f "$_LINEAR_SCRIPT_PATH" ]]; then
    echo "Error: Linear script not found at $_LINEAR_SCRIPT_PATH" >&2
    return 1
  fi

  # Pass all arguments directly to the linear.ts script
  npx tsx "$_LINEAR_SCRIPT_PATH" "$@"
}

# Individual command functions for tab completion and direct access
linear_teams() {
  linear teams "$@"
}

linear_projects() {
  linear projects "$@"
}

linear_issues() {
  linear issues "$@"
}

linear_issue() {
  linear issue "$@"
}

linear_me() {
  linear me "$@"
}

linear_set-userId() {
  linear set-userId "$@"
}

# Convenience aliases
alias lg='linear_issue'
alias lme='linear_me'
alias lteams='linear_teams'
alias lprojects='linear_projects'
alias lissues='linear_issues'

# Helper function to get branch name and checkout
linear_checkout() {
  local issue_identifier="$1"

  if [[ -z "$issue_identifier" ]]; then
    echo "Usage: linear_checkout <issue-identifier>"
    echo "Example: linear_checkout VIT-364"
    return 1
  fi

  echo "Getting issue details for $issue_identifier..."
  local issue_response
  issue_response=$(linear issue "$issue_identifier")

  if [[ $? -ne 0 ]]; then
    echo "Failed to get issue details for $issue_identifier" >&2
    return 1
  fi

  local branch_name
  branch_name=$(echo "$issue_response" | jq -r '.branchName')

  if [[ -z "$branch_name" || "$branch_name" == "null" ]]; then
    echo "No branch name found for issue $issue_identifier" >&2
    return 1
  fi

  echo "Checking out branch: $branch_name"
  git checkout "$branch_name"
}

alias lco='linear_checkout'

# Tab completion for linear commands
if [[ -n "$ZSH_VERSION" ]]; then
  _linear_commands=(
    'teams:List teams you are a member of'
    'projects:List all projects'
    'issues:List open issues'
    'issue:Get detailed info for an issue'
    'me:Get current user info and teams'
    'set-userId:Set your Linear user ID'
  )

  _linear() {
    local context state line

    _arguments -C \
      "1: :->commands" \
      "*::arg:->args"

    case $state in
    commands)
      _describe 'linear command' _linear_commands
      ;;
    args)
      case $line[1] in
      issue)
        _message 'issue identifier (e.g., VIT-364)'
        ;;
      issues)
        _arguments \
          '--teamId[Team ID]:team id:' \
          '--projectId[Project ID]:project id:'
        ;;
      projects)
        _arguments '--teamId[Team ID]:team id:'
        ;;
      teams)
        _arguments '--all[Show all teams]'
        ;;
      esac
      ;;
    esac
  }

  compdef _linear linear
fi
