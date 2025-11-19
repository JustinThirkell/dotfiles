#!/usr/bin/env bash
#
# Generate manifest of installed cargo packages

set -e

cd "$(dirname "$0")"

if ! command -v cargo &> /dev/null; then
  echo "cargo not installed, skipping manifest generation"
  exit 0
fi

echo "Generating cargo manifest..."

# Get list of installed packages and extract crate names
cargo install --list | grep -E '^[a-zA-Z0-9_-]+ v' | awk '{print $1}' | sort > manifest.txt

echo "cargo manifest saved to rust/manifest.txt ($(wc -l < manifest.txt | tr -d ' ') packages)"
