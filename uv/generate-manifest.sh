#!/usr/bin/env bash
#
# Generate manifest of globally installed uv tools

set -e

cd "$(dirname "$0")"

if ! command -v uv &> /dev/null; then
  echo "uv not installed, skipping manifest generation"
  exit 0
fi

echo "Generating uv manifest..."

# Get list of installed tools and extract just the package names
uv tool list | grep -E '^[a-zA-Z0-9_-]+ v' | awk '{print $1}' > manifest.txt

echo "uv manifest saved to uv/manifest.txt ($(wc -l < manifest.txt | tr -d ' ') packages)"
