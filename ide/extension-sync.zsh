# Function to sync extensions between source and target IDE (one-way, additive only)
sync_extensions_one_way() {
  local source_extensions="$1"
  local target_extensions="$2"
  local target_cmd="$3"
  local dry_run="$4"
  local source_name="$5"
  local target_name="$6"

  echo "📦 Checking extensions from $source_name to install in $target_name..."
  while IFS= read -r ext; do
    if ! grep -q "^$ext\$" "$target_extensions"; then
      if [ "$dry_run" = true ]; then
        echo "Would install $ext in $target_name"
      else
        echo "Installing $ext in $target_name..."
        $target_cmd --install-extension "$ext"
      fi
    fi
  done <"$source_extensions"
}

# Function to perform a hard sync from source to target IDE (including removals)
hard_sync_extensions() {
  local source_type="$1"
  local dry_run=false

  # Process command line arguments
  while getopts "d" opt; do
    case $opt in
    d) dry_run=true ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      return 1
      ;;
    esac
  done

  # Validate source type
  if [[ "$source_type" != "vscode" && "$source_type" != "cursor" ]]; then
    echo "Error: Source must be either 'vscode' or 'cursor'"
    return 1
  fi

  local vscode_cmd="code"
  local cursor_cmd="cursor"
  local temp_dir="/tmp/ide_sync"

  # Set source and target based on input
  local source_cmd target_cmd source_name target_name
  if [ "$source_type" = "vscode" ]; then
    source_cmd="$vscode_cmd"
    target_cmd="$cursor_cmd"
    source_name="VS Code"
    target_name="Cursor"
  else
    source_cmd="$cursor_cmd"
    target_cmd="$vscode_cmd"
    source_name="Cursor"
    target_name="VS Code"
  fi

  # Create temp directory if it doesn't exist
  mkdir -p "$temp_dir"

  # Get current lists of extensions
  $source_cmd --list-extensions | sort >"$temp_dir/source_extensions.txt"
  $target_cmd --list-extensions | sort >"$temp_dir/target_extensions.txt"

  echo "🔍 Analyzing extensions..."
  if [ "$dry_run" = true ]; then
    echo "DRY RUN - No changes will be made"
  fi

  # Install missing extensions
  echo "📦 Installing missing extensions in $target_name..."
  while IFS= read -r ext; do
    if ! grep -q "^$ext\$" "$temp_dir/target_extensions.txt"; then
      if [ "$dry_run" = true ]; then
        echo "Would install $ext in $target_name"
      else
        echo "Installing $ext in $target_name..."
        $target_cmd --install-extension "$ext"
      fi
    fi
  done <"$temp_dir/source_extensions.txt"

  # Remove extra extensions
  echo "�️  Removing extra extensions from $target_name..."
  while IFS= read -r ext; do
    if ! grep -q "^$ext\$" "$temp_dir/source_extensions.txt"; then
      if [ "$dry_run" = true ]; then
        echo "Would remove $ext from $target_name"
      else
        echo "Removing $ext from $target_name..."
        $target_cmd --uninstall-extension "$ext"
      fi
    fi
  done <"$temp_dir/target_extensions.txt"

  # Cleanup
  rm -rf "$temp_dir"

  if [ "$dry_run" = true ]; then
    echo "✨ Dry run complete!"
  else
    echo "✨ Hard sync complete! $target_name now matches $source_name"
  fi
}

# Original two-way sync function (additive only)
sync_ide_extensions() {
  local dry_run=false

  # Process command line arguments
  while getopts "d" opt; do
    case $opt in
    d) dry_run=true ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      return 1
      ;;
    esac
  done

  local vscode_cmd="code"
  local cursor_cmd="cursor"
  local temp_dir="/tmp/ide_sync"

  # Create temp directory if it doesn't exist
  mkdir -p "$temp_dir"

  # Get current lists of extensions
  $vscode_cmd --list-extensions | sort >"$temp_dir/vscode_extensions.txt"
  $cursor_cmd --list-extensions | sort >"$temp_dir/cursor_extensions.txt"

  echo "🔍 Analyzing extensions..."
  if [ "$dry_run" = true ]; then
    echo "DRY RUN - No changes will be made"
  fi

  # Sync in both directions using the helper function
  sync_extensions_one_way \
    "$temp_dir/vscode_extensions.txt" \
    "$temp_dir/cursor_extensions.txt" \
    "$cursor_cmd" \
    "$dry_run" \
    "VS Code" \
    "Cursor"

  sync_extensions_one_way \
    "$temp_dir/cursor_extensions.txt" \
    "$temp_dir/vscode_extensions.txt" \
    "$vscode_cmd" \
    "$dry_run" \
    "Cursor" \
    "VS Code"

  # Cleanup
  rm -rf "$temp_dir"

  if [ "$dry_run" = true ]; then
    echo "✨ Dry run complete!"
  else
    echo "✨ Sync complete!"
  fi
}
