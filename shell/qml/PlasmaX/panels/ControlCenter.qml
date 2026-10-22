// ControlCenter — quick settings: theme, brightness/volume, network, battery
// and the X-Defender security card.
import QtQuick
import QtQuick.Layouts
import PlasmaX

Item {
    id: root

    property var system
    property var defender
    property var api
    property bool expanded: false

    readonly property int panelW: 360

    width: panelW
    height: expanded ? col.implicitHeight + Theme.s.xl * 2 : 0
    clip: true
    z: 120
    visible: height > 2

    Behavior on height { NumberAnimation {
        duration: Theme.motion.slow
        easing.type: Easing.OutBack
        easing.overshoot: 0.25 } }

    function open() { expanded = true }
    function close() { expanded = false }

    GlassSurface {
        anchors.fill: parent
        radius: Theme.r.xl
        backdrop: null
        tintOpacity: 0.55
        sheen: 0.5
        elevated: true
    }

    ColumnLayout {
        id: col
        anchors.fill: parent
        anchors.margins: Theme.s.lg
        spacing: Theme.s.md

        // Toggle grid
        GridLayout {
            Layout.fillWidth: true
            columns: 2
            columnSpacing: Theme.s.sm
            rowSpacing: Theme.s.sm

            Repeater {
                model: [
                    { glyph: "☾", label: "Tema", key: "theme" },
                    { glyph: "wifi", label: root.system ? root.system.networkLabel : "Ağ", key: "net" },
                    { glyph: "◈", label: "PlasmaX", key: "shell" },
                    { glyph: "🛡", label: root.defender ? root.defender.statusLabel : "X-Defender", key: "defender" }
                ]
                delegate: GlassSurface {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.preferredHeight: 52
                    radius: Theme.r.md
                    backdrop: null
                    tintOpacity: 0.38
                    sheen: 0.4

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.s.md
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: Theme.s.sm
                        Text {
                            text: modelData.glyph
                            font.pixelSize: Theme.type.body
                            color: Theme.accent
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text {
                                text: modelData.label
                                font.family: Theme.type.family
                                font.pixelSize: Theme.type.label
                                font.weight: Theme.type.weightMedium
                                color: Theme.c.ink
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (modelData.key === "theme" && root.api) root.api.toggleThemeMode()
                            else if (modelData.key === "shell" && root.api) root.api.openShellSettings()
                        }
                    }
                }
            }
        }

        // Brightness
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.s.xs
            Text {
                text: "☀ Parlaklık"
                font.family: Theme.type.family
                font.pixelSize: Theme.type.caption
                color: Theme.c.inkMuted
            }
            Slider {
                id: bright
                Layout.fillWidth: true
                from: 10
                to: 100
                value: root.system ? root.system.brightness : 80
                onMoved: root.system && root.system.setBrightness(value)
            }
        }

        // Volume
        ColumnLayout {
            Layout.fillWidth: true
            spacing: Theme.s.xs
            Text {
                text: "🔊 Ses"
                font.family: Theme.type.family
                font.pixelSize: Theme.type.caption
                color: Theme.c.inkMuted
            }
            Slider {
                Layout.fillWidth: true
                from: 0
                to: 100
                value: root.system ? root.system.volume : 50
                onMoved: root.system && root.system.setVolume(value)
            }
        }

        // Battery / power
        GlassSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: batRow.implicitHeight + Theme.s.md
            radius: Theme.r.md
            backdrop: null
            tintOpacity: 0.3
            sheen: 0.2

            RowLayout {
                id: batRow
                anchors.fill: parent
                anchors.margins: Theme.s.sm
                Text {
                    text: root.system && root.system.batteryPercent >= 0
                          ? ("⌁ %1% · %2").arg(root.system.batteryPercent)
                                          .arg(root.system.batteryTimeLabel)
                          : "Şarj cihazı bağlı"
                    font.family: Theme.type.family
                    font.pixelSize: Theme.type.label
                    color: Theme.c.ink
                }
                Item { Layout.fillWidth: true }
                GlassButton {
                    label: "Tüm ayarlar"
                    onClicked: root.api && root.api.openSystemSettings()
                }
            }
        }

        // X-Defender card
        GlassSurface {
            Layout.fillWidth: true
            Layout.preferredHeight: defRow.implicitHeight + Theme.s.md
            radius: Theme.r.md
            backdrop: null
            tint: root.defender && root.defender.threats > 0 ? Theme.danger : Theme.mint
            tintOpacity: 0.16
            sheen: 0.3
            visible: root.defender !== null && root.defender !== undefined

            RowLayout {
                id: defRow
                anchors.fill: parent
                anchors.margins: Theme.s.sm
                spacing: Theme.s.sm
                Text {
                    text: "🛡"
                    font.pixelSize: Theme.type.heading
                    anchors.verticalCenter: parent.verticalCenter
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    Text {
                        text: "X-Defender"
                        font.family: Theme.type.family
                        font.pixelSize: Theme.type.label
                        font.weight: Theme.type.weightSemibold
                        color: Theme.c.ink
                    }
                    Text {
                        text: root.defender ? root.defender.statusLabel : "Bağlı değil"
                        font.family: Theme.type.family
                        font.pixelSize: Theme.type.caption
                        color: Theme.c.inkMuted
                    }
                }
                Item { Layout.fillWidth: true }
                GlassButton {
                    label: "Tara"
                    onClicked: root.defender && root.defender.quickScan()
                }
            }
        }
    }
}
