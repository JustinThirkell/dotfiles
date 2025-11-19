#!/usr/bin/env bash
#
# Install npm and yarn global packages from manifests

set -e

cd "$(dirname "$0")"

# Install from npm manifest
if command -v npm &> /dev/null && [ -f npm-manifest.txt ]; then
  echo "Installing npm global packages from manifest..."

  while IFS= read -r package; do
    # Skip empty lines and comments
    [[ -z "$package" || "$package" =~ ^# ]] && continue

    echo "  Installing $package..."
    npm install -g "$package" || echo "  Warning: Failed to install $package"
  done < npm-manifest.txt

  echo "npm packages installation complete"
else
  if ! command -v npm &> /dev/null; then
    echo "npm not installed, skipping npm packages"
  elif [ ! -f npm-manifest.txt ]; then
    echo "No npm manifest found, skipping"
  fi
fi

# Install from yarn manifest
if command -v yarn &> /dev/null && [ -f yarn-manifest.txt ]; then
  echo "Installing yarn global packages from manifest..."

  while IFS= read -r package; do
    # Skip empty lines and comments
    [[ -z "$package" || "$package" =~ ^# ]] && continue

    echo "  Installing $package..."
    yarn global add "$package" || echo "  Warning: Failed to install $package"
  done < yarn-manifest.txt

  echo "yarn packages installation complete"
else
  if ! command -v yarn &> /dev/null; then
    echo "yarn not installed, skipping yarn packages"
  elif [ ! -f yarn-manifest.txt ]; then
    echo "No yarn manifest found, skipping"
  fi
fi
