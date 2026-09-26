import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

Panel {
  id: root
  moduleName: "kdako.onedriver"
  ipcTarget: "kdako.onedriver"

  readonly property string script: String(Qt.resolvedUrl("onedriver.sh")).replace(/^file:\/\//, "")
  readonly property string mountPoint: Quickshell.env("HOME") + "/OneDrive"

  property bool installed: false
  property bool mounted: false
  property bool open: false

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
    open = false
  }

  function install() { runInTerminal([script, "install"]) }
  function remove() { runInTerminal([script, "remove"]) }
  function mount() { runInTerminal([script, "mount"]) }

  function unmount() {
    if (!confirmUnmount) { confirmUnmount = true; confirmTimer.restart(); return }
    confirmUnmount = false
    runInTerminal([script, "unmount"])
  }

  function showStatus() { runInTerminal([script, "status"]) }

  function openPanel() { open = true }
  function closePanel() { open = false }

  onOpenChanged: {
    if (open) { lastError = ""; refresh() }
    else { confirmUnmount = false }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: root.glyph
    dimmed: !root.installed
    tooltipText: root.open ? "" : "OneDriver: " + root.statusText
    onPressed: function(b) {
      if (b === Qt.MiddleButton) root.showStatus()
      else root.open = !root.open
    }
  }

  Loader {
    id: panelLoader
    source: Qt.resolvedUrl("Panel.qml")
    visible: root.open
    onLoaded: {
      var p = item
      if (p) {
        p.barWidget = root
      }
    }
  }

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
    interval: root.open ? 2000 : 5000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.refresh()
  }
}
