import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

// La Linea bar icon — he stands in your bar and fidgets, randomly.
// Poses are authentic keyed frames (stand + bow). Click opens the
// Omarchy-style tribute card (PopupCard, anchored top-right).
BarWidget {
  id: root
  moduleName: "rene.lalinea"

  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  property bool cardOpen: false
  readonly property string repoUrl: "https://github.com/ariDev1/omaLinea"

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
    tooltipText: "La Linea — click to honor Osvaldo Cavandoli"
    iconComponent: Item {
      Image {
        anchors.centerIn: parent
        y: root.hopY
        source: root.bowing ? Qt.resolvedUrl("icon-bow.png") : Qt.resolvedUrl("icon-stand.png")
        fillMode: Image.PreserveAspectFit
        smooth: true
        width: 22
        height: 22
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
    contentWidth: card.fittedContentWidth(Style.space(300))
    contentHeight: card.fittedContentHeight(cardColumn.implicitHeight)

    Column {
      id: cardColumn
      anchors.fill: parent
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
