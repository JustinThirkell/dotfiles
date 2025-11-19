#!/usr/bin/env bash
#
# Install Go packages from manifest

set -e

cd "$(dirname "$0")"

if ! command -v go &> /dev/null; then
  echo "go not installed, skipping Go packages installation"
  exit 0
fi

if [ ! -f manifest.txt ]; then
  echo "No Go manifest found, skipping"
  exit 0
fi

echo "Installing Go packages from manifest..."

while IFS= read -r package; do
  # Skip empty lines and comments
  [[ -z "$package" || "$package" =~ ^# ]] && continue

  echo "  Installing $package..."
  go install "$package" || echo "  Warning: Failed to install $package"
done < manifest.txt

echo "Go packages installation complete"
