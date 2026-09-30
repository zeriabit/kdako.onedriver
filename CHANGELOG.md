# Changelog

## v1.2.3 (2026-09-30)

### Fixed
- **Rename destination now constrained to OneDrive.** `confirmRename()` in Panel.qml builds the new path relative to the source folder (parent of `currentPath` + new name) instead of passing a bare name to `onedriver.sh`, whose `mv` would resolve it against the terminal's working directory. A folder rename from the panel can no longer move the folder out of `~/OneDrive` or collide with an unrelated local entry.
- **Folder navigation restored.** `MouseArea.onClicked` and `onDoubleClicked` in the file list no longer reference an unresolved `panel` id. The root `Item` now has `id: panel`, and the handlers use direct scope lookup (`currentPath = child`, `refreshList()`). Single-click and double-click on a folder row navigate into it again.
- **PanelHero icon Text hardened.** The icon `Text` element rendering the `glyph` property now sets `textFormat: Text.PlainText` to match the security baseline for all file-derived text.

### Defense in depth
- `onedriver.sh cmd_rename` already resolved both `old` and `new` with `readlink -f` and rejected destinations outside `$MOUNT_POINT`. The QML-side fix closes the path-construction gap so the wrong destination is never proposed to the script in the first place.

### Security baseline
- All `Text` elements in Panel.qml that render file-derived content (`modelData.n`, `modelData.t`, `renameTarget`, breadcrumb segments, `glyph`, `lastError`) now explicitly set `textFormat: Text.PlainText`.
- Verified at HEAD `6f666153ba0306f9cd4cd7b99f89688aae82cbcd` against baseline `e20d008c11274649f2cf76f4e58ba453c56ed3eb`.

## v1.2.1 (previous)
- Also render file icon text (`modelData.t`) as plain text.

## v1.2.0 (previous)
- ASCII cleanup: replaced all em dashes (U+2014) with "--" throughout onedriver.sh and README.md.
- Fixed Row anchor warning: "Size" column header in plain Row now uses explicit `x`/`y` instead of `Layout.alignment`.
- Fixed deferred-init warnings on contentForeground/contentUrgent/contentFontFamily properties with null guards.
- Panel initializes file list refresh only after `barWidget` is available.
