// Dock — floating, magnifying application dock (bottom center).
// Magnification uses a Gaussian falloff + springy easing: responsive at 60 fps
// without the CPU cost of per-icon physics simulations.
import QtQuick
import PlasmaX

Item {
    id: root

    property var apps
    property bool hidden: false
    signal launcherRequested()

    readonly property int count: apps && apps.count !== undefined ? apps.count : 0
    readonly property real iconSize: Theme.dockIcon
    readonly property int padding: Theme.s.md

    height: Theme.dockHeight + Theme.s.xs * 2
    width: dockRow.width + padding * 2
    z: 90

    // Slide away when overlays are up.
    transform: Translate { y: root.hidden ? root.height + Theme.dockInset : 0
                       Behavior on y { NumberAnimation {
                           duration: Theme.motion.base
                           easing.type: Easing.OutCubic } } }
    opacity: root.hidden ? 0.0 : 1.0
    Behavior on opacity { NumberAnimation { duration: Theme.motion.base } }

    GlassSurface {
        anchors.fill: parent
        radius: Theme.r.xl
        backdrop: null
        tintOpacity: 0.38
        sheen: 0.55
        elevated: true
    }

    Row {
        id: dockRow
        anchors.centerIn: parent
        spacing: Theme.s.xs

        Repeater {
            model: root.apps

            delegate: Item {
                id: cell

                required property int index
                required property string name
                required property string icon
                required property bool running

                readonly property real dist: {
                    // HandlerPoint position is in this cell's coordinates.
                    if (!iconMouse.hasHover)
                        return 99999
                    return Math.abs(iconMouse.point.position.x - width / 2)
                }
                readonly property real magnified: {
                    // Gaussian: 1.0 under the cursor → 0.0 beyond 3.5 icons.
                    const sigma = root.iconSize * 1.6
                    return 1.0 + 0.55 * Math.exp(-(dist * dist) / (2 * sigma * sigma))
                }

                width: root.iconSize + Theme.s.sm
                height: root.iconSize + Theme.s.xl + Theme.s.sm

                Item {
                    id: iconBox
                    width: root.iconSize
                    height: root.iconSize
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: Theme.s.xs
                    scale: cell.magnified
                    Behavior on scale { NumberAnimation {
                        duration: Theme.motion.base
                        easing.type: Easing.OutBack
                        easing.overshoot: 0.25 } }

                    // Running indicator dot.
                    Rectangle {
                        visible: cell.running
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.bottom
                        anchors.topMargin: 3
                        width: 4; height: width
                        radius: width / 2
                        color: Theme.accent
                    }

                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.r.md
                        color: Theme.c.surfaceRaised
                        border.width: 1
                        border.color: Theme.c.line
                        scale: cellIconMouse.containsPress ? 0.92 : 1.0
                        Behavior on scale { NumberAnimation { duration: Theme.motion.instant } }

                        // App icon: pixmap from the model when present, glyph fallback.
                        Image {
                            id: appIcon
                            anchors.fill: parent
                            anchors.margins: 6
                            source: cell.icon && cell.icon !== "" ? ("image://icon/" + cell.icon) : ""
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            visible: status === Image.Ready
                        }
                        Text {
                            anchors.centerIn: parent
                            visible: appIcon.status !== Image.Ready
                            text: cell.name.length > 0 ? cell.name.charAt(0).toUpperCase() : "?"
                            font.family: Theme.type.family
                            font.pixelSize: Theme.type.title
                            font.weight: Theme.type.weightSemibold
                            color: Theme.accent
                        }
                    }

                    MouseArea {
                        id: cellIconMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.apps.launchIndex(cell.index)
                        onDoubleClicked: root.launcherRequested()
                    }

                    // Tooltip
                    Rectangle {
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: tipText.width + Theme.s.md
                        height: tipText.height + Theme.s.xs * 2
                        radius: Theme.r.sm
                        color: Theme.c.surfaceRaised
                        border.width: 1
                        border.color: Theme.c.line
                        opacity: cellIconMouse.containsMouse && !cellIconMouse.containsPress ? 0.96 : 0
                        Behavior on opacity { NumberAnimation { duration: Theme.motion.fast } }
                        Text {
                            id: tipText
                            anchors.centerIn: parent
                            text: cell.name
                            font.family: Theme.type.family
                            font.pixelSize: Theme.type.caption
                            color: Theme.c.ink
                        }
                    }
                }

                HoverHandler { id: iconMouse }
            }
        }

        // Separator + launcher button
        Rectangle {
            width: 1
            height: root.iconSize * 0.7
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.c.line
            visible: root.count > 0
        }

        Item {
            width: root.iconSize + Theme.s.sm
            height: root.iconSize + Theme.s.xl
            GlassSurface {
                anchors.fill: parent
                anchors.margins: Theme.s.xs
                radius: Theme.r.md
                backdrop: null
                tintOpacity: 0.5
                sheen: 0.7
            }
            Text {
                anchors.centerIn: parent
                text: "◈"
                font.pixelSize: Theme.type.title
                color: Theme.accent
            }
            MouseArea {
                anchors.fill: parent
                onClicked: root.launcherRequested()
            }
        }
    }

    HoverHandler { id: outer }
}
