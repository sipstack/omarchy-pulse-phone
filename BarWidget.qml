// Pulse Phone — Omarchy bar widget.
//
// Deliberately dumb: a static Pulse icon that shows and hides the phone. It
// reports no call state, because the bar cannot see inside the browser window
// that hosts the PWA, and faking it would be worse than omitting it.
//
// The phone itself is the live Pulse PWA in a Chromium --app window; all the
// real work happens in bin/pulse-phone.
import QtQuick

Item {
  id: root

  // Injected by the bar host at load time.
  property var bar
  property string moduleName
  property var settings

  // Resolved against this file, so the widget works immediately after
  // `omarchy plugin add` — no PATH entry and no install step required.
  readonly property string script: {
    var p = Qt.resolvedUrl("bin/pulse-phone").toString()
    return p.indexOf("file://") === 0 ? p.substring(7) : p
  }

  readonly property int glyphSize: (settings && settings.iconSize) ? settings.iconSize : 18

  implicitWidth: glyphSize + 6
  implicitHeight: bar ? bar.barSize : 26

  Image {
    id: icon
    anchors.centerIn: parent
    source: Qt.resolvedUrl("assets/icon.png")
    width: root.glyphSize
    height: root.glyphSize
    sourceSize.width: root.glyphSize * 2
    sourceSize.height: root.glyphSize * 2
    smooth: true
    mipmap: true
    opacity: hoverArea.containsMouse ? 1.0 : 0.82

    Behavior on opacity {
      NumberAnimation { duration: 120; easing.type: Easing.OutQuad }
    }
  }

  // Fallback if the icon asset is ever missing: a text mark rather than a hole
  // in the bar.
  Text {
    anchors.centerIn: parent
    visible: icon.status === Image.Error
    text: "Pulse"
    color: bar ? bar.foreground : "white"
    font.family: bar ? bar.fontFamily : "monospace"
    font.pixelSize: 11
  }

  MouseArea {
    id: hoverArea
    anchors.fill: parent
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    onEntered: if (bar) bar.showTooltip(root, "Pulse Phone\n\nleft: show/hide · middle: dialpad · right: quit")
    onExited: if (bar) bar.hideTooltip(root)

    // Qt6 form: take the event as a named parameter rather than relying on
    // the deprecated injected `mouse` signal argument. Named `ev` so it cannot
    // shadow this MouseArea's id.
    onClicked: function (ev) {
      if (!bar)
        return
      var q = bar.shellQuote ? bar.shellQuote(root.script) : ("'" + root.script + "'")
      if (ev.button === Qt.RightButton)
        bar.run(q + " quit")
      else if (ev.button === Qt.MiddleButton)
        bar.run(q + " dialpad")
      else
        bar.run(q + " toggle")
    }
  }
}
