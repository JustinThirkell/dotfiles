#!/usr/bin/env bash

##############################################################################################
# Function to download and install a vscode extension into Cursor
#
# Cursor uses the Open VSX Registry as its default extension marketplace, rather than Microsoft's VS Code Marketplace. 
# Not all extension authors publish to Open VSX, which is why you'll find some extensions missing.
#
# Download VSCode extension as .vsix and install it in Cursor
# Usage: install-vscode-ext-into-cursor pb33f.vacuum
##############################################################################################
install-vscode-ext-into-cursor() {
  if [[ -z "$1" ]]; then
    echo "Usage: install-vscode-ext-into-cursor <publisher.extension>" >&2
    return 1
  fi

  local ext=$1  # format: publisher.extension
  local publisher=${ext%.*}
  local extension=${ext#*.}
  
  # Validate that we have both publisher and extension
  if [[ -z "$publisher" ]] || [[ -z "$extension" ]] || [[ "$publisher" == "$ext" ]] || [[ "$extension" == "$ext" ]]; then
    echo "Error: Invalid extension format. Expected 'publisher.extension', got: $ext" >&2
    return 1
  fi

  # Use ~/Downloads directory
  local downloads_dir="$HOME/Downloads"
  local vsix_file="${downloads_dir}/${ext}.vsix"

  # Download the extension
  echo "Downloading ${ext}..."
  if ! curl -L -f -s "https://${publisher}.gallery.vsassets.io/_apis/public/gallery/publisher/${publisher}/extension/${extension}/latest/assetbyname/Microsoft.VisualStudio.Services.VSIXPackage" -o "$vsix_file"; then
    echo "Error: Failed to download extension ${ext}" >&2
    return 1
  fi

  # Verify the file was downloaded and is not empty
  if [[ ! -f "$vsix_file" ]] || [[ ! -s "$vsix_file" ]]; then
    echo "Error: Downloaded file is missing or empty" >&2
    rm -f "$vsix_file"
    return 1
  fi

  # Install the extension
  echo "Installing ${ext}..."
  if cursor --install-extension "$vsix_file"; then
    echo "Successfully installed ${ext}"
    return 0
  else
    echo "Error: Failed to install extension ${ext}" >&2
    # Keep the file for debugging
    echo "VSIX file kept at: $vsix_file" >&2
    return 1
  fi
}

