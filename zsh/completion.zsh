# matches case insensitive for lowercase
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# pasting with tabs doesn't perform completion
zstyle ':completion:*' insert-tab pending

# Always show completions without asking (even if many)
zstyle ':completion:*' list-prompt ''
zstyle ':completion:*' select-prompt ''

# Alternative: Set a higher threshold before asking (optional)
# LISTMAX=0  # 0 means never ask, always show all completions

# Show completions immediately without pressing tab twice
setopt AUTO_LIST
setopt LIST_AMBIGUOUS

# Show completions in a more compact format
zstyle ':completion:*' list-packed true
zstyle ':completion:*' list-rows-first true
