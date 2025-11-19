#!/usr/bin/env bash
#
# Install uv tools from manifest

set -e

cd "$(dirname "$0")"

if ! command -v uv &> /dev/null; then
  echo "uv not installed, skipping uv tools installation"
  exit 0
fi

if [ ! -f manifest.txt ]; then
  echo "No uv manifest found, skipping"
  exit 0
fi

echo "Installing uv tools from manifest..."

while IFS= read -r package; do
  # Skip empty lines and comments
  [[ -z "$package" || "$package" =~ ^# ]] && continue

  echo "  Installing $package..."
  uv tool install "$package" || echo "  Warning: Failed to install $package"
done < manifest.txt

echo "uv tools installation complete"
