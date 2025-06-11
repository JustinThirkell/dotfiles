#!/bin/zsh

# Hybrid Git Completion Setup
# 1. Use Homebrew's git completion (more current and optimized)
# 2. Configure for better git checkout behavior

# Load Homebrew's git completion (preferred over system default)
if [[ -f "$(brew --prefix)/share/zsh/site-functions/_git" ]]; then
  # Force Homebrew's git completion to take precedence
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
  # Remove any cached git completion
  unfunction _git 2>/dev/null || true
fi

# Configure git checkout completion to show local branches first, then remote branches
# This separates local branches from remote branches more clearly
zstyle ':completion:*:git-checkout:*' tag-order 'local-branches remote-branches heads commit-tags tree-ishs files'

# Group local branches separately from remote branches
zstyle ':completion:*:git-checkout:*:local-branches' command 'git branch --format="%(refname:short)"'
zstyle ':completion:*:git-checkout:*:remote-branches' command 'git branch -r --format="%(refname:short)" | grep -v "HEAD"'

# Alternative configuration for better separation
zstyle ':completion:*:git-checkout:*' group-name ''
zstyle ':completion:*:git-checkout:*:heads' group-name 'local branches'
zstyle ':completion:*:git-checkout:*:remote-branches' group-name 'remote branches'

# Limit the number of commit completions to reduce clutter
zstyle ':completion:*:git-checkout:*:commit-objects' command 'git log --oneline --max-count=10'

# Don't sort branches alphabetically - show in git's natural order
zstyle ':completion:*:git-checkout:*:heads' sort false
zstyle ':completion:*:git-checkout:*:remote-branches' sort false
zstyle ':completion:*:git-checkout:*:local-branches' sort false

# Original code kept for reference:
#
# #!/bin/zsh
# # Uses git's autocompletion for inner commands. Assumes an install of git's
# # bash `git-completion` script at $completion below (this is where Homebrew
# # tosses it, at least).
# # CREDIT: https://github.com/holman/dotfiles/blob/master/git/completion.zsh
# completion='$(brew --prefix)/share/zsh/site-functions/_git'
# if test -f $completion; then
#   source $completion
# fi
