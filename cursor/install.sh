echo "› cursor settings symlink setup"

# Backup existing settings if they exist
CURSOR_SETTINGS_PATH="$HOME/Library/Application Support/Cursor/User/settings.json"
if [ -f "$CURSOR_SETTINGS_PATH" ] && [ ! -L "$CURSOR_SETTINGS_PATH" ]; then
  echo "  backing up existing settings.json to settings.json.before-dotfiles"
  mv "$CURSOR_SETTINGS_PATH" "$CURSOR_SETTINGS_PATH.before-dotfiles"
fi

ln -sf "$PWD/cursor/settings.json" "$CURSOR_SETTINGS_PATH"
