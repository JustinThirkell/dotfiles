# Git completion is handled by:
# 1. System zsh git completion (/usr/share/zsh/5.9/functions/_git)
# 2. Oh My Zsh git plugin
#
# Custom completion not needed - system + OMZ works perfectly!
#
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
