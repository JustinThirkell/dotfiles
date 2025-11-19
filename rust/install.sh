#!/usr/bin/env bash
#
# Install cargo packages from manifest

set -e

cd "$(dirname "$0")"

if ! command -v cargo &> /dev/null; then
  echo "cargo not installed, skipping cargo packages installation"
  exit 0
fi

if [ ! -f manifest.txt ]; then
  echo "No cargo manifest found, skipping"
  exit 0
fi

echo "Installing cargo packages from manifest..."

while IFS= read -r package; do
  # Skip empty lines and comments
  [[ -z "$package" || "$package" =~ ^# ]] && continue

  echo "  Installing $package..."
  cargo install "$package" || echo "  Warning: Failed to install $package"
done < manifest.txt

echo "cargo packages installation complete"
