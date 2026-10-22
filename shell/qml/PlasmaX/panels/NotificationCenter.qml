// NotificationCenter — toast/banner queue + pull-down history panel.
import QtQuick
import QtQuick.Layouts
import PlasmaX

Item {
    id: root

    property var model: []
    property bool expanded: false

    width: 360
    height: expanded ? Math.min(col.implicitHeight + Theme.s.xl * 2, 520) : 0
    clip: true
    z: 130
    visible: height > 2

    Behavior on height { NumberAnimation {
        duration: Theme.motion.slow
        easing.type: Easing.OutBack
        easing.overshoot: 0.2 } }

    function open() { expanded = true }
    function close() { expanded = false }

    GlassSurface {
        anchors.fill: parent
        radius: Theme.r.xl
        backdrop: null
        tintOpacity: 0.55
        sheen: 0.4
        elevated: true
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.s.lg
        spacing: Theme.s.md

        RowLayout {
            Layout.fillWidth: true
            Text {
                text: "Bildirimler"
                font.family: Theme.type.family
                font.pixelSize: Theme.type.heading
                font.weight: Theme.type.weightSemibold
                color: Theme.c.ink
            }
            Item { Layout.fillWidth: true }
            GlassButton {
                label: "Temizle"
                onClicked: root.model = []
            }
            GlassButton {
                label: "×"
                onClicked: root.close()
            }
        }

        // Empty state
        Text {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: Theme.s.xl
            visible: root.model.length === 0
            text: "Sessiz ve sakin."
            font.family: Theme.type.family
            font.pixelSize: Theme.type.body
            color: Theme.c.inkFaint
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: Theme.s.sm
            model: root.model

            delegate: GlassSurface {
                required property var modelData
                Layout.fillWidth: true
                radius: Theme.r.lg
                backdrop: null
                tintOpacity: 0.32
                sheen: 0.25

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: Theme.s.md
                    spacing: Theme.s.xs

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: modelData.app || "X-OS"
                            font.family: Theme.type.family
                            font.pixelSize: Theme.type.label
                            font.weight: Theme.type.weightSemibold
                            color: Theme.c.ink
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: modelData.time || ""
                            font.family: Theme.type.family
                            font.pixelSize: Theme.type.caption
                            color: Theme.c.inkFaint
                        }
                    }
                    Text {
                        Layout.fillWidth: true
                        text: modelData.body || ""
                        wrapMode: Text.WordWrap
                        font.family: Theme.type.family
                        font.pixelSize: Theme.type.body
                        color: Theme.c.inkMuted
                    }
                }
            }
        }
    }
}
