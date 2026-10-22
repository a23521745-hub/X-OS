// StickerLayer — draggable desktop stickers with spring physics.
//
// Stickers persist as JSON through xos.settings (SettingsStore, C++), so they
// survive logout and are shared between sessions.  Edit mode is entered from
// the Launcher's "Stickers" tab; long-press/Alt+drag moves them any time.
import QtQuick
import PlasmaX

Item {
    id: root

    property int topInset: 0
    property int bottomInset: 0
    property bool editMode: false

    // Loaded from SettingsStore (array of {id, glyph, x, y, rot, scale, color}).
    property var stickers: settingsBridge && settingsBridge.stickers ? settingsBridge.stickers : []

    // The shell passes `xos.settings` down via the context; guard for previews.
    property var settingsBridge: null

    Repeater {
        model: root.stickers

        delegate: Item {
            id: sticker
            required property var modelData
            readonly property int idx: index

            x: modelData.x
            y: modelData.y
            width: 96 * (modelData.scale || 1)
            height: width
            rotation: modelData.rot || 0
            z: drag.active ? 1000 : 10

            // Springy placement: settles instead of snapping.
            Behavior on x { NumberAnimation {
                duration: Theme.motion.base
                easing.type: Theme.lightMode ? Easing.OutCubic : Easing.OutBack
                easing.overshoot: 0.4
            } }
            Behavior on y { NumberAnimation {
                duration: Theme.motion.base
                easing.type: Easing.OutBack
                easing.overshoot: 0.4
            } }

            scale: drag.active ? 1.08 : (root.editMode ? 1.0 : 0.98)

            GlassSurface {
                anchors.fill: parent
                radius: Theme.r.lg
                backdrop: null
                tint: modelData.color || Theme.accentSoft
                tintOpacity: 0.85
                sheen: 0.7
                elevated: true
            }

            Text {
                anchors.centerIn: parent
                text: modelData.glyph || "✦"
                font.pixelSize: parent.width * 0.45
                color: Theme.c.ink
            }

            // Delete badge in edit mode.
            Rectangle {
                visible: root.editMode
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.rightMargin: -6
                anchors.topMargin: -6
                width: 22; height: width
                radius: width / 2
                color: Theme.danger
                Text {
                    anchors.centerIn: parent
                    text: "×"
                    color: "#fff"
                    font.pixelSize: 14
                    font.bold: true
                }
                TapHandler {
                    onTapped: {
                        const next = root.stickers.filter((_, i) => i !== sticker.idx)
                        root.stickers = next
                        if (root.settingsBridge) root.settingsBridge.saveStickers(next)
                    }
                }
            }

            DragHandler {
                id: drag
                target: sticker
                onReleased: {
                    // Snap to a subtle grid so scattered stickers stay tidy.
                    const nx = Math.round(sticker.x / 24) * 24
                    const ny = Math.round(sticker.y / 24) * 24
                    sticker.x = nx
                    sticker.y = ny
                    if (root.settingsBridge) {
                        const next = root.stickers.map((s, i) =>
                            i === sticker.idx ? Object.assign({}, s, { x: nx, y: ny }) : s)
                        root.stickers = next
                        root.settingsBridge.saveStickers(next)
                    }
                }
            }
        }
    }

    // Empty state hint in edit mode.
    Text {
        visible: root.editMode && root.stickers.length === 0
        anchors.centerIn: parent
        text: "Sticker eklemek için Launcher → Stickers"
        font.family: Theme.type.family
        font.pixelSize: Theme.type.heading
        color: Theme.c.inkMuted
        opacity: 0.9
    }
}
