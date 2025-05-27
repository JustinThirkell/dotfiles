if [ -f $HOME/.iterm2_shell_integration.zsh ]; then
  echo "iTerm2 shell integration already installed."
else
  echo "Installing iTerm2 shell integration..."
  curl -L https://iterm2.com/shell_integration/zsh -o $HOME/.iterm2_shell_integration.zsh
fi

if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
else
  echo "Oh My Zsh is already installed at $HOME/.oh-my-zsh, skipping install."
fi
