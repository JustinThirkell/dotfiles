#!/bin/zsh
# Zen browser session backup/restore.
# Workaround for Zen occasionally unpinning pinned tabs — snapshot the
# session-store files when they're in a known-good state and restore if needed.

ZEN_PROFILE="${ZEN_PROFILE:-/Users/justin/Library/Application Support/zen/Profiles/tfwpy8uk.Default (release)}"
ZEN_BACKUP_DIR="${ZEN_BACKUP_DIR:-$HOME/Documents/Zen/backups}"
ZEN_SESSION_FILES=(sessionstore.jsonlz4 sessionstore-backups zen-sessions.jsonlz4 zen-sessions-backup)

zen_running() {
  pgrep -f "Zen\.app/Contents/MacOS" >/dev/null
}

zen_snapshot() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
    cat <<EOF
Usage: zen_snapshot

Copy Zen session/pinned-tab state to \$ZEN_BACKUP_DIR/<timestamp>/.
Quit Zen first (Cmd+Q — not just the window) so the session is flushed to disk.

Env:
  ZEN_PROFILE     Zen profile dir
                  current: $ZEN_PROFILE
  ZEN_BACKUP_DIR  Snapshot destination
                  current: $ZEN_BACKUP_DIR
EOF
    return 0
  fi

  if zen_running; then
    echo "Quit Zen first (Cmd+Q, not just the window) so the session is flushed." >&2
    return 1
  fi

  local ts dest f
  ts="$(date +%Y%m%dT%H%M%S)"
  dest="$ZEN_BACKUP_DIR/$ts"
  mkdir -p "$dest"
  for f in "${ZEN_SESSION_FILES[@]}"; do
    [[ -e "$ZEN_PROFILE/$f" ]] && cp -R "$ZEN_PROFILE/$f" "$dest/"
  done
  echo "Snapshot saved to $dest"
}

zen_restore() {
  if [[ "${1:-}" == "--help" || "${1:-}" == "-h" || -z "${1:-}" ]]; then
    cat <<EOF
Usage: zen_restore <snapshot-dir>

Restore Zen session files from <snapshot-dir> into the active profile.
The current state is first stashed to \$ZEN_BACKUP_DIR/pre-restore-<timestamp>/
so the restore is itself reversible. Quit Zen before running.

Env:
  ZEN_PROFILE     Zen profile dir
                  current: $ZEN_PROFILE
  ZEN_BACKUP_DIR  Pre-restore stash destination
                  current: $ZEN_BACKUP_DIR
EOF
    [[ -z "${1:-}" ]] && return 1
    return 0
  fi

  if zen_running; then
    echo "Quit Zen first." >&2
    return 1
  fi

  local src="$1"
  if [[ ! -d "$src" ]]; then
    echo "Snapshot dir not found: $src" >&2
    return 1
  fi

  local pre f
  pre="$ZEN_BACKUP_DIR/pre-restore-$(date +%Y%m%dT%H%M%S)"
  mkdir -p "$pre"
  for f in "${ZEN_SESSION_FILES[@]}"; do
    [[ -e "$ZEN_PROFILE/$f" ]] && cp -R "$ZEN_PROFILE/$f" "$pre/"
  done
  for f in "${ZEN_SESSION_FILES[@]}"; do
    if [[ -e "$src/$f" ]]; then
      rm -rf "${ZEN_PROFILE:?}/$f"
      cp -R "$src/$f" "$ZEN_PROFILE/"
    fi
  done
  echo "Restored from $src (previous state stashed in $pre)"
}
