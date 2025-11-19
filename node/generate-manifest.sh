#!/usr/bin/env bash
#
# Generate manifests of globally installed npm and yarn packages

set -e

cd "$(dirname "$0")"

# Generate npm manifest
if command -v npm &> /dev/null; then
  echo "Generating npm manifest..."
  # Get global packages, exclude npm itself and corepack, extract package names
  npm list -g --depth=0 --parseable 2>/dev/null | \
    xargs -n1 basename 2>/dev/null | \
    grep -v '^npm$' | \
    grep -v '^corepack$' | \
    grep -v '^lib$' | \
    sort > npm-manifest.txt
  echo "npm manifest saved to node/npm-manifest.txt ($(wc -l < npm-manifest.txt | tr -d ' ') packages)"
else
  echo "npm not installed, skipping npm manifest"
fi

# Generate yarn manifest
if command -v yarn &> /dev/null; then
  echo "Generating yarn manifest..."
  # yarn global list outputs "yarn global vX.X.X" and "info" lines, extract package names
  yarn global list --depth=0 2>/dev/null | \
    grep -E '^info "' | \
    sed 's/info "//g' | \
    sed 's/@.*"//g' | \
    sort > yarn-manifest.txt

  # If manifest is empty or only has headers, create empty file
  if [ ! -s yarn-manifest.txt ] || ! grep -q '^[a-zA-Z]' yarn-manifest.txt 2>/dev/null; then
    > yarn-manifest.txt
  fi

  echo "yarn manifest saved to node/yarn-manifest.txt ($(wc -l < yarn-manifest.txt | tr -d ' ') packages)"
else
  echo "yarn not installed, skipping yarn manifest"
fi
