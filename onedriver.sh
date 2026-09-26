#!/bin/bash
# onedriver helper for kdako.onedriver Omarchy plugin
# Commands: state, install, remove, mount, unmount, status, list, delete, rename

set -euo pipefail

COMMAND="${1:-state}"
MOUNT_POINT="${HOME}/OneDrive"

json_escape() {
  s="${1}"
  s="${s//\\/\\\\}"
  s="${s//\"/\\\"}"
  printf '%s' "$s"
}

case "$COMMAND" in
state)
  installed=false
  mounted=false
  if command -v onedriver >/dev/null 2>&1; then
    installed=true
  fi
  if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    mounted=true
  fi
  echo "installed=$installed"
  echo "mounted=$mounted"
  ;;
install)
  echo "Installing onedriver from AUR..."
  if command -v yay >/dev/null 2>&1; then
    yay -S --noconfirm onedriver
  elif command -v paru >/dev/null 2>&1; then
    paru -S --noconfirm onedriver
  else
    echo "ERROR: No AUR helper found (yay or paru required)" >&2
    exit 1
  fi
  ;;
remove)
  echo "Removing onedriver from AUR..."
  if command -v yay >/dev/null 2>&1; then
    yay -Rns --noconfirm onedriver
  elif command -v paru >/dev/null 2>&1; then
    paru -Rns --noconfirm onedriver
  else
    echo "ERROR: No AUR helper found (yay or paru required)" >&2
    exit 1
  fi
  ;;
mount)
  if ! command -v onedriver >/dev/null 2>&1; then
    echo "ERROR: onedriver not installed" >&2
    exit 1
  fi
  if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "Already mounted at $MOUNT_POINT"
    exit 0
  fi
  mkdir -p "$MOUNT_POINT"
  echo "Mounting OneDrive at $MOUNT_POINT..."
  setsid onedriver "$MOUNT_POINT" &
  sleep 2
  if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "Mounted successfully"
  else
    echo "Mount may still be in progress"
  fi
  ;;
unmount)
  if ! mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
    echo "Not mounted"
    exit 0
  fi
  echo "Unmounting $MOUNT_POINT..."
  fusermount -u "$MOUNT_POINT" 2>/dev/null || umount "$MOUNT_POINT" 2>/dev/null || {
    echo "ERROR: Failed to unmount" >&2
    exit 1
  }
  echo "Unmounted"
  ;;
status)
  if command -v onedriver >/dev/null 2>&1; then
    echo "onedriver is installed"
    if mountpoint -q "$MOUNT_POINT" 2>/dev/null; then
      echo "Mounted at $MOUNT_POINT"
      du -sh "$MOUNT_POINT" 2>/dev/null | cut -f1 || echo "size unknown"
    else
      echo "Not mounted"
    fi
  else
    echo "onedriver is NOT installed"
  fi
  ;;
list)
  dir="${2:-$MOUNT_POINT}"
  resolved=$(realpath "$dir" 2>/dev/null) || { echo "[]"; exit 0; }

  case "$resolved" in
    "$MOUNT_POINT"|"$MOUNT_POINT"/*) ;;
    *) echo "[]"; exit 0 ;;
  esac

  [[ -d "$resolved" ]] || { echo "[]"; exit 0; }

  output="["
  need_comma=false
  count=0
  max_entries=200

  while IFS= read -r -d '' path && [[ $count -lt $max_entries ]]; do
    name=$(basename "$path")
    [[ "$name" == .* ]] && continue

    if $need_comma; then output+=","; fi
    need_comma=true

    escaped=$(json_escape "$name")
    output+="{\"n\":\"$escaped\",\"t\":\"folder\"}"
    count=$((count + 1))
  done < <(find "$resolved" -maxdepth 1 -mindepth 1 -type d -printf '%p\0' 2>/dev/null | sort -z)

  while IFS= read -r -d '' path && [[ $count -lt $max_entries ]]; do
    name=$(basename "$path")
    [[ "$name" == .* ]] && continue

    if $need_comma; then output+=","; fi
    need_comma=true

    escaped=$(json_escape "$name")
    sz=$(stat -c %s "$path" 2>/dev/null || echo 0)
    output+="{\"n\":\"$escaped\",\"t\":\"file\",\"s\":$sz}"
    count=$((count + 1))
  done < <(find "$resolved" -maxdepth 1 -mindepth 1 -type f -printf '%p\0' 2>/dev/null | sort -z)

  output+="]"
  echo "$output"
  ;;
delete)
  path="${2}"
  [[ -z "$path" ]] && { echo "ERROR: No path specified" >&2; exit 1; }

  resolved=$(realpath "$path" 2>/dev/null) || { echo "ERROR: Path not found" >&2; exit 1; }

  case "$resolved" in
    "$MOUNT_POINT"|"$MOUNT_POINT"/*) ;;
    *) echo "ERROR: Path outside mount point" >&2; exit 1 ;;
  esac

  rm -rf "$resolved" && echo "Deleted: $(basename "$path")" || {
    echo "ERROR: Delete failed" >&2
    exit 1
  }
  ;;
rename)
  old="${2}"
  new="${3}"
  [[ -z "$old" || -z "$new" ]] && { echo "ERROR: Usage: rename <old> <new>" >&2; exit 1; }

  resolved_old=$(realpath "$old" 2>/dev/null) || { echo "ERROR: Source not found" >&2; exit 1; }

  case "$resolved_old" in
    "$MOUNT_POINT"|"$MOUNT_POINT"/*) ;;
    *) echo "ERROR: Path outside mount point" >&2; exit 1 ;;
  esac

  dir=$(dirname "$resolved_old")
  resolved_new=$(realpath -m "$dir/$new" 2>/dev/null) || { echo "ERROR: Invalid new name" >&2; exit 1; }

  case "$resolved_new" in
    "$MOUNT_POINT"|"$MOUNT_POINT"/*) ;;
    *) echo "ERROR: New path outside mount point" >&2; exit 1 ;;
  esac

  mv "$resolved_old" "$resolved_new" && echo "Renamed: $(basename "$old") to $new" || {
    echo "ERROR: Rename failed" >&2
    exit 1
  }
  ;;
*)
  echo "Usage: $0 {state|install|remove|mount|unmount|status|list|delete|rename}" >&2
  exit 1
  ;;
esac
