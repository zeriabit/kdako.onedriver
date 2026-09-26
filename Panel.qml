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
  property string lastError: ""

  implicitWidth: 340
  implicitHeight: 480

  Column {
    id: column
    width: parent.width
    spacing: Style.space(12)

    PanelHero {
      id: hero
      width: parent.width
      title: "OneDriver"
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

    // ---- mounted
    Column {
      visible: mounted
      width: parent.width
      spacing: Style.space(10)

      Hint { text: "OneDrive is mounted at ~/OneDrive." }
      Button {
        width: parent.width
        iconText: "󰚌"
        text: confirmUnmount ? "Click to confirm" : "Unmount"
        active: confirmUnmount
        foreground: foreground
        fontFamily: fontFamily
        onClicked: barWidget.unmount()
      }

      Button {
        width: parent.width
        iconText: "󰌘"
        text: "Show status"
        foreground: dim
        fontFamily: fontFamily
        fontSize: Style.font.bodySmall
        onClicked: barWidget.showStatus()
      }
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
  }

  Timer {
    id: confirmTimer
    interval: 4000
    onTriggered: confirmUnmount = false
  }

  component Hint: Text {
    width: parent.width
    textFormat: Text.PlainText
    color: dim
    font.family: fontFamily
    font.pixelSize: Style.font.bodySmall
    wrapMode: Text.WordWrap
  }
}
