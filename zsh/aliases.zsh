alias reload!='. ~/.zshrc'

alias cls='clear' # Good 'ol Clear Screen command
alias j="just"
# Python
alias python='python3'

# apps
alias tower='open -a Tower'
alias git_cheatsheet='code --goto ~/.oh-my-zsh/plugins/git/README.md:1'

# Git
alias gs='gst'
gpom() {
  local default_branch=$(git default 2>/dev/null || echo "main")
  git pull --no-rebase --no-edit origin "$default_branch"
}
gbrlog() {
  local default_branch=$(git default 2>/dev/null || echo "main")
  git log --oneline --date=short HEAD ^"$default_branch" -10
}
# alias g="git"
# alias gc="git commit -S"
# alias gm="git commit -S -m"dz
# alias gs="git status"
# alias gpl="git pull"
# alias gps="git push"
# alias gd="git difftool"
# alias gr="git reset HEAD --hard"
# alias gst="git stash --include-untracked && git checkout"
# alias gnb="git checkout -b"
# alias gco="git checkout"
# alias gmg="git merge"
# alias gmm="git merge main"

# Yarn
alias yade="yarn add -D -E"
alias ys="yarn start"

# AWS
alias assume="source /opt/homebrew/bin/assume"
# https://docs.commonfate.io/granted/internals/shell-alias
export GRANTED_ALIAS_CONFIGURED="true"

# Gas Town docker shortcuts (use a function — zsh doesn't word-split variables in aliases)
gt-compose() { docker compose -f ~/dev/oss/gastown/docker-compose.yml "$@"; }

# Enter a Gas Town shell (for tmux, crew sessions, interactive work)
alias gt-shell='gt-compose exec -it gastown zsh'

# Run a gt command without entering a shell (for quick checks)
alias gtx='gt-compose exec gastown'

# Attach to crew member sessions
alias gt-crew='gt-compose exec -it gastown gt crew at'

# Attach to Mayor
alias gt-mayor='gt-compose exec -it gastown gt mayor attach'

# Watch an agent (read-only tmux attach)
gt-watch() { gt-compose exec -it gastown tmux attach -t "$1" -r; }

# List tmux sessions
alias gt-sessions='gt-compose exec gastown tmux list-sessions'
