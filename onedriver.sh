#!/usr/bin/env bash
# onedriver — helper script for the kdako.onedriver Omarchy bar widget.
#
# Commands:
#   state      -> prints "installed=true/false" and "mounted=true/false"
#   install    -> installs the onedriver AUR package with yay or paru
#   remove     -> removes the onedriver AUR package
#   mount      -> starts onedriver if installed and not running
#   unmount    -> stops a running onedriver process
#   status     -> human-readable status line for floating-terminal display
#   list <dir> -> JSON array of {t, n, s} for the given directory
#   delete <path>   -> rm -rf the path (must be under ~/OneDrive)
#   rename <old> <new> -> mv old new (both under ~/OneDrive)
#
# The real onedriver binary is expected at /usr/bin/onedriver (from the AUR).
# AUR operations use `yay` if available, falling back to `paru`.

set -euo pipefail

REAL_ONEDRIVER="/usr/bin/onedriver"
MOUNT_POINT="$HOME/OneDrive"
AUR_HELPER=""

detect_aur_helper() {
    if command -v yay >/dev/null 2>&1; then
        AUR_HELPER="yay"
    elif command -v paru >/dev/null 2>&1; then
        AUR_HELPER="paru"
    else
        echo "No AUR helper found. Install yay or paru first." >&2
        exit 1
    fi
}

is_installed() {
    command -v onedriver >/dev/null 2>&1
}

is_mounted() {
    if ! is_installed; then
        return 1
    fi
    pgrep -x onedriver >/dev/null 2>&1
}

stop_onedriver() {
    if command -v onedriver >/dev/null 2>&1; then
        onedriver --unmount >/dev/null 2>&1 || true
    fi
    sleep 1
    pkill -x onedriver >/dev/null 2>&1 || true
    sleep 1
}

start_onedriver() {
    if ! is_installed; then
        echo "onedriver is not installed. Run install first." >&2
        exit 1
    fi
    if is_mounted; then
        echo "already mounted"
        return 0
    fi
    nohup onedriver >/dev/null 2>&1 &
    sleep 2
    if is_mounted; then
        echo "mounted"
    else
        echo "start issued (check logs if mount did not appear)"
    fi
}

cmd_state() {
    if is_installed; then
        echo "installed=true"
    else
        echo "installed=false"
    fi
    if is_mounted; then
        echo "mounted=true"
    else
        echo "mounted=false"
    fi
}

cmd_install() {
    detect_aur_helper
    echo "installing onedriver via $AUR_HELPER ..."
    if ! $AUR_HELPER -S --noconfirm onedriver >/dev/null 2>&1; then
        echo "AUR install failed. Open the terminal button to see details." >&2
        exit 1
    fi
    echo "installed"
}

cmd_remove() {
    if ! is_installed; then
        echo "onedriver is not installed." >&2
        exit 1
    fi
    detect_aur_helper
    echo "removing onedriver via $AUR_HELPER ..."
    if ! $AUR_HELPER -Rns --noconfirm onedriver >/dev/null 2>&1; then
        echo "AUR remove failed. Open the terminal button to see details." >&2
        exit 1
    fi
    stop_onedriver
    echo "removed"
}

cmd_mount() {
    start_onedriver
}

cmd_unmount() {
    if ! is_mounted; then
        echo "not mounted"
        return 0
    fi
    stop_onedriver
    echo "unmounted"
}

cmd_status() {
    if ! is_installed; then
        echo "onedriver: not installed"
        return 0
    fi
    if is_mounted; then
        echo "onedriver: mounted at $MOUNT_POINT"
    else
        echo "onedriver: installed but not running"
    fi
}

cmd_list() {
    local dir="${1:-$MOUNT_POINT}"
    if [ ! -d "$dir" ]; then
        echo "[]"
        return 0
    fi

    printf '['
    local first=1
    local entry
    while IFS= read -r -d '' entry; do
        local name
        name="$(basename "$entry")"
        local type
        if [ -d "$entry" ] && [ ! -L "$entry" ]; then
            type="folder"
        else
            type="file"
        fi
        local size
        if [ "$type" = "file" ]; then
            size="$(stat -c %s "$entry" 2>/dev/null || echo 0)"
        else
            size=0
        fi
        name="${name//\\/\\\\}"
        name="${name//\"/\\\"}"
        if [ "$first" -eq 1 ]; then
            first=0
        else
            printf ','
        fi
        printf '{"t":"%s","n":"%s","s":%s}' "$type" "$name" "$size"
    done < <(find "$dir" -maxdepth 1 -mindepth 1 -print0 2>/dev/null | sort -z)
    printf ']\n'
}

cmd_delete() {
    local target="$1"
    if [ -z "$target" ]; then
        echo "usage: delete <path>" >&2
        exit 1
    fi
    local real_target
    real_target="$(readlink -f "$target" 2>/dev/null || echo "$target")"
    local real_mount
    real_mount="$(readlink -f "$MOUNT_POINT" 2>/dev/null || echo "$MOUNT_POINT")"
    if [ "${real_target#"$real_mount"}" = "$real_target" ]; then
        echo "refusing to delete outside $MOUNT_POINT: $target" >&2
        exit 1
    fi
    if [ ! -e "$target" ]; then
        echo "path does not exist: $target" >&2
        exit 1
    fi
    rm -rf "$target"
    echo "deleted $target"
}

cmd_rename() {
    local old="$1"
    local new="$2"
    if [ -z "$old" ] || [ -z "$new" ]; then
        echo "usage: rename <old> <new>" >&2
        exit 1
    fi
    local real_old
    real_old="$(readlink -f "$old" 2>/dev/null || echo "$old")"
    local real_mount
    real_mount="$(readlink -f "$MOUNT_POINT" 2>/dev/null || echo "$MOUNT_POINT")"
    if [ "${real_old#"$real_mount"}" = "$real_old" ]; then
        echo "refusing to rename outside $MOUNT_POINT: $old" >&2
        exit 1
    fi
    if [ ! -e "$old" ]; then
        echo "path does not exist: $old" >&2
        exit 1
    fi
    mv "$old" "$new"
    echo "renamed $old -> $new"
}

usage() {
    echo "usage: onedriver.sh {state|install|remove|mount|unmount|status|list|delete|rename}" >&2
    exit 1
}

if [ "$#" -lt 1 ]; then
    usage
fi

case "$1" in
    state)   cmd_state ;;
    install) cmd_install ;;
    remove)  cmd_remove ;;
    mount)   cmd_mount ;;
    unmount) cmd_unmount ;;
    status)  cmd_status ;;
    list)    cmd_list "$2" ;;
    delete)  cmd_delete "$2" ;;
    rename)  cmd_rename "$2" "$3" ;;
    *)       usage ;;
esac
