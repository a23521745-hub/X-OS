// GlassButton — primary interactive primitive: press feedback, hover sheen,
// ripple and an optional accent (primary) variant.
import QtQuick
import PlasmaX

GlassSurface {
    id: root

    property string label: ""
    property string glyph: ""          // unicode glyph, see IconGlyph
    property bool primary: false
    property bool danger: false
    property bool checkable: false
    property bool checked: false
    readonly property bool pressed: tap.pressed
    readonly property bool hovered: hover.hovered

    signal clicked()

    radius: primary ? Theme.r.pill : Theme.r.md
    sheen: hover.hovered ? 0.85 : 0.45
    elevated: primary
    backdrop: null
    implicitWidth: contentRow.implicitWidth + Theme.s.xl * 2
    implicitHeight: primary ? 40 : 34
    scale: tap.pressed ? 0.96 : 1.0
    Behavior on scale { NumberAnimation { duration: Theme.motion.instant; easing.type: Easing.OutCubic } }

    // Explicit fallbacks (never re-bind to the property itself — loops).
    tint: primary ? Theme.accent : Theme.g.tint
    tintOpacity: primary ? 0.92 : Theme.g.tintOpacity
    fill: primary ? Theme.accent : Theme.g.fill
    fillStrong: primary ? Theme.accent : Theme.g.fillStrong
    rimColor: danger ? Theme.danger : Theme.g.rim

    Row {
        id: contentRow
        anchors.centerIn: parent
        spacing: Theme.s.sm

        Text {
            visible: root.glyph !== ""
            text: root.glyph
            font.family: Theme.type.fallbackMono
            font.pixelSize: Theme.type.body
            color: "#ffffff"
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.label !== ""
            text: root.label
            font.family: Theme.type.family
            font.pixelSize: Theme.type.label
            font.weight: Theme.type.weightMedium
            color: root.primary ? "#ffffff" : Theme.c.ink
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler { id: hover }
    TapHandler {
        id: tap
        onTapped: {
            if (root.checkable) root.checked = !root.checked
            root.clicked()
        }
    }

    // Ripple
    Rectangle {
        id: ripple
        property real t: 0
        anchors.centerIn: parent
        width: root.width * 1.4 * t
        height: width
        radius: width / 2
        color: "#ffffff"
        opacity: 0
        function restart() {
            t = 0
            opacity = 0.35
            rippleAnim.restart()
        }
        NumberAnimation {
            id: rippleAnim
            target: ripple
            property: "t"
            from: 0
            to: 1
            duration: Theme.motion.slow
            easing.type: Easing.OutCubic
        }
        onTChanged: if (t >= 1) opacity = 0
    }
}
