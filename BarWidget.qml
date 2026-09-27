import QtQuick
import Quickshell
import Quickshell.Io
import qs.Commons
import qs.Ui

BarWidget {
  id: root
  moduleName: "kdako.onedriver"

  readonly property string script: String(Qt.resolvedUrl("onedriver.sh")).replace(/^file:\/\//, "")
  readonly property string pluginDir: root.script.replace(/\/[^/]+$/, "")
  readonly property string mountPoint: Quickshell.env("HOME") + "/OneDrive"

  // Transient state populated by the state process.
  property bool installed: false
  property bool mounted: false
  property bool open: false

  readonly property string glyph: mounted ? "[OD]" : (installed ? "[OD]" : "[ND]")
  readonly property string statusText: {
    if (!installed) return "Not installed"
    if (mounted) return "Mounted"
    return "Installed - not mounted"
  }

  // Reference the backing script so the bar can surface install/remove buttons.
  readonly property string description: "Install, mount, and browse the onedriver AUR package."

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

  property string lastError: ""
  property bool confirmUnmount: false

  onOpenChanged: {
    if (open) { root.lastError = ""; refresh() }
    else { root.confirmUnmount = false }
  }

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
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
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      var p = item
      if (p) {
        p.barWidget = root
        if ("bar" in p) p.bar = root.bar
      }
    }
  }

  Process {
    id: stateProc
    command: [root.script, "state"]
    stdout: StdioCollector {
      onStreamFinished: {
        var kv = ({})
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
