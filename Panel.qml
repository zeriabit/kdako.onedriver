import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import qs.Ui

Item {
  id: panel
  moduleName: "kdako.onedriver"
  property var barWidget
  readonly property string script: panel.barWidget ? panel.barWidget.script : ""
  readonly property string mountPoint: Quickshell.env("HOME") + "/OneDrive"

  readonly property bool installed: panel.barWidget ? panel.barWidget.installed : false
  readonly property bool mounted: panel.barWidget ? panel.barWidget.mounted : false
  readonly property string glyph: mounted ? "󰋩" : (installed ? "󰋩" : "󱘝")
  readonly property string statusText: {
    if (!installed) return "Not installed"
    if (mounted) return "Mounted"
    return "Installed - not mounted"
  }

  readonly property color foreground: barWidget ? barWidget.foreground : Color.foreground
  readonly property color dim: panel.barWidget ? barWidget.dim : Qt.darker(foreground, 1.55)
  readonly property color urgent: barWidget ? barWidget.urgent : Color.urgent
  readonly property string fontFamily: barWidget ? barWidget.fontFamily : Style.font.family

  property bool confirmUnmount: false
  property bool confirmDelete: false
  property string confirmDeleteTarget: ""
  property string renameTarget: ""
  property string renameNewName: ""
  property string lastError: ""
  property string currentPath: panel.mountPoint
  property var entries: []
  property bool listing: false

  implicitWidth: 340
  implicitHeight: 480

  Component.onCompleted: refreshList()

  function refreshList() {
    if (!listing) listing = true
    var dir = currentPath || mountPoint
    listProc.command = [script, "list", dir]
    listProc.running = true
  }

  function navigateTo(name) {
    var child = currentPath + "/" + name
    listProc.command = [script, "list", child]
    listProc.running = true
    Qt.callLater(function() {
      currentPath = child
      refreshList()
    })
  }

  function navigateUp() {
    var parts = currentPath.split("/")
    if (parts.length > 3) {
      parts.pop()
      var parent = parts.join("/")
      if (parent === mountPoint || parent === "") parent = mountPoint
      currentPath = parent
      refreshList()
    }
  }

  function deleteEntry(name) {
    var fullPath = currentPath + "/" + name
    if (!confirmDelete) {
      confirmDelete = true
      confirmDeleteTarget = name
      confirmDeleteTimer.restart()
      return
    }
    confirmDelete = false
    confirmDeleteTarget = ""
    barWidget.runInTerminal([script, "delete", fullPath])
    refreshList()
  }

  function startRename(name) {
    renameTarget = name
    renameNewName = name
    renameRow.visible = true
    Qt.callLater(function() { renameField.focus = true })
  }

  function confirmRename() {
    if (renameNewName && renameNewName !== "" && renameNewName !== renameTarget) {
      var fullPath = currentPath + "/" + renameTarget
      barWidget.runInTerminal([script, "rename", fullPath, renameNewName])
    }
    renameTarget = ""
    renameNewName = ""
    renameRow.visible = false
    refreshList()
  }

  function cancelRename() {
    renameTarget = ""
    renameNewName = ""
    renameRow.visible = false
  }

  function formatSize(bytes) {
    if (bytes === 0) return "0 B"
    var units = ["B", "KB", "MB", "GB"]
    var value = bytes
    var index = 0
    while (value >= 1024 && index < units.length - 1) {
      value /= 1024
      index++
    }
    var decimals = value >= 100 ? 0 : (value >= 10 ? 1 : 2)
    return value.toFixed(decimals) + " " + units[index]
  }

  function breadcrumbParts() {
    var parts = []
    var p = currentPath
    if (p === mountPoint) { parts.push("OneDrive"); return parts }
    var segments = p.substring(mountPoint.length).split("/")
    for (var i = 0; i < segments.length; i++) {
      if (segments[i] !== "") parts.push(segments[i])
    }
    return parts
  }

  Column {
    id: column
    width: parent.width
    spacing: Style.space(10)

    PanelHero {
      id: hero
      width: parent.width
      title: "OneDriver Files"
      meta: statusText
      foreground: foreground
      fontFamily: fontFamily
      iconOpacity: installed ? 1.0 : 0.4
      iconComponent: Component {
        Text {
          text: glyph
          color: foreground
          font.family: fontFamily
          font.pixelSize: Style.font.display
        }
      }
    }

    // ---- not installed
    Column {
      visible: !installed
      width: parent.width
      spacing: Style.space(10)

      Hint { text: "The onedriver AUR package is not installed. It provides a FUSE filesystem for Microsoft OneDrive. An AUR helper (yay or paru) is required." }
      Button {
        width: parent.width
        iconText: "󰏗"
        text: "Install from AUR"
        bordered: true
        foreground: foreground
        fontFamily: fontFamily
        onClicked: barWidget.install()
      }
    }

    // ---- installed, not mounted
    Column {
      visible: installed && !mounted
      width: parent.width
      spacing: Style.space(10)

      Hint { text: "onedriver is installed but not running. Mount it to access your OneDrive at ~/OneDrive." }
      Button {
        width: parent.width
        iconText: "󰋩"
        text: "Mount OneDrive"
        bordered: true
        foreground: foreground
        fontFamily: fontFamily
        onClicked: barWidget.mount()
      }

      PanelSeparator {
        visible: true
        foreground: foreground
      }

      Button {
        width: parent.width
        iconText: "󰆴"
        text: "Remove from AUR"
        foreground: urgent
        fontFamily: fontFamily
        fontSize: Style.font.bodySmall
        onClicked: barWidget.remove()
      }
    }

    // ---- mounted: file browser
    Column {
      visible: mounted
      width: parent.width
      spacing: Style.space(8)

      // Path bar
      Row {
        width: parent.width
        spacing: 4
        opacity: 1.0

        Text {
          text: "󰋩"
          color: foreground
          font.family: fontFamily
          font.pixelSize: 14
        }

        Repeater {
          model: breadcrumbParts()
          Text {
            text: modelData
            color: foreground
            font.family: fontFamily
            font.pixelSize: Style.font.bodySmall
            elide: Text.ElideRight
          }
          Rectangle {
            width: 4
            height: 14
            color: dim
          }
        }
      }

      // Up button
      Button {
        width: parent.width
        iconText: "↑"
        text: "Up"
        enabled: currentPath !== mountPoint
        foreground: enabled ? foreground : dim
        fontFamily: fontFamily
        fontSize: Style.font.bodySmall
        onClicked: navigateUp()
      }

      // Column headers
      Row {
        width: parent.width
        spacing: 8
        Text {
          text: "Name"
          color: dim
          font.family: fontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          text: "Size"
          color: dim
          font.family: fontFamily
          font.pixelSize: Style.font.bodySmall
          anchors.right: parent.right
        }
      }

      // File list
      ListView {
        id: fileList
        width: parent.width
        height: 260
        clip: true
        model: entries
        delegate: Rectangle {
          id: row
          width: parent.width
          height: 30
          color: mouse.containsMouse ? "rgba(255,255,255,0.05)" : "transparent"

          Text {
            id: icon
            text: modelData.t === "folder" ? "󰉋" : "󰈙"
            color: modelData.t === "folder" ? foreground : dim
            font.family: fontFamily
            font.pixelSize: 16
            x: 6
            y: 6
          }

          Text {
            text: modelData.n
            color: foreground
            font.family: fontFamily
            font.pixelSize: Style.font.body
            x: icon.x + icon.width + 6
            y: 5
            elide: Text.ElideRight
          }

          Text {
            text: modelData.t === "file" ? formatSize(modelData.s) : ""
            color: dim
            font.family: fontFamily
            font.pixelSize: Style.font.bodySmall
            x: parent.width - 72
            y: 6
          }

          MouseArea {
            id: mouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              if (modelData.t === "folder") {
                var child = currentPath + "/" + modelData.n
                panel.currentPath = child
                panel.refreshList()
              }
            }
            onDoubleClicked: {
              if (modelData.t === "folder") {
                var child = currentPath + "/" + modelData.n
                panel.currentPath = child
                panel.refreshList()
              }
            }
            onPressed: function(b) {
              if (b === Qt.RightButton) {
                if (modelData.t === "folder") panel.startRename(modelData.n)
              }
            }
          }
        }
      }

      // Empty / loading states
      Text {
        visible: entries.length === 0 && !listing
        text: "This folder is empty."
        color: dim
        font.family: fontFamily
        font.pixelSize: Style.font.bodySmall
        width: parent.width
        wrapMode: Text.WordWrap
      }

      Text {
        visible: listing
        text: "Loading…"
        color: dim
        font.family: fontFamily
        font.pixelSize: Style.font.bodySmall
        width: parent.width
      }

      Text {
        visible: lastError !== ""
        width: parent.width
        textFormat: Text.PlainText
        text: lastError
        color: urgent
        font.family: fontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      // Action row
      Row {
        width: parent.width
        spacing: 8

        Button {
          width: parent.width - parent.spacing
          text: confirmDelete
            ? "Confirm delete: " + confirmDeleteTarget
            : "Right-click a folder to rename · Right-click a file to delete"
          enabled: !confirmDelete
          foreground: confirmDelete ? urgent : foreground
          fontFamily: fontFamily
          fontSize: Style.font.bodySmall
          onClicked: {
            if (confirmDelete && confirmDeleteTarget !== "") {
              var target = currentPath + "/" + confirmDeleteTarget
              barWidget.runInTerminal([script, "delete", target])
              confirmDelete = false
              confirmDeleteTarget = ""
              refreshList()
            }
          }
        }
      }
    }
  }

  Timer {
    id: confirmDeleteTimer
    interval: 5000
    onTriggered: confirmDelete = false
  }

  Timer {
    id: confirmUnmountTimer
    interval: 4000
    onTriggered: confirmUnmount = false
  }

  Timer {
    id: refreshTimer
    interval: panel.mounted ? 5000 : 0
    running: panel.mounted && panel.opened
    repeat: true
    triggeredOnStart: false
    onTriggered: panel.refreshList()
  }

  Timer {
    id: renameTimer
    interval: 4000
    onTriggered: {
      if (renameTarget !== "") {
        renameTarget = ""
        renameNewName = ""
        renameRow.visible = false
      }
    }
  }

  // Rename inline row
  Row {
    id: renameRow
    width: parent.width
    visible: renameTarget !== ""
    spacing: 4

    Text {
      text: "Rename " + renameTarget + " to:"
      color: foreground
      font.family: fontFamily
      font.pixelSize: Style.font.bodySmall
    }

    TextField {
      id: renameField
      width: parent.width - 100
      text: renameNewName
      font.family: fontFamily
      font.pixelSize: Style.font.body
      onAccepted: panel.confirmRename()
      onTextChanged: renameNewName = text
    }

    Button {
      width: 46
      text: "Go"
      enabled: renameNewName !== "" && renameNewName !== renameTarget
      foreground: foreground
      fontFamily: fontFamily
      font.pixelSize: Style.font.bodySmall
      onClicked: panel.confirmRename()
    }

    Button {
      width: 46
      text: "×"
      foreground: dim
      fontFamily: fontFamily
      font.pixelSize: Style.font.body
      onClicked: panel.cancelRename()
    }
  }

  component Hint: Text {
    width: parent.width
    textFormat: Text.PlainText
    color: dim
    font.family: fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  Process {
    id: listProc
    command: [panel.script, "list", panel.currentPath]
    workingDirectory: panel.barWidget ? panel.barWidget.pluginDir : ""
    stdout: StdioCollector {
      onStreamFinished: {
        listing = false
        try {
          entries = JSON.parse(text)
          if (!Array.isArray(entries)) entries = []
        } catch (e) {
          entries = []
        }
      }
    }
    onExited: {
      listing = false
      if (text.trim() !== "") {
        try {
          entries = JSON.parse(text)
          if (!Array.isArray(entries)) entries = []
        } catch (e) {
          entries = []
        }
      }
    }
  }
}
