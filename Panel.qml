import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Item {
  property var barWidget: null

  readonly property string script: barWidget ? barWidget.script : ""
  readonly property string mountPoint: Quickshell.env("HOME") + "/OneDrive"
  readonly property string pluginDir: barWidget ? barWidget.pluginDir : ""

  readonly property bool installed: barWidget ? barWidget.installed : false
  readonly property bool mounted: barWidget ? barWidget.mounted : false

  readonly property color contentForeground: barWidget ? barWidget.foreground : Color.foreground
  readonly property color contentDim: contentForeground ? Qt.darker(contentForeground, 1.55) : Color.foreground
  readonly property color contentUrgent: barWidget ? barWidget.urgent : Color.urgent
  readonly property string contentFontFamily: barWidget ? barWidget.fontFamily : Style.font.family

  readonly property string glyph: mounted ? "[OD]" : (installed ? "[OD]" : "[ND]")
  readonly property string statusText: {
    if (!installed) return "Not installed"
    if (mounted) return "Mounted"
    return "Installed - not mounted"
  }

  property bool confirmDelete: false
  property string confirmDeleteTarget: ""
  property string renameTarget: ""
  property string renameNewName: ""
  property string lastError: ""
  property string currentPath: mountPoint
  property var entries: []
  property bool listing: false

  implicitWidth: 340
  implicitHeight: 480

    Component.onCompleted: {
      if (barWidget) refreshList()
    }

  function refreshList() {
    if (listing) return
    listing = true
    listProc.command = [script, "list", currentPath]
    listProc.running = true
  }

  function navigateTo(name) {
    currentPath = currentPath + "/" + name
    listProc.command = [script, "list", currentPath]
    listProc.running = true
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
    width: parent.width
    spacing: Style.space(10)

    PanelHero {
      width: parent.width
      title: "OneDriver Files"
      meta: statusText
      foreground: contentForeground
      fontFamily: contentFontFamily
      iconOpacity: installed ? 1.0 : 0.4
      iconComponent: Component {
        Text {
          text: glyph
          color: contentForeground
          font.family: contentFontFamily
          font.pixelSize: Style.font.display
        }
      }
    }

    Column {
      visible: !installed
      width: parent.width
      spacing: Style.space(10)

      Hint { text: "The onedriver AUR package is not installed. It provides a FUSE filesystem for Microsoft OneDrive. An AUR helper (yay or paru) is required." }
      Button {
        width: parent.width
        iconText: "[F]"
        text: "Install from AUR"
        bordered: true
        foreground: contentForeground
        fontFamily: contentFontFamily
        fontSize: Style.font.body
        onClicked: barWidget.install()
      }
    }

    Column {
      visible: installed && !mounted
      width: parent.width
      spacing: Style.space(10)

      Hint { text: "onedriver is installed but not running. Mount it to access your OneDrive at ~/OneDrive." }
      Button {
        width: parent.width
        iconText: "[OD]"
        text: "Mount OneDrive"
        bordered: true
        foreground: contentForeground
        fontFamily: contentFontFamily
        fontSize: Style.font.body
        onClicked: barWidget.mount()
      }

      PanelSeparator {
        visible: true
        foreground: contentForeground
      }

      Button {
        width: parent.width
        iconText: "[F]"
        text: "Remove from AUR"
        foreground: contentUrgent
        fontFamily: contentFontFamily
        fontSize: Style.font.bodySmall
        onClicked: barWidget.remove()
      }
    }

    Column {
      visible: mounted
      width: parent.width
      spacing: Style.space(8)

      Row {
        width: parent.width
        spacing: 4
        Text {
          text: "[OD]"
          color: contentForeground
          font.family: contentFontFamily
          font.pixelSize: 14
        }
        Repeater {
          model: breadcrumbParts()
          Text {
            text: modelData
            color: contentForeground
            font.family: contentFontFamily
            font.pixelSize: Style.font.bodySmall
            textFormat: Text.PlainText
            elide: Text.ElideRight
          }
          Rectangle {
            width: 4
            height: 14
            color: contentDim
          }
        }
      }

      Button {
        width: parent.width
        iconText: "Up"
        text: "Up"
        enabled: currentPath !== mountPoint
        foreground: enabled ? contentForeground : contentDim
        fontFamily: contentFontFamily
        fontSize: Style.font.bodySmall
        onClicked: navigateUp()
      }

      Row {
        width: parent.width
        spacing: 8
        Text {
          text: "Name"
          color: contentDim
          font.family: contentFontFamily
          font.pixelSize: Style.font.bodySmall
        }
        Text {
          text: "Size"
          color: contentDim
          font.family: contentFontFamily
          font.pixelSize: Style.font.bodySmall
          x: parent.width - 72
          y: 6
        }
      }

      ListView {
        id: fileList
        width: parent.width
        height: 260
        clip: true
        model: entries
        delegate: Rectangle {
          width: parent.width
          height: 30
          color: rowMouse.hovered ? "rgba(255,255,255,0.05)" : "transparent"

          Text {
            id: icon
            text: modelData.t === "folder" ? "[F]" : "[F]"
            color: modelData.t === "folder" ? contentForeground : contentDim
            font.family: contentFontFamily
            font.pixelSize: 16
            x: 6
            y: 6
          }

          Text {
            text: modelData.n
            color: contentForeground
            font.family: contentFontFamily
            font.pixelSize: Style.font.body
            textFormat: Text.PlainText
            x: icon.x + icon.width + 6
            y: 5
            elide: Text.ElideRight
          }

          Text {
            text: modelData.t === "file" ? formatSize(modelData.s) : ""
            color: contentDim
            font.family: contentFontFamily
            font.pixelSize: Style.font.bodySmall
            textFormat: Text.PlainText
            x: parent.width - 72
            y: 6
          }

          MouseArea {
            id: rowMouse
            anchors.fill: parent
            hoverEnabled: true
            property bool hovered: false
            onEntered: rowMouse.hovered = true
            onExited: rowMouse.hovered = false
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

      Text {
        visible: entries.length === 0 && !listing
        text: "This folder is empty."
        color: contentDim
        font.family: contentFontFamily
        font.pixelSize: Style.font.bodySmall
        width: parent.width
        wrapMode: Text.WordWrap
      }

      Text {
        visible: listing
        text: "Loading..."
        color: contentDim
        font.family: contentFontFamily
        font.pixelSize: Style.font.bodySmall
        width: parent.width
      }

      Text {
        visible: lastError !== ""
        width: parent.width
        textFormat: Text.PlainText
        text: lastError
        color: contentUrgent
        font.family: contentFontFamily
        font.pixelSize: Style.font.bodySmall
        wrapMode: Text.WordWrap
      }

      Row {
        width: parent.width
        spacing: 8
        Button {
          width: parent.width - parent.spacing
          text: confirmDelete
            ? "Confirm delete: " + confirmDeleteTarget
            : "Right-click a folder to rename. Right-click a file to delete"
          enabled: !confirmDelete
          foreground: confirmDelete ? contentUrgent : contentForeground
          fontFamily: contentFontFamily
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
    id: refreshTimer
    interval: mounted ? 5000 : 0
    running: mounted
    repeat: true
    triggeredOnStart: false
    onTriggered: refreshList()
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

  Row {
    id: renameRow
    width: parent.width
    visible: renameTarget !== ""
    spacing: 4

    Text {
      text: "Rename " + renameTarget + " to:"
      color: contentForeground
      font.family: contentFontFamily
      font.pixelSize: Style.font.bodySmall
      textFormat: Text.PlainText
    }

    TextField {
      id: renameField
      width: parent.width - 100
      text: renameNewName
      font.family: contentFontFamily
      font.pixelSize: Style.font.body
      onAccepted: panel.confirmRename()
      onTextChanged: renameNewName = text
    }

    Button {
      width: 46
      text: "Go"
      enabled: renameNewName !== "" && renameNewName !== renameTarget
      foreground: contentForeground
      fontFamily: contentFontFamily
      fontSize: Style.font.bodySmall
      onClicked: panel.confirmRename()
    }

    Button {
      width: 46
      text: "x"
      foreground: contentDim
      fontFamily: contentFontFamily
      fontSize: Style.font.body
      onClicked: panel.cancelRename()
    }
  }

  component Hint: Text {
    width: parent.width
    textFormat: Text.PlainText
    color: contentDim
    font.family: contentFontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }

  Process {
    id: listProc
    command: [script, "list", currentPath]
    workingDirectory: pluginDir
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
