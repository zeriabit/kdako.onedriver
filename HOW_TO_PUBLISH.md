# How to publish a new Omarchy bar plugin

## What was done for kdako.onedriver

1. Created the plugin directory at `~/.config/omarchy/plugins/kdako.onedriver/`
   with `manifest.json`, `Panel.qml`, `onedriver.sh`, `README.md`, `LICENSE`.
2. Initialized a git repo inside that directory.
3. Created the GitHub repo via `gh repo create zeriabit/kdako.onedriver --public`.
4. Added the remote and pushed: `git push -u origin master`.
5. Enabled it in the Omarchy bar: `omarchy plugin enable kdako.onedriver --section right`.

## How to do the same for a new plugin

### Prerequisites

- `gh` CLI authenticated to GitHub (`gh auth login`).
- The plugin directory ready under `~/.config/omarchy/plugins/<id>/`.

### Steps

```bash
# 1. cd into the plugin dir
cd ~/.config/omarchy/plugins/<plugin-id>

# 2. init and commit
git init
git add -A
git commit -m "Initial commit"

# 3. create the GitHub repo (public example)
gh repo create <github-user>/<repo-name> --public --description "..." --confirm

# 4. push
git push -u origin master
```

`<github-user>` is the GitHub account that will own the repo. On this system
that's `zeriabit` (the `gh` authenticated user). The plugin id (`kdako.onedriver`)
doesn't have to match the GitHub repo name, but keeping them aligned helps.

### To enable on the local bar after publishing

```bash
omarchy plugin enable <plugin-id> --section right
```

### To install from the published repo on another machine

```bash
omarchy plugin add https://github.com/<user>/<repo>.git --enable
```

### To update after editing

```bash
cd ~/.config/omarchy/plugins/<plugin-id>
git add -A
git commit -m "changes"
git push
```

Then on the user machine: `omarchy plugin update <plugin-id>`.

## Notes

- The repo was created under `zeriabit` because that's the `gh` authenticated
  account. If you want it under `kdako`, authenticate `gh` as `kdako` or create
  the repo manually on github.com and push to it.
- The plugin is currently enabled on this bar. Disable with:
  `omarchy plugin disable kdako.onedriver`.
- The `onedriver.sh` helper runs in a floating terminal launched by the bar.
  It requires `yay` or `paru` for AUR installs.

## Repo URL

https://github.com/zeriabit/kdako.onedriver
