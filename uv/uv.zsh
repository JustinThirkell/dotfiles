if [ -f "$HOME/.local/bin/env" ]; then
  . "$HOME/.local/bin/env"
fi
eval "$(uv generate-shell-completion zsh)"
eval "$(uvx --generate-shell-completion zsh)"
