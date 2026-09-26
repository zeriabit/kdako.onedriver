# kdako.onedriver — OneDriver Omarchy Bar Plugin

Manages the [onedriver](https://aur.archlinux.org/packages/onedriver/) AUR package
(a FUSE filesystem for Microsoft OneDrive) from the Omarchy bar.

## What it does

- Shows whether `onedriver` is installed and whether your OneDrive is currently
  mounted at `~/OneDrive`.
- Installs `onedriver` from the AUR (requires `yay` or `paru`).
- Mounts / unmounts your OneDrive filesystem.
- **Browse files** — open the panel to browse, rename, and delete files and
  folders on your local OneDrive mount.

## Install

```bash
mkdir -p ~/.config/omarchy/plugins
git clone <this-repo-url> ~/.config/omarchy/plugins/kdako.onedriver
omarchy plugin enable kdako.onedriver --section right
```

Then click the OneDriver icon in the bar and follow the panel.

## Requirements

- Arch Linux with an AUR helper (`yay` or `paru`).
- The `onedriver` package: https://aur.archlinux.org/packages/onedriver/
- `python3` (used by the file browser for JSON directory listing; no extra packages needed).

## File browser (v1.1.0)

When OneDrive is mounted, the panel shows a file browser for `~/OneDrive`:

- **Navigate** — click a folder to open it, or use **Up** to go to the parent.
- **Breadcrumb** — shows your path inside OneDrive; click any segment to jump.
- **Rename** — right-click a folder, type a new name, press Enter.
- **Delete** — right-click a file or folder and confirm.
- **Refresh** — the list refreshes automatically every 5 seconds while open.

## Mount point

Defaults to `~/OneDrive`. To change it, edit the `MOUNT_POINT` variable in
`onedriver.sh`.

## Shell commands

`onedriver.sh` accepts: `state`, `install`, `remove`, `mount`, `unmount`,
`status`, `list`, `delete`, `rename`.

## Removal

```bash
omarchy plugin disable kdako.onedriver
omarchy plugin remove kdako.onedriver
```

Then optionally remove the AUR package:

```bash
yay -Rns onedriver   # or paru -Rns onedriver
```

## License

MIT
