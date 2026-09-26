#!/bin/bash
# onedriver helper for kdako.onedriver Omarchy plugin
# Commands: state, install, mount, unmount, status

set -euo pipefail

COMMAND="${1:-state}"
MOUNT_POINT="${HOME}/OneDrive"

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
      echo "Mount may still be in progress — check $MOUNT_POINT"
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
  *)
    echo "Usage: $0 {state|install|mount|unmount|status}" >&2
    exit 1
    ;;
esac
