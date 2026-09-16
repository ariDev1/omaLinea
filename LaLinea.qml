import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// La Linea Walker v3.6 — 14 original Cavandoli scenes, native stage + edge fill.
// Bar icon (BarIcon.qml): standing figure, random bow/hop every 5–18s.
// Click the bar icon → native Omarchy PopupCard with Cavandoli tribute +
// plugin source link (https://github.com/ariDev1/omaLinea).
// Scene files: walk.gif/rant.ogg (violin, 28s) + scene1..13 gif/ogg (12-40s).
// Extended 2026-09-16: scene2 23s->35s, scene3 12s->30s, scene4 18s->35s @8fps.
// Added 2026-09-16: scene10 Duel (ss420), scene11 Beers (ss880), scene12 Ball (ss2500), 30s @8fps.
// Added 2026-09-16: scene13 Tennis (ss2282, 22s @8fps, navy key 0x00053E).
// Added 2026-09-16: edge-to-edge zoom toggle (SUPER+SHIFT+Z).
// NOTE: AnimatedImage decodes ALL frames to RAM (~400x320x4 bytes each).
// Keep GIFs <= ~400 frames @400px wide or scenes go black/frozen.
// Zoom is GPU scaling of the same decoded frames — safe at any size.
// Summon/toggle: omarchy-shell shell toggle rene.lalinea            (SUPER+L)
// Next scene:      omarchy-shell shell summon rene.lalinea '{"action":"next"}'  (SUPER+SHIFT+L)
// Previous scene:  omarchy-shell shell summon rene.lalinea '{"action":"prev"}'  (SUPER+SHIFT+J)
// Zoom toggle:     omarchy-shell shell summon rene.lalinea '{"action":"toggleFill"}'  (SUPER+SHIFT+Z)
// Force zoom on:   omarchy-shell shell summon rene.lalinea '{"action":"fill"}'
// Force native:    omarchy-shell shell summon rene.lalinea '{"action":"stage"}'
// Direct scene:    omarchy-shell shell summon rene.lalinea '{"scene":2}'
Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  property bool opened: false
  property int sceneIndex: 0

  // false = native size on bottom stage (crisp, your favorite).
  // true = scaled to screen edges (stretched fullscreen).
  // Toggle with SUPER+SHIFT+Z. GPU scaling only — same decoded frames.
  property bool fillScreen: false

  // Display size multiplier: 1.0 = native 400px, 1.8 = big stage presence.
  // Cheap (GPU scale) — unlike bigger GIF files which break AnimatedImage.
  property real displayScale: 1.8

  readonly property var scenes: [
    { name: "Violin",       gif: "walk.gif",   audio: "rant.ogg"   },
    { name: "Car repair",   gif: "scene1.gif", audio: "scene1.ogg" },
    { name: "Umbrella",     gif: "scene2.gif", audio: "scene2.ogg" },
    { name: "Piano",        gif: "scene3.gif", audio: "scene3.ogg" },
    { name: "Car push",     gif: "scene4.gif", audio: "scene4.ogg" },
    { name: "Trumpet",      gif: "scene5.gif", audio: "scene5.ogg" },
    { name: "Fight cloud",  gif: "scene6.gif", audio: "scene6.ogg" },
    { name: "Car stack",    gif: "scene7.gif", audio: "scene7.ogg" },
    { name: "Trapeze",      gif: "scene8.gif", audio: "scene8.ogg" },
    { name: "Steps",        gif: "scene9.gif", audio: "scene9.ogg" },
    { name: "Duel",         gif: "scene10.gif", audio: "scene10.ogg" },
    { name: "Beers",        gif: "scene11.gif", audio: "scene11.ogg" },
    { name: "Ball",         gif: "scene12.gif", audio: "scene12.ogg" },
    { name: "Tennis",       gif: "scene13.gif", audio: "scene13.ogg" }
  ]

  readonly property string audioPath: {
    var u = String(Qt.resolvedUrl(scenes[sceneIndex].audio));
    return u.replace(/^file:\/\//, "");
  }

  function setScene(i) {
    var n = scenes.length
    root.sceneIndex = ((i % n) + n) % n
    if (root.opened) restartAudio()
  }
  function next() {
    var was = root.opened
    root.setScene(root.sceneIndex + 1)
    if (!was) root.open("{}")
  }
  function prev() {
    var was = root.opened
    root.setScene(root.sceneIndex - 1)
    if (!was) root.open("{}")
  }
  function toggleFill() {
    if (!root.opened) root.open('{"action":"fill"}')
    else root.fillScreen = !root.fillScreen
  }
  function restartAudio() {
    audioProc.running = false
    audioProc.command = ["mpv", "--no-video", "--loop-file=inf", "--really-quiet", "--volume=80", root.audioPath]
    restartTimer.restart()
  }

  Timer {
    id: restartTimer
    interval: 300
    repeat: false
    onTriggered: { if (root.opened) audioProc.running = true }
  }

  function open(payloadJson) {
    try {
      var p = JSON.parse(payloadJson || "{}")
      if (typeof p.scene === "number") root.sceneIndex = ((p.scene % scenes.length) + scenes.length) % scenes.length
      else if (p.action === "next") { root.opened = true; root.setScene(root.sceneIndex + 1); return }
      else if (p.action === "prev") { root.opened = true; root.setScene(root.sceneIndex - 1); return }
      else if (p.action === "toggleFill") { root.opened = true; root.fillScreen = !root.fillScreen; restartAudio(); return }
      else if (p.action === "fill") { root.fillScreen = true }
      else if (p.action === "stage") { root.fillScreen = false }
    } catch (e) {}
    root.opened = true
    restartAudio()
  }
  function close() {
    root.opened = false
    restartTimer.stop()
    if (audioProc.running) audioProc.running = false
  }
  function toggle() {
    if (root.opened) root.dismiss()
    else root.open("{}")
  }
  function dismiss() {
    root.close()
    if (root.shell && typeof root.shell.hide === "function")
      root.shell.hide("rene.lalinea")
  }

  // Original rant audio per scene, looped for as long as he is on stage.
  Process {
    id: audioProc
    command: ["mpv", "--no-video", "--loop-file=inf", "--really-quiet", "--volume=80", root.audioPath]
  }

  PanelWindow {
    id: panel
    visible: root.opened
    anchors { top: true; bottom: true; left: true; right: true }
    color: "transparent"
    WlrLayershell.namespace: "omarchy-lalinea"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    exclusionMode: ExclusionMode.Ignore
    // Fully click-through: he never steals clicks from your windows.
    // SUPER+L dismiss, SUPER+SHIFT+L / SUPER+SHIFT+J cycle scenes, SUPER+SHIFT+Z zoom.
    mask: Region {}

    Item {
      id: stage
      anchors.fill: parent

      // Native stage: aspect-correct bottom display (crisp favorite).
      // Fill mode: stretched to screen edges (SUPER+SHIFT+Z toggles).
      // Both are GPU scaling of the same small decoded GIF — always safe.
      AnimatedImage {
        id: walker
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 0
        anchors.horizontalCenter: parent.horizontalCenter
        width: root.fillScreen ? stage.width : Math.min(stage.width * 0.8, 400 * displayScale)
        height: root.fillScreen ? stage.height : width * 0.8
        source: Qt.resolvedUrl(scenes[sceneIndex].gif)
        playing: root.opened
        cache: false
        asynchronous: true
        smooth: true
        fillMode: root.fillScreen ? Image.Stretch : Image.PreserveAspectFit
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        text: "La Linea • " + scenes[sceneIndex].name + " (" + (sceneIndex + 1) + "/" + scenes.length + ") • " + (root.fillScreen ? "EDGE FILL" : "native") + " • SUPER+L dismiss, SHIFT+L/J scenes, SHIFT+Z zoom"
        color: "white"
        opacity: 0.55
        font.pixelSize: 13
      }
    }
  }
}
