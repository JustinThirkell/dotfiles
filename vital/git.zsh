# Branch prefix for issue branches (now sourced from environment)
# ISSUE_BRANCH_PREFIX is set in zshrc.local.symlink

# Function for checking out justint/clp branches
function git-checkout-issue-branch() {
  # Alias provided through the alias definition below
  local branches
  branches=($(git branch | grep -oE "$ISSUE_BRANCH_PREFIX-[0-9]+-[a-zA-Z0-9-]+" | sort))

  if [[ $# -eq 0 ]]; then
    if [[ ${#branches[@]} -eq 0 ]]; then
      echo "No $ISSUE_BRANCH_PREFIX branches found."
      return 1
    fi

    echo "Available issue branches:"
    for branch in "${branches[@]}"; do
      echo "  $branch"
    done
    return 0
  fi

  local branch_pattern="$1"
  local matching_branches=()

  for branch in "${branches[@]}"; do
    if [[ "$branch" == *"$branch_pattern"* ]]; then
      matching_branches+=("$branch")
    fi
  done

  if [[ ${#matching_branches[@]} -eq 0 ]]; then
    echo "No branches matching '$branch_pattern' found."
    return 1
  elif [[ ${#matching_branches[@]} -eq 1 ]]; then
    echo "Checking out ${matching_branches[0]}"
    git checkout "${matching_branches[0]}"
  else
    echo "Multiple matches found. Please be more specific:"
    for branch in "${matching_branches[@]}"; do
      echo "  $branch"
    done
    return 1
  fi
}

# Set column format
zstyle ':completion:*:git-checkout-issue-branch:*' format '%B%F{blue}Issue Branches:%f%b'
zstyle ':completion:*:git-checkout-issue-branch:*' list-rows-first false
zstyle ':completion:*:git-checkout-issue-branch:*' list-packed false
zstyle ':completion:*:gcoi:*' list-rows-first false
zstyle ':completion:*:gcoi:*' list-packed false

# Add tab completion for the function
# Customizes tab completion to only show local branches that:
#   Start with "justint/clp"
#   Or are named "main"
_git_checkout_issue_branch_complete() {
  local branches
  # Use git for-each-ref for more reliable branch name parsing
  branches=($(git for-each-ref --format='%(refname:short)' refs/heads/ | grep -E "^(main|$ISSUE_BRANCH_PREFIX-[0-9]+-[a-zA-Z0-9-]+)$" | sort))

  # Create description array with empty descriptions
  local -a branch_descriptions
  for branch in $branches; do
    branch_descriptions+=("$branch:$branch")
  done

  # Use _values instead of _describe for better formatting control
  _values "branches" $branch_descriptions
}

compdef _git_checkout_issue_branch_complete git-checkout-issue-branch

# Create alias 'gcoi' for the function
alias gcoi='git-checkout-issue-branch'
# Make sure tab completion works with the alias too
compdef gcoi=git-checkout-issue-branch
