import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import QtQuick

Item {
  id: root
  property var active: ({ kind: "none" })
  readonly property string pluginDir: Qt.resolvedUrl(".").toString().replace(/^file:\/\//, "")

  function refreshActive() { if (!activeProcess.running) activeProcess.running = true }

  // `omarchy plugin add` only installs the QML files. Bootstrap the optional
  // command-line helper and menu entry the first time the service is loaded.
  Process {
    id: bootstrapProcess
    command: ["bash", root.pluginDir + "/install.sh"]
    running: true
    onExited: {
      restoreProcess.running = true
      lockRestoreProcess.running = true
      root.refreshActive()
    }
  }
  Process {
    id: restoreProcess
    command: ["wallpaper-controller", "restore"]
    onExited: root.refreshActive()
  }
  Process {
    id: lockRestoreProcess
    command: ["wallpaper-controller", "lock-restore"]
  }
  Process {
    id: activeProcess
    command: ["wallpaper-controller", "active"]
    stdout: StdioCollector { onStreamFinished: { try { root.active = JSON.parse(text) } catch (error) {} } }
  }
  Process {
    id: dueProcess
    command: ["wallpaper-controller", "due"]
    onExited: root.refreshActive()
  }
  Process {
    id: lockDueProcess
    command: ["wallpaper-controller", "lock-due"]
  }
  Timer {
    interval: 60000
    repeat: true
    running: true
    onTriggered: {
      if (!dueProcess.running) dueProcess.running = true
      if (!lockDueProcess.running) lockDueProcess.running = true
    }
  }
  Timer { interval: 5000; repeat: true; running: true; onTriggered: root.refreshActive() }

  Variants {
    model: Quickshell.screens
    PanelWindow {
      required property var modelData
      screen: modelData
      anchors { top: true; bottom: true; left: true; right: true }
      visible: root.active.kind === "static"
      color: "transparent"
      exclusionMode: ExclusionMode.Ignore
      WlrLayershell.namespace: "wallpaper-controller-static"
      WlrLayershell.layer: WlrLayer.Background
      WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
      Image {
        anchors.fill: parent
        source: root.active.frames ? "file://" + root.active.frames + "/" + modelData.name + ".png" : ""
        fillMode: Image.Stretch
        asynchronous: true
        cache: false
      }
    }
  }
}
