#!/bin/bash
# Exports KeyCue settings to the dotfiles repository.

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Export KeyCue preferences
defaults export com.macility.keycue "$SCRIPT_DIR/com.macility.keycue.plist"

# Copy KeyCue application support files
cp -r "$HOME/Library/Application Support/KeyCue/Custom Shortcuts" "$SCRIPT_DIR/"
cp -r "$HOME/Library/Application Support/KeyCue/Themes" "$SCRIPT_DIR/"

# Commit the changes
cd "$SCRIPT_DIR"
git add .
git commit -m "KeyCue: Update settings"

echo "KeyCue settings exported and committed."
