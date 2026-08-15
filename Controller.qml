import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts
import qs.Commons as Commons
import qs.Ui as Ui

Item {
  id: root

  property bool opened: false
  property bool reopenAfterPicker: false
  property var shell: null
  property var entries: []
  property var cycleEntries: []
  property string activeId: ""
  property bool rotationEnabled: true
  property int intervalMinutes: 30
  property string query: ""

  readonly property color foreground: Commons.Color.menu.text
  readonly property color surface: Commons.Color.menu.background
  readonly property color border: Commons.Color.menu.border
  readonly property color accent: Commons.Color.accent
  readonly property string fontFamily: Commons.Style.font.menuFamily

  function open() { opened = true; reload() }
  function close() { opened = false }
  function reload() { if (!listProcess.running) listProcess.running = true }
  function run(args) { commandProcess.command = ["wallpaper-controller"].concat(args); commandProcess.running = true }
  function selected(id) { return cycleEntries.indexOf(id) >= 0 }
  function pickStaticImages() {
    reopenAfterPicker = true
    opened = false
    Qt.callLater(function() { pickerProcess.running = true })
  }

  IpcHandler {
    target: "priyesh.wallpaper-controller"
    function toggle() { root.opened ? root.close() : root.open() }
    function show() { root.open() }
    function hide() { root.close() }
  }

  Process {
    id: listProcess
    command: ["wallpaper-controller", "entries"]
    stdout: StdioCollector {
      onStreamFinished: {
        try {
          var response = JSON.parse(text)
          if (Array.isArray(response.entries)) root.entries = response.entries
          if (Array.isArray(response.cycle)) root.cycleEntries = response.cycle
          root.activeId = String(response.active || "")
          if (response.settings) {
            root.rotationEnabled = response.settings.rotationEnabled === true
            root.intervalMinutes = Number(response.settings.intervalMinutes || 30)
          }
        } catch (error) {}
      }
    }
  }

  Process { id: commandProcess; onExited: root.reload() }

  Process {
    id: pickerProcess
    command: ["zenity", "--file-selection", "--multiple", "--separator=\n", "--title=Add static wallpapers"]
    stdout: StdioCollector {
      onStreamFinished: {
        var paths = text.trim().split("\n").filter(function(path) { return path.length > 0 })
        if (paths.length) root.run(["add-static"].concat(paths))
      }
    }
    onExited: {
      if (!root.reopenAfterPicker) return
      Qt.callLater(function() {
        root.reopenAfterPicker = false
        root.opened = true
        root.reload()
      })
    }
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: Qt.rgba(Commons.Color.background.r, Commons.Color.background.g, Commons.Color.background.b, 0.78)
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Rectangle {
      anchors.centerIn: parent
      width: Math.min(parent.width - Commons.Style.space(64), Commons.Style.space(1300))
      height: Math.min(parent.height - Commons.Style.space(64), Commons.Style.space(820))
      radius: Commons.Style.cornerRadius
      color: root.surface
      border.color: root.border
      border.width: Commons.Style.normalBorderWidth

      Keys.onEscapePressed: root.close()

      ColumnLayout {
        anchors.fill: parent
        anchors.margins: Commons.Style.spacing.popupPadding
        spacing: Commons.Style.spacing.md

        RowLayout {
          Layout.fillWidth: true
          spacing: Commons.Style.spacing.sm

          Text {
            text: "Wallpaper Controller"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Commons.Style.font.title
            font.bold: true
            Layout.fillWidth: true
          }
          Ui.Button { text: "Add images"; bordered: true; onClicked: root.pickStaticImages() }
          Ui.Button { text: "Next"; bordered: true; onClicked: root.run(["cycle"]) }
          Ui.Button { text: "Close"; bordered: true; onClicked: root.close() }
        }

        RowLayout {
          Layout.fillWidth: true
          spacing: Commons.Style.spacing.md

          Ui.TextField {
            id: search
            Layout.fillWidth: true
            placeholderText: "Search wallpapers"
            onTextChanged: root.query = text.toLowerCase()
          }
          Text {
            text: "Rotation"
            color: root.foreground
            font.family: root.fontFamily
            font.pixelSize: Commons.Style.font.body
          }
          Ui.ToggleSwitch {
            checked: root.rotationEnabled
            onToggled: root.run(["settings", root.rotationEnabled ? "false" : "true", String(minutes.value)])
          }
          Ui.NumberField {
            id: minutes
            label: "Every (minutes)"
            from: 5
            to: 1440
            value: root.intervalMinutes
            onModified: function(value) { root.run(["settings", root.rotationEnabled ? "true" : "false", String(value)]) }
          }
        }

        Text {
          text: "Click a card to apply it. Toggle the marker to include it in the shuffle rotation. Long-press a static image to remove it."
          color: Qt.darker(root.foreground, 1.35)
          font.family: root.fontFamily
          font.pixelSize: Commons.Style.font.caption
          Layout.fillWidth: true
          wrapMode: Text.WordWrap
        }

        GridView {
          Layout.fillWidth: true
          Layout.fillHeight: true
          clip: true
          cellWidth: Commons.Style.space(220)
          cellHeight: Commons.Style.space(190)
          model: root.entries.filter(function(entry) { return !root.query || entry.title.toLowerCase().indexOf(root.query) >= 0 })

          delegate: Item {
            required property var modelData
            width: Commons.Style.space(220)
            height: Commons.Style.space(190)

            readonly property bool current: root.activeId === modelData.id
            readonly property bool hot: cardMouse.containsMouse

            Rectangle {
              anchors.fill: parent
              anchors.margins: Commons.Style.spacing.xs
              radius: Commons.Style.cornerRadius
              color: current ? Commons.Style.selectedFillFor(root.foreground, root.accent)
                : (hot ? Commons.Style.hoverFillFor(root.foreground, root.accent) : Commons.Style.normalFillFor(root.foreground, root.accent))
              border.color: modelData.valid ? (current ? root.accent : root.border) : Commons.Color.urgent
              border.width: Commons.Style.normalBorderWidth
            }

            Image {
              anchors { left: parent.left; right: parent.right; top: parent.top; margins: Commons.Style.spacing.sm }
              height: Commons.Style.space(112)
              source: modelData.preview ? "file://" + modelData.preview : ""
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: false
              visible: status === Image.Ready
            }

            Text {
              anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Commons.Style.spacing.sm }
              text: modelData.title + (modelData.valid ? "" : "\nMissing file")
              color: root.foreground
              font.family: root.fontFamily
              font.pixelSize: Commons.Style.font.bodySmall
              wrapMode: Text.WordWrap
              maximumLineCount: 2
            }

            Ui.ToggleSwitch {
              z: 2
              anchors { top: parent.top; right: parent.right; margins: Commons.Style.spacing.sm }
              checked: root.selected(modelData.id)
              onToggled: root.run(["toggle-cycle", modelData.id])
            }

            MouseArea {
              id: cardMouse
              z: 1
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: root.run(["apply", modelData.id])
              onPressAndHold: if (modelData.kind === "static") root.run(["remove-static", modelData.id])
            }
          }
        }
      }
    }
  }
}
