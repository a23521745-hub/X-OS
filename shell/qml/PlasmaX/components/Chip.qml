// Chip — compact pill used across TopBar, ControlCenter and notifications.
import QtQuick
import PlasmaX

Item {
    id: root

    property string label: ""
    property string glyph: ""
    property color accent: "transparent"
    property bool active: false
    property alias hovered: hover.hovered
    property int paddingH: Theme.s.md

    signal clicked()

    implicitWidth: content.implicitWidth + paddingH * 2
    implicitHeight: 30

    GlassSurface {
        anchors.fill: parent
        radius: Theme.r.pill
        backdrop: null
        tintOpacity: root.active ? 0.55 : 0.32
        fill: root.active ? Theme.accentSoft : Theme.g.fill
        sheen: 0.3
        elevated: false
        opacity: root.hovered ? 1.0 : 0.92
        Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
    }

    Row {
        id: content
        anchors.centerIn: parent
        spacing: Theme.s.xs

        Text {
            visible: root.glyph !== ""
            text: root.glyph
            font.pixelSize: Theme.type.caption
            color: root.active ? Theme.accent : (Theme.mode === "light" ? Theme.light.inkMuted
                                                                        : Theme.dark.inkMuted)
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            visible: root.label !== ""
            text: root.label
            font.family: Theme.type.family
            font.pixelSize: Theme.type.caption
            font.weight: Theme.type.weightMedium
            color: Theme.mode === "light" ? Theme.light.ink : Theme.dark.ink
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    HoverHandler { id: hover }
    TapHandler { onTapped: root.clicked() }
}
