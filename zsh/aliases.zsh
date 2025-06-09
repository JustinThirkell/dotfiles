alias reload!='. ~/.zshrc'

alias cls='clear' # Good 'ol Clear Screen command

# apps
alias tower='open -a Tower'
alias git_cheatsheet='code --goto ~/.oh-my-zsh/plugins/git/README.md:1'

# Git
alias gs='gst'
alias gpom='git pull --no-rebase origin main'
alias gbrlog='git log --oneline --date=short HEAD ^main -10' # or git log upstream/main..HEAD
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
