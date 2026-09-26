import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

// OneDriver - manages the onedriver AUR package (FUSE OneDrive filesystem)
// from the Omarchy bar: install, mount, unmount.
Panel {
  id: root
  moduleName: "kdako.onedriver"
  ipcTarget: "kdako.onedriver"

  readonly property string script: String(Qt.resolvedUrl("onedriver.sh")).replace(/^file:\/\//, "")
  readonly property string mountPoint: Quickshell.env("HOME") + "/OneDrive"

  // ---- state from onedriver.sh state
  property bool installed: false
  property bool mounted: false

  // ---- ui state
  property bool busy: false
  property bool confirmUnmount: false
  property string lastError: ""

  readonly property string glyph: mounted ? "󰋩" : (installed ? "󰋩" : "󱘝")
  readonly property string statusText: {
    if (!installed) return "Not installed"
    if (mounted) return "Mounted"
    return "Installed - not mounted"
  }

  readonly property color foreground: bar ? bar.foreground : Color.foreground
  readonly property color dim: Qt.darker(foreground, 1.55)
  readonly property color urgent: bar ? bar.urgent : Color.urgent
  readonly property string fontFamily: bar ? bar.fontFamily : Style.font.family

  function refresh() {
    if (!stateProc.running) stateProc.running = true
  }

  function runInTerminal(args) {
    var quoted = args.map(function(a) { return "'" + String(a).replace(/'/g, "'\\''") + "'" }).join(" ")
    if (bar) bar.run("omarchy-launch-floating-terminal-with-presentation " + quoted)
    close()
  }

  function install() { runInTerminal([script, "install"]) }

  function mount() { runInTerminal([script, "mount"]) }

  function unmount() {
    if (!confirmUnmount) { confirmUnmount = true; confirmTimer.restart(); return }
    confirmUnmount = false
    runInTerminal([script, "unmount"])
  }

  function showStatus() { runInTerminal([script, "status"]) }

  onOpenedChanged: {
    if (opened) { lastError = ""; refresh() }
    else { confirmUnmount = false }
  }

  // ---- state process
  Process {
    id: stateProc
    command: [root.script, "state"]
    stdout: StdioCollector {
      onStreamFinished: {
        var kv = ({ })
        String(text).split("\n").forEach(function(line) {
          var i = line.indexOf("=")
          if (i > 0) kv[line.slice(0, i)] = line.slice(i + 1)
        })
        root.installed = kv.installed === "true"
        root.mounted  = kv.mounted  === "true"
        if (root.busy) root.busy = false
      }
    }
  }

  Timer {
    id: confirmTimer
    interval: 4000
    onTriggered: root.confirmUnmount = false
  }

  Timer {
    interval: root.opened ? 2000 : 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }

  // ---- bar button
  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyph
    dimmed: !root.installed
    tooltipText: root.opened ? "" : "OneDriver: " + root.statusText
    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.showStatus()
      else root.toggle()
    }
  }

  // ---- panel
  KeyboardPanel {
    id: panel
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.opened
    contentWidth: panel.fittedContentWidth(Style.space(340))
    contentHeight: panel.fittedContentHeight(column.implicitHeight, Style.space(480))

    PanelKeyCatcher {
      id: keyCatcher
      anchors.fill: parent
      onActivateRequested: root.close()
      onCloseRequested: root.close()
      onTextKey: function(t) {
        if (t === " " || t === "t" || t === "T") root.refresh()
        else if (t === "i" || t === "I") { if (root.installed) return; root.install() }
        else if (t === "m" || t === "M") { if (!root.installed || root.mounted) return; root.mount() }
        else if (t === "u" || t === "U") { if (!root.installed || !root.mounted) return; root.unmount() }
      }

      Column {
        id: column
        width: parent.width
        spacing: Style.space(12)

        PanelHero {
          id: hero
          width: parent.width
          title: "OneDriver"
          meta: root.statusText
          foreground: root.foreground
          fontFamily: root.fontFamily
          iconOpacity: root.installed ? 1.0 : 0.4
          iconComponent: Component {
            Text {
              text: root.glyph
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Style.font.display
            }
          }
        }

        // ---- not installed
        Column {
          visible: !root.installed
          width: parent.width
          spacing: Style.space(10)

          Hint { text: "The onedriver AUR package is not installed. It provides a FUSE filesystem for Microsoft OneDrive. An AUR helper (yay or paru) is required." }
          Button {
            width: parent.width
            iconText: "󰏗"
            text: "Install from AUR"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.install()
          }
        }

        // ---- installed, not mounted
        Column {
          visible: root.installed && !root.mounted
          width: parent.width
          spacing: Style.space(10)

          Hint { text: "onedriver is installed but not running. Mount it to access your OneDrive at ~/OneDrive." }
          Button {
            width: parent.width
            iconText: "󰋩"
            text: "Mount OneDrive"
            bordered: true
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.mount()
          }
        }

        // ---- mounted
        Column {
          visible: root.mounted
          width: parent.width
          spacing: Style.space(10)

          Hint { text: "OneDrive is mounted at ~/OneDrive." }
          Button {
            width: parent.width
            iconText: "󰚌"
            text: root.confirmUnmount ? "Click to confirm" : "Unmount"
            active: root.confirmUnmount
            foreground: root.foreground
            fontFamily: root.fontFamily
            onClicked: root.unmount()
          }

          Button {
            width: parent.width
            iconText: "󰌘"
            text: "Show status"
            foreground: root.dim
            fontFamily: root.fontFamily
            fontSize: Style.font.bodySmall
            onClicked: root.showStatus()
          }
        }

        Text {
          visible: root.lastError !== ""
          width: parent.width
          textFormat: Text.PlainText
          text: root.lastError
          color: root.urgent
          font.family: root.fontFamily
          font.pixelSize: Style.font.bodySmall
          wrapMode: Text.WordWrap
        }
      }
    }
  }

  component Hint: Text {
    width: parent.width
    textFormat: Text.PlainText
    color: root.dim
    font.family: root.fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }
}
