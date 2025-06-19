#!/bin/bash
# Imports KeyCue settings from the dotfiles repository.

# Get the directory of this script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KEYCUE_APP_SUPPORT_DIR="$HOME/Library/Application Support/KeyCue"

# Kill KeyCue to ensure settings are not overwritten
pkill KeyCue

# Create Application Support directory if it doesn't exist
mkdir -p "$KEYCUE_APP_SUPPORT_DIR"

# Import KeyCue preferences
defaults import com.macility.keycue "$SCRIPT_DIR/com.macility.keycue.plist"

# Copy KeyCue application support files
cp -r "$SCRIPT_DIR/Custom Shortcuts" "$KEYCUE_APP_SUPPORT_DIR/"
cp -r "$SCRIPT_DIR/Themes" "$KEYCUE_APP_SUPPORT_DIR/"

echo "KeyCue settings imported. You may need to restart KeyCue."
