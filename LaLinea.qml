import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

// La Linea Walker — all 28 complete numbered episodes, native stage + edge fill.
// Bar icon (BarIcon.qml): standing figure, random bow/hop every 5–18s.
// Click the bar icon → native Omarchy PopupCard with Cavandoli tribute +
// plugin source link (https://github.com/ariDev1/omaLinea).
// episodes/NNN-PP.webp: transparent 30s chunks at 8fps, 400x320.
// episodes/NNN.ogg: uninterrupted original soundtrack for each full episode.
// AnimatedImage decodes the active chunk to RAM (<=240 frames, ~123 MB).
// Summon/toggle: omarchy-shell shell toggle rene.lalinea            (SUPER+L)
// Next scene:      omarchy-shell shell summon rene.lalinea '{"action":"next"}'  (SUPER+SHIFT+L)
// Previous scene:  omarchy-shell shell summon rene.lalinea '{"action":"prev"}'  (SUPER+SHIFT+J)
// Zoom toggle:     omarchy-shell shell summon rene.lalinea '{"action":"toggleFill"}'  (SUPER+SHIFT+Z)
// Force zoom on:   omarchy-shell shell summon rene.lalinea '{"action":"fill"}'
// Force native:    omarchy-shell shell summon rene.lalinea '{"action":"stage"}'
// Direct episode:  omarchy-shell shell summon rene.lalinea '{"episode":120}'
// Zero-based index: omarchy-shell shell summon rene.lalinea '{"scene":19}'
Item {
  id: root

  property var shell: null
  property var manifest: null
  property string omarchyPath: Quickshell.env("OMARCHY_PATH")

  property bool opened: false
  property int sceneIndex: 0

  // false = native size on bottom stage (crisp, your favorite).
  // true = scaled to screen edges (stretched fullscreen).
  // Toggle with SUPER+SHIFT+Z. Implemented as a GPU Scale transform so the
  // AnimatedImage decode size never changes and playback never restarts.
  property bool fillScreen: false

  // Display size multiplier: 1.0 = native 400px, 1.8 = big stage presence.
  // Cheap GPU scaling of the active WebP chunk.
  property real displayScale: 1.8

  readonly property var scenes: {
    // Starts of episodes 101–128, including title cards and endings.
    var starts = [0, 150, 310, 465, 620, 775, 925, 1080, 1230, 1385,
                  1540, 1695, 1850, 2005, 2160, 2315, 2475, 2635, 2790,
                  2945, 3100, 3260, 3420, 3575, 3730, 3880, 4035, 4190,
                  4345.901]
    var result = []
    for (var i = 0; i < starts.length - 1; i++) {
      var number = 101 + i
      var duration = starts[i + 1] - starts[i]
      result.push({ name: "Episode " + number, number: number, duration: duration,
                    parts: Math.ceil(duration / 30), audio: "episodes/" + number + ".ogg" })
    }
    return result
  }
  property int partIndex: 0
  readonly property string partUrl: "episodes/" + scenes[sceneIndex].number + "-" + ("0" + partIndex).slice(-2) + ".webp"

  readonly property string audioPath: {
    var u = String(Qt.resolvedUrl(scenes[sceneIndex].audio));
    return u.replace(/^file:\/\//, "");
  }

  // Wall-clock anchor for A/V sync. Audio (mpv) runs free while video
  // (AnimatedImage) can stall on chunk loads or fullscreen GPU scaling.
  // elapsed() lets us seek audio back to video on zoom toggles.
  property double episodeStartMs: 0
  function episodeElapsed() {
    if (episodeStartMs <= 0) return partIndex * 30
    var e = (Date.now() - episodeStartMs) / 1000
    var d = scenes[sceneIndex].duration
    if (e < 0) return 0
    if (e > d - 0.1) return d - 0.1
    return e
  }

  function setScene(i) {
    var n = scenes.length
    root.sceneIndex = ((i % n) + n) % n
    if (root.opened) startEpisode()
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
    if (!root.opened) { root.open('{"action":"fill"}'); return }
    // GPU transform only: never touch partIndex, timers, or audio here.
    // The previous resyncAv() seeked mpv to the wall-clock position while
    // the WebP chunk restarts at its own frame 0, which guaranteed drift.
    root.fillScreen = !root.fillScreen
  }
  function restartAudio() {
    audioProc.running = false
    audioProc.command = ["mpv", "--no-video", "--really-quiet", "--volume=80", root.audioPath]
    restartTimer.restart()
  }
  function seekAudio(offsetSec) {
    var off = Math.min(Math.max(0, offsetSec), Math.max(0, scenes[sceneIndex].duration - 0.2))
    audioProc.running = false
    audioProc.command = ["mpv", "--no-video", "--really-quiet", "--volume=80", "--start=" + off.toFixed(2), root.audioPath]
    restartTimer.restart()
  }
  function resyncAv() {
    var elapsed = root.episodeElapsed()
    var p = Math.min(Math.floor(elapsed / 30), root.scenes[root.sceneIndex].parts - 1)
    if (p < 0) p = 0
    root.partIndex = p
    var intoPart = elapsed - p * 30
    var remain = Math.min(30 - intoPart, root.scenes[root.sceneIndex].duration - elapsed)
    if (remain < 1) remain = 1
    partTimer.stop()
    partTimer.interval = Math.round(remain * 1000)
    partTimer.start()
    // Re-anchor the clock now; restartTimer adds ~300ms before mpv resumes,
    // so shift the anchor forward to keep video from running ahead.
    root.episodeStartMs = Date.now() - elapsed * 1000 + 300
    root.seekAudio(elapsed)
  }

  function startEpisode() {
    partTimer.stop()
    root.partIndex = 0
    root.episodeStartMs = Date.now()
    partTimer.interval = Math.round(Math.min(30, root.scenes[root.sceneIndex].duration) * 1000)
    partTimer.start()
    restartAudio()
  }

  Timer {
    id: partTimer
    interval: 30000
    repeat: false
    onTriggered: {
      if (!root.opened) return
      if (root.partIndex + 1 < root.scenes[root.sceneIndex].parts) {
        root.partIndex++
        var remain = Math.min(30, root.scenes[root.sceneIndex].duration - root.partIndex * 30)
        partTimer.interval = Math.round(remain * 1000)
        partTimer.start()
      } else {
        root.startEpisode()
      }
    }
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
      if (typeof p.episode === "number" && p.episode >= 101 && p.episode <= 128 && Math.floor(p.episode) === p.episode)
        root.sceneIndex = p.episode - 101
      else if (typeof p.scene === "number" && isFinite(p.scene)) root.sceneIndex = ((Math.floor(p.scene) % scenes.length) + scenes.length) % scenes.length
      else if (p.action === "next") { root.opened = true; root.setScene(root.sceneIndex + 1); return }
      else if (p.action === "prev") { root.opened = true; root.setScene(root.sceneIndex - 1); return }
      else if (p.action === "toggleFill") {
        root.fillScreen = !root.fillScreen
        if (!root.opened) { root.opened = true; root.startEpisode() }
        // When already open: flip the GPU transform only. Do NOT restart
        // or seek anything — AnimatedImage keeps its current frame, mpv
        // keeps playing, so they stay in sync.
        return
      }
      else if (p.action === "fill") { root.fillScreen = true }
      else if (p.action === "stage") { root.fillScreen = false }
    } catch (e) {}
    root.opened = true
    startEpisode()
  }
  function close() {
    root.opened = false
    partTimer.stop()
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

  // A shell restart while open orphans the looping mpv (fresh shell, no
  // owner — the rant plays forever with nobody to stop it). Reap any stale
  // rant audio from this plugin exactly once at load; at startup no live
  // instance exists, so every match is an orphan by definition.
  Process {
    id: orphanReap
    command: ["pkill", "-f", "rene\\.lalinea/.*\\.ogg"]
    running: true
  }

  // One continuous audio track per episode; visual chunks change independently.
  Process {
    id: audioProc
    command: ["mpv", "--no-video", "--really-quiet", "--volume=80", root.audioPath]
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

      // GPU-only zoom: the AnimatedImage keeps its native decode size in
      // both modes. Fill mode scales the whole layer via transform, so the
      // movie never reloads/restarts (a restart would replay the 30s chunk
      // from frame 0 while mpv audio keeps real time = permanent desync).
      property real zoomX: root.fillScreen && walker.width > 0 ? stage.width / walker.width : 1
      property real zoomY: root.fillScreen && walker.height > 0 ? stage.height / walker.height : 1

      Item {
        id: zoomLayer
        anchors.fill: parent
        transform: Scale {
          xScale: stage.zoomX
          yScale: stage.zoomY
          origin.x: stage.width / 2
          origin.y: stage.height
        }

        // Native stage size, always: aspect-correct bottom display.
        // Fill mode stretches via zoomLayer, not by resizing the image.
        AnimatedImage {
          id: walker
          anchors.bottom: parent.bottom
          anchors.bottomMargin: 0
          anchors.horizontalCenter: parent.horizontalCenter
          width: Math.min(stage.width * 0.8, 400 * root.displayScale)
          height: width * 0.8
          source: Qt.resolvedUrl(root.partUrl)
          playing: root.opened
          cache: false
          asynchronous: true
          smooth: true
          fillMode: Image.PreserveAspectFit
        }
      }

      Text {
        anchors.right: parent.right
        anchors.rightMargin: 18
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 12
        text: "La Linea • " + root.scenes[root.sceneIndex].name + " (" + (root.sceneIndex + 1) + "/" + root.scenes.length + ") • " + (root.fillScreen ? "EDGE FILL" : "native") + " • SUPER+L dismiss, SHIFT+L/J episodes, SHIFT+Z zoom"
        color: "white"
        opacity: 0.55
        font.pixelSize: 13
      }
    }
  }
}
