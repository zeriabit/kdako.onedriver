# kdako.onedriver - OneDriver Omarchy Bar Plugin

Manages the [onedriver](https://aur.archlinux.org/packages/onedriver/) AUR package
(a FUSE filesystem for Microsoft OneDrive) from the Omarchy bar.

## What it does

- Shows whether `onedriver` is installed and whether your OneDrive is currently
  mounted at `~/OneDrive`.
- Installs `onedriver` from the AUR (requires `yay` or `paru`).
- Mounts / unmounts your OneDrive filesystem.

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

## Mount point

Defaults to `~/OneDrive`. To change it, edit the `MOUNT_POINT` variable in
`onedriver.sh`.

## License

MIT
