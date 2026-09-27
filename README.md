# OneDriver -- Omarchy bar widget

Install, mount, unmount, and browse the `onedriver` AUR package (FUSE OneDrive filesystem) from the Omarchy bar.

## What it manages

`onedriver` is a FUSE filesystem that mounts your Microsoft OneDrive at `~/OneDrive`. This widget:

- Detects whether `onedriver` is installed and whether it is currently mounted.
- Starts/stops the daemon from the bar.
- Opens a floating panel to browse `~/OneDrive`, rename folders, and delete files.
- Runs AUR install/remove operations through an AUR helper (yay or paru).

## Install

The widget is a bar widget. Add it to your bar with:

```
omarchy plugin add https://github.com/zeriabit/kdako.onedriver.git
omarchy bar put kdako.onedriver
```

Or enable it from the Omarchy plugin manager.

## Requirements

- An AUR helper: `yay` or `paru` must be installed and usable by your user.
- `onedriver` itself is installed and updated through the AUR helper, not manually.
- The real `onedriver` binary is expected at `/usr/bin/onedriver` after install.

## Bar usage

- Left-click the icon to open the file browser panel.
- Middle-click to show a short status line in a floating terminal.
- The icon reflects state:
  - `[ND]` -- not installed
  - `[OD]` (dim) -- installed but not mounted
  - `[OD]` -- mounted

When mounted, open the panel and you can:

- Navigate folders.
- Rename a folder with a right-click.
- Delete a file or folder with a right-click.

AUR operations (install/remove) are delegated to a floating terminal so you can see output and confirm anything unusual.

## Buttons in the panel

- **Install from AUR** -- when `onedriver` is not installed.
- **Mount OneDrive** -- when installed but not running.
- **Remove from AUR** -- removes the package and stops the daemon.
- **Up** -- go to the parent folder in the browser.

## Files

- `BarWidget.qml` -- bar icon/button and state polling.
- `Panel.qml` -- popup file browser panel.
- `onedriver.sh` -- shell backend for install/mount/unmount/state/listing.

## Notes

- This widget does not sync or touch your OneDrive account directly. It only manages the local FUSE daemon and lets you browse the mounted tree.
- If the daemon fails to start, open the terminal button from the bar icon to inspect logs/output.

## v1.2.0 changes

- Fixed ASCII-cleanup: replaced all em dashes (U+2014) with "--" throughout onedriver.sh and README.md so the plugin passes ASCII-clean verification.
- Fixed Row anchor warning in Panel.qml: the "Size" column header inside a plain Row was using `Layout.alignment` (which only works inside RowLayout/ColumnLayout). Changed to explicit `x`/`y` positioning.
- Fixed deferred-init warnings on Panel.qml contentForeground/contentUrgent/contentFontFamily properties: these properties read from `barWidget` before the Loader injects it, causing transient `undefined` assignments. Added null guards so they fall back to defaults cleanly during early init.
- Panel.qml now initializes the file list refresh only after `barWidget` is available (Component.onCompleted guarded with `if (barWidget) refreshList()`).
