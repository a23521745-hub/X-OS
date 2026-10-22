// LockScreen — heavily blurred wallpaper, oversized clock, avatar + password.
import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import PlasmaX

Item {
    id: root

    property var api

    function unlock() {
        if (root.api && root.api.tryUnlock(pin.text)) {
            pin.text = ""
            visible = false
        } else {
            shake.restart()
            pin.text = ""
        }
    }

    visible: false

    // Heavy blur of whatever sits underneath: our own wallpaper.
    ShaderEffectSource {
        id: blurred
        anchors.fill: parent
        sourceItem: parent.parent   // the shell window content
        live: true
        visible: false
    }
    MultiEffect {
        anchors.fill: parent
        source: blurred
        blurEnabled: true
        blur: 1.0
        saturation: 0.9
    }

    Rectangle { anchors.fill: parent; color: "#04060A"; opacity: 0.35 }

    ClockService { id: clock }

    ColumnLayout {
        anchors.centerIn: parent
        spacing: Theme.s.lg

        Text {
            text: clock.timeString
            font.family: Theme.type.family
            font.pixelSize: 96
            font.weight: Theme.type.weightMedium
            color: "#FFFFFF"
            Layout.alignment: Qt.AlignHCenter
        }
        Text {
            text: clock.dateString
            font.family: Theme.type.family
            font.pixelSize: Theme.type.heading
            color: "#FFFFFF"
            opacity: 0.85
            Layout.alignment: Qt.AlignHCenter
        }

        Item { Layout.preferredHeight: Theme.s.lg }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.s.lg

            Rectangle {
                width: 56; height: width
                radius: width / 2
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Theme.accent }
                    GradientStop { position: 1.0; color: Theme.cyan }
                }
                Text {
                    anchors.centerIn: parent
                    text: "X"
                    font.family: Theme.type.family
                    font.pixelSize: Theme.type.title
                    font.weight: Theme.type.weightSemibold
                    color: "#fff"
                }
            }

            GlassSurface {
                width: 260
                height: 44
                radius: Theme.r.pill
                backdrop: null
                tint: "#000000"
                tintOpacity: 0.45
                sheen: 0.3

                TextInput {
                    id: pin
                    anchors.fill: parent
                    anchors.leftMargin: Theme.s.lg
                    anchors.rightMargin: Theme.s.lg
                    echoMode: TextInput.Password
                    font.family: Theme.type.family
                    font.pixelSize: Theme.type.heading
                    color: "#FFFFFF"
                    verticalAlignment: TextInput.AlignVCenter
                    clip: true
                    onAccepted: root.unlock()
                    focus: root.visible

                    Text {
                        visible: pin.text === ""
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Parola"
                        font: pin.font
                        color: "#FFFFFF"
                        opacity: 0.5
                    }

                    SequentialAnimation on x {
                        id: shake
                        NumberAnimation { to: 8;  duration: 60; easing.type: Easing.OutQuad }
                        NumberAnimation { to: -8; duration: 120 }
                        NumberAnimation { to: 0;  duration: 60; easing.type: Easing.InOutQuad }
                    }
                }
            }

            GlassButton { label: "Giriş"; primary: true; onClicked: root.unlock() }
        }

        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.api && root.api.lockHint !== "" ? root.api.lockHint : ""
            font.family: Theme.type.family
            font.pixelSize: Theme.type.caption
            color: "#FFFFFF"
            opacity: 0.55
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.s.md
            GlassButton { label: "Uyku"; onClicked: root.api && root.api.suspend() }
            GlassButton { label: "Kapat"; danger: true; onClicked: root.api && root.api.shutdown() }
        }
    }
}
