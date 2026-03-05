#!/bin/bash
# Shared Common Utilities
# Provides common functions for repository management, token management, and logging
# Version: 1.0.0

# ============================================================================
# Logging Utilities
# ============================================================================

# Only initialize logging if not already initialized
if [ -z "${COLOR_DEBUG:-}" ]; then
  # Color codes - respect NO_COLOR environment variable
  if [ -t 2 ] && [ "${NO_COLOR:-}" = "" ]; then
    COLOR_DEBUG='\033[0;90m' # Grey (bright black, works in both dark/light themes)
    COLOR_INFO='\033[0;32m'  # Green
    COLOR_WARN='\033[0;33m'  # Yellow
    COLOR_ERROR='\033[0;31m' # Red
    COLOR_RESET='\033[0m'    # Reset
  else
    COLOR_DEBUG=''
    COLOR_INFO=''
    COLOR_WARN=''
    COLOR_ERROR=''
    COLOR_RESET=''
  fi

  # Single source of truth: set DEVCONTAINER_DEBUG=true to enable debug logging
  DEBUG=${DEVCONTAINER_DEBUG:-false}

  # Debug logging - only shown if DEBUG=true
  debug_log() {
    if [ "${DEBUG:-false}" = "true" ]; then
      echo -e "${COLOR_DEBUG}[DEBUG]${COLOR_RESET} $*" >&2
    fi
  }

  # Info logging - always shown
  info_log() {
    echo -e "${COLOR_INFO}[INFO]${COLOR_RESET} $*" >&2
  }

  # Warning logging - always shown
  warn_log() {
    echo -e "${COLOR_WARN}[WARN]${COLOR_RESET} $*" >&2
  }

  # Error logging - always shown
  error_log() {
    echo -e "${COLOR_ERROR}[ERROR]${COLOR_RESET} $*" >&2
  }
fi

# ============================================================================
# Config Local Resolution
# ============================================================================

CONFIG_LOCAL_FILE="/workspace/.devcontainer/config.local"

# Read a key=value from config.local
# Usage: _read_config_value KEY
_read_config_value() {
  local key="$1"
  if [ -f "$CONFIG_LOCAL_FILE" ]; then
    grep -E "^${key}=" "$CONFIG_LOCAL_FILE" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"'"'" | tr -d '[:space:]'
  fi
}

# Read a key=value from config.local, preserving internal whitespace
# Usage: _read_config_value_raw KEY
_read_config_value_raw() {
  local key="$1"
  if [ -f "$CONFIG_LOCAL_FILE" ]; then
    grep -E "^${key}=" "$CONFIG_LOCAL_FILE" 2>/dev/null | head -1 | cut -d= -f2- | tr -d '"'"'" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'
  fi
}

# Get the git user name from config.local
# Returns: user name or empty string
get_git_user_name() {
  local name
  name=$(_read_config_value_raw "GIT_USER_NAME")
  if [ -n "$name" ]; then
    debug_log "Git user name from config.local: $name"
    echo "$name"
  fi
}

# Get the git user email from config.local
# Returns: user email or empty string
get_git_user_email() {
  local email
  email=$(_read_config_value "GIT_USER_EMAIL")
  if [ -n "$email" ]; then
    debug_log "Git user email from config.local: $email"
    echo "$email"
  fi
}

# Get the Claude auth mode from config.local
# Returns: "browser" or "api-key"
get_claude_auth_mode() {
  local auth_mode
  auth_mode=$(_read_config_value "CLAUDE_AUTH_MODE")
  if [ -n "$auth_mode" ]; then
    debug_log "Claude auth mode from config.local: $auth_mode"
    echo "$auth_mode"
  else
    debug_log "No CLAUDE_AUTH_MODE in config.local — defaulting to browser"
    echo "browser"
  fi
}

# Get the devcontainer profile from config.local, falling back to env var
# Returns: profile name (default: "default")
get_devcontainer_profile() {
  local profile
  profile=$(_read_config_value "PROFILE")
  if [ -n "$profile" ]; then
    debug_log "Profile from config.local: $profile"
    echo "$profile"
    return
  fi
  debug_log "No profile configured — defaulting to default"
  echo "default"
}

# Get the 1Password service account token from config.local
# Returns: token value or empty string
get_op_service_account_token() {
  local token
  token=$(_read_config_value "OP_SERVICE_ACCOUNT_TOKEN")
  if [ -n "$token" ]; then
    debug_log "OP service account token found in config.local (length: ${#token})"
    echo "$token"
  fi
}

# ============================================================================
# Repository Name Detection
# ============================================================================

# Determine repository name from git or directory
# Returns: repository name (e.g., "my-repo")
get_repo_name() {
  local repo_name=""

  # Try to get from git remote URL first (works in containers where cwd is /workspace)
  if git rev-parse --show-toplevel &>/dev/null 2>&1; then
    local remote_url=$(git config --get remote.origin.url 2>/dev/null || echo "")
    if [ -n "$remote_url" ]; then
      # Extract repo name from URLs like:
      # - git@github.com:user/repo.git
      # - https://github.com/user/repo.git
      # - git@github.com-{repo}:user/repo.git (SSH alias format)
      # Remove .git suffix, extract last path component
      repo_name=$(echo "$remote_url" | sed -E 's|\.git$||' | sed -E 's|.*[:/]([^/]+)$|\1|')
      # Handle SSH alias format (git@github.com-repo:user/repo.git)
      if [[ "$repo_name" =~ ^github\.com- ]]; then
        repo_name=$(echo "$repo_name" | sed -E 's|^github\.com-||')
      fi
      debug_log "Repository name detected from git remote: $repo_name"
    else
      repo_name=$(basename "$(git rev-parse --show-toplevel)")
      debug_log "Repository name detected from git root: $repo_name"
    fi
  else
    repo_name=$(basename "$PWD")
    debug_log "Repository name detected from directory: $repo_name"
  fi
  echo "${repo_name}"
}

# ============================================================================
# Vault Name Resolution
# ============================================================================

# Get repository-specific vault name
# Returns: vault name in format "Devcontainer {repo-name}"
# Example: "my-repo" -> "Devcontainer my-repo"
get_repo_vault_name() {
  local repo_name="$1"
  if [ -z "$repo_name" ]; then
    error_log "get_repo_vault_name: repo_name is required"
    return 1
  fi
  echo "Devcontainer ${repo_name}"
}
