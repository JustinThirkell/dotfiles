#! /bin/zsh
# I'm trialling out a few productivity improvements.
# These are deliberately not under source control in the katoa repo and are excluded by adding them to .git/info/exclude
# Just in case my machine gets toasted I don't want to lose them, and so they are backed up like so....
# If they work/once they're solid then they'll get added to the katoa repo.

productivity-assets-backup() {
  local backup_date=$(date +%Y%m%d)
  local backup_dir="$HOME/Library/CloudStorage/GoogleDrive-${USER_EMAIL}/My Drive/Untracked files backup"
  local patch_file="$backup_dir/productivity-assets-$backup_date.patch"
  local zip_file="$backup_dir/productivity-assets-$backup_date.zip"

  # CD to the specific repo
  cd "$PROJECTS/vital/katoa" || {
    echo "Error: Cannot access $PROJECTS/vital/katoa"
    return 1
  }

  # Create backup directory if it doesn't exist
  mkdir -p "$backup_dir"

  # Files to back up
  local files=(
    ".vscode/tasks.json"
    ".cursor/rules/integration-test-execution.mdc"
    ".cursor/rules/unit-test-execution.mdc"
    "apps/care/src/api/core/test-visit/create-test-visit-testharness.ts"
  )

  # Check which files exist
  local existing_files=()
  for file in "${files[@]}"; do
    if [[ -f "$file" ]]; then
      existing_files+=("$file")
    fi
  done

  if [[ ${#existing_files[@]} -eq 0 ]]; then
    echo "No productivity assets found to backup"
    return 1
  fi

  # Create git patch
  echo "Creating git patch..."
  git add "${existing_files[@]}"
  git diff --cached >"$patch_file"
  git reset >/dev/null 2>&1 # unstage the files

  # Create zip archive
  echo "Creating zip archive..."
  zip -q "$zip_file" "${existing_files[@]}"

  echo "Backup completed:"
  echo "  Patch: $patch_file"
  echo "  Zip:   $zip_file"
  echo "  Files backed up: ${existing_files[*]}"
}
