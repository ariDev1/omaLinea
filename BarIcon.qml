import QtQuick
import QtQuick.Controls
import QtQuick.Effects
import Quickshell
import qs.Commons
import qs.Ui

// La Linea bar icon — he stands in your bar and fidgets, randomly.
// Poses are authentic keyed frames (stand + bow). Click opens the
// Omarchy-style episode picker and tribute card (PopupCard, bar-anchored).
BarWidget {
  id: root
  moduleName: "rene.lalinea"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property bool cardOpen: false
  readonly property string repoUrl: "https://github.com/ariDev1/omaLinea"

  function selectEpisode(number) {
    root.close()
    if (root.bar && root.bar.shell)
      root.bar.shell.summon("rene.lalinea", JSON.stringify({ episode: number }))
  }

  // Widget panel contract: programmatic open/close alongside the click toggle.
  property alias opened: root.cardOpen
  function open() { root.cardOpen = true }
  function close() { root.cardOpen = false }

  // Outer-scope state the iconComponent binds to (ids inside a
  // Component can't be targeted from outside, so we animate these).
  property bool bowing: false
  property real hopY: 0

  // Random life: every 5–18s he either bows, hops, or stands straight.
  Timer {
    id: lifeTimer
    interval: 7000
    repeat: true
    running: true
    onTriggered: {
      interval = 5000 + Math.random() * 13000
      var roll = Math.random()
      if (roll < 0.45) root.bowing = !root.bowing
      else if (roll < 0.7) hopAnim.restart()
      else root.bowing = false
    }
  }

  SequentialAnimation {
    id: hopAnim
    PropertyAnimation { target: root; property: "hopY"; to: -4; duration: 140; easing.type: Easing.OutQuad }
    PropertyAnimation { target: root; property: "hopY"; to: 0; duration: 200; easing.type: Easing.BounceOut }
  }

  BarIconButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    tooltipText: "La Linea — choose an episode"
    iconComponent: Item {
      // Same look and feel as glyph icons: tinted to bar foreground via
      // MultiEffect (adapts to dark/light themes like every other icon).
      // Sized to the optical canvas ×1.25 (~20px in a 27px slot) so the
      // thin line figure stays legible instead of shrinking to 16px.
      readonly property real iconPx: Math.round(button.opticalSize * 1.25)
      y: root.hopY
      Image {
        id: lineArt
        anchors.centerIn: parent
        width: parent.iconPx
        height: parent.iconPx
        source: root.bowing ? Qt.resolvedUrl("icon-bow.png") : Qt.resolvedUrl("icon-stand.png")
        fillMode: Image.PreserveAspectFit
        smooth: true
        sourceSize.width: Math.round(parent.iconPx * Screen.devicePixelRatio)
        sourceSize.height: Math.round(parent.iconPx * Screen.devicePixelRatio)
        visible: false
        layer.enabled: true
      }
      MultiEffect {
        anchors.fill: lineArt
        source: lineArt
        colorization: 1.0
        colorizationColor: button.foreground
      }
    }
    onPressed: root.cardOpen = !root.cardOpen
  }

  // Native Omarchy dropdown: themed card, anchored under the bar icon,
  // outside-click dismisses it — same component the tray uses.
  PopupCard {
    id: card
    anchorItem: button
    owner: root
    bar: root.bar
    open: root.cardOpen
    contentWidth: card.fittedContentWidth(Style.space(360))
    contentHeight: card.fittedContentHeight(cardColumn.implicitHeight, Style.space(520))

    Flickable {
      id: cardScroll
      anchors.fill: parent
      contentWidth: width
      contentHeight: cardColumn.implicitHeight
      clip: true
      boundsBehavior: Flickable.StopAtBounds
      flickableDirection: Flickable.VerticalFlick
      interactive: contentHeight > height
      ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

      Column {
        id: cardColumn
        width: cardScroll.width
        spacing: Style.space(8)

        Row {
          spacing: Style.space(10)
          width: parent.width

          Image {
            source: Qt.resolvedUrl("icon-stand.png")
            width: 40
            height: 40
            fillMode: Image.PreserveAspectFit
            smooth: true
            anchors.verticalCenter: parent.verticalCenter
          }

          Column {
            spacing: 2
            anchors.verticalCenter: parent.verticalCenter

            Text {
              text: "La Linea"
              color: root.bar.foreground
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.title
              font.bold: true
            }
            Text {
              text: "Unofficial fan tribute"
              color: Qt.darker(root.bar.foreground, 1.4)
              font.family: root.bar.fontFamily
              font.pixelSize: Style.font.caption
            }
          }
        }

        Text {
          width: parent.width
          text: "Choose an episode · 101–128"
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true
        }

        Grid {
          id: episodeGrid
          width: parent.width
          columns: 4
          spacing: Style.space(6)

          Repeater {
            model: 28
            delegate: Rectangle {
              id: episodeCell
              required property int index
              readonly property int episodeNumber: 101 + index
              width: (episodeGrid.width - episodeGrid.spacing * 3) / 4
              height: Style.space(32)
              radius: Math.max(2, Style.cornerRadius)
              color: cellMouse.containsMouse
                ? Style.hoverFillFor(root.bar.foreground, Color.accent)
                : Style.normalFillFor(root.bar.foreground, Color.accent)

              Text {
                anchors.centerIn: parent
                text: episodeCell.episodeNumber
                color: root.bar.foreground
                font.family: root.bar.fontFamily
                font.pixelSize: Style.font.body
                font.bold: true
              }

              MouseArea {
                id: cellMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.selectEpisode(episodeCell.episodeNumber)
              }
            }
          }
        }

        Text {
          width: parent.width
          wrapMode: Text.WordWrap
          text: "Created by Osvaldo Cavandoli (1920–2007). Voice of the rant: Carlo Bonomi. First aired 1969 — grazie, Maestro."
          color: root.bar.foreground
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
        }

        Text {
          width: parent.width
          wrapMode: Text.WrapAnywhere
          textFormat: Text.RichText
          text: 'Official tribute: <a href="https://osvaldocavandoli.com/la-linea/">osvaldocavandoli.com</a>'
          linkColor: Color.accent
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          onLinkActivated: function(link) { Qt.openUrlExternally(link) }
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
          }
        }

        Text {
          width: parent.width
          wrapMode: Text.WrapAnywhere
          textFormat: Text.RichText
          text: 'Plugin source: <a href="' + root.repoUrl + '">github.com/ariDev1/omaLinea</a>'
          linkColor: Color.accent
          color: Qt.darker(root.bar.foreground, 1.4)
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          onLinkActivated: function(link) { Qt.openUrlExternally(link) }
          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.NoButton
            cursorShape: parent.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
          }
        }

        Text {
          width: parent.width
          text: "▶ Summon La Linea on stage"
          color: Color.accent
          font.family: root.bar.fontFamily
          font.pixelSize: Style.font.body
          font.bold: true

          MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: {
              root.close()
              if (root.bar) root.bar.shell.summon("rene.lalinea", "{}")
            }
          }
        }
      }
    }
  }
}
