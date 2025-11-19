#!/usr/bin/env bash
#
# Generate manifest of installed Go packages

set -e

cd "$(dirname "$0")"

if ! command -v go &> /dev/null; then
  echo "go not installed, skipping manifest generation"
  exit 0
fi

GO_BIN_DIR="${GOBIN:-$HOME/go/bin}"

if [ ! -d "$GO_BIN_DIR" ]; then
  echo "Go bin directory not found, skipping manifest generation"
  exit 0
fi

echo "Generating Go manifest..."

# Clear or create manifest file
> manifest.txt

# Iterate through all binaries in go/bin
for binary in "$GO_BIN_DIR"/*; do
  if [ -f "$binary" ] && [ -x "$binary" ]; then
    # Extract module path from binary metadata
    module_path=$(go version -m "$binary" 2>/dev/null | grep -E '^\s*path\s+' | awk '{print $2}')

    if [ -n "$module_path" ]; then
      echo "${module_path}@latest" >> manifest.txt
    fi
  fi
done

# Sort and deduplicate
sort -u manifest.txt -o manifest.txt

echo "Go manifest saved to go/manifest.txt ($(wc -l < manifest.txt | tr -d ' ') packages)"
