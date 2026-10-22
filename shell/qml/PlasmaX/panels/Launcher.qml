// Launcher — full-screen application launcher with search, grid, stickers
// and power actions.  The backdrop blurs the wallpaper; the content floats on
// a large Liquid Glass card that scales in with a springy ease.
import QtQuick
import QtQuick.Layouts
import PlasmaX

Item {
    id: root

    property var apps
    property Item backdrop
    property bool stickerEditMode: false
    property alias searchField: search

    readonly property bool open: visible

    function toggle() { visible ? close() : openIt() }
    function openIt() {
        visible = true
        search.text = ""
        grid.currentIndex = 0
        search.forceActiveFocus()
    }
    function close() {
        visible = false
        stickerEditMode = false
    }

    visible: false

    // Scrim
    Rectangle {
        anchors.fill: parent
        color: "#05070B"
        opacity: 0.45
        visible: root.visible
        Behavior on opacity { NumberAnimation { duration: Theme.motion.base } }
    }

    MouseArea { anchors.fill: parent; onClicked: root.close() }

    // Card
    GlassSurface {
        id: card
        width: Math.min(parent.width - Theme.s.xxl * 2, Theme.launcherWidth)
        height: Math.min(parent.height - Theme.s.xxl * 2, Theme.launcherHeight)
        anchors.centerIn: parent
        radius: Theme.r.xxl
        backdrop: root.backdrop
        blurAmount: 1.0
        sheen: 0.75
        elevated: true
        visible: root.visible
        scale: root.visible ? 1.0 : 0.94
        opacity: root.visible ? 1.0 : 0.0
        Behavior on scale { NumberAnimation {
            duration: Theme.motion.slow
            easing.type: Easing.OutBack
            easing.overshoot: 0.35 } }
        Behavior on opacity { NumberAnimation { duration: Theme.motion.base } }

        MouseArea { anchors.fill: parent; z: -1 }   // swallow clicks

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.s.xl
            spacing: Theme.s.lg

            // ── search ───────────────────────────────────────────────────────
            GlassSurface {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: Theme.r.pill
                backdrop: null
                tintOpacity: 0.35
                sheen: 0.3

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: Theme.s.lg
                    anchors.rightMargin: Theme.s.lg
                    spacing: Theme.s.sm

                    Text { text: "⌕"; font.pixelSize: Theme.type.heading; color: Theme.c.inkMuted }

                    TextInput {
                        id: search
                        Layout.fillWidth: true
                        verticalAlignment: TextInput.AlignVCenter
                        font.family: Theme.type.family
                        font.pixelSize: Theme.type.heading
                        color: Theme.c.ink
                        clip: true
                        focus: root.visible
                        Keys.onEscapePressed: root.close()
                        Keys.onReturnPressed: if (grid.currentItem) grid.currentItem.activate()

                        Text {
                            visible: search.text === ""
                            anchors.verticalCenter: parent.verticalCenter
                            text: "Uygulama ara…"
                            font: search.font
                            color: Theme.c.inkFaint
                        }
                    }
                }
            }

            // ── tabs ─────────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.s.sm

                Chip { label: "Uygulamalar"; active: !root.stickerEditMode
                       onClicked: root.stickerEditMode = false }
                Chip { label: "Stickers"; active: root.stickerEditMode
                       onClicked: root.stickerEditMode = true }
                Item { Layout.fillWidth: true }

                Chip { label: "⟳ Yenile"; onClicked: if (root.apps) root.apps.refresh() }
            }

            // ── content ──────────────────────────────────────────────────────
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.stickerEditMode ? 1 : 0

                // Grid
                GridView {
                    id: grid
                    clip: true
                    model: root.apps
                    cellWidth: 116
                    cellHeight: 108
                    boundsBehavior: Flickable.StopAtBounds
                    keyNavigationEnabled: true

                    delegate: Item {
                        id: cell
                        required property int index
                        required property string name
                        required property string comment
                        required property string icon
                        readonly property bool selected: GridView.isCurrentItem

                        width: grid.cellWidth
                        height: grid.cellHeight

                        function activate() { root.apps.launchIndex(index); root.close() }

                        Column {
                            anchors.centerIn: parent
                            spacing: Theme.s.sm

                            Rectangle {
                                width: 56; height: width
                                radius: Theme.r.lg
                                anchors.horizontalCenter: parent.horizontalCenter
                                color: Theme.c.surfaceRaised
                                border.width: 1
                                border.color: cell.selected ? Theme.accent : Theme.c.line

                                Image {
                                    anchors.fill: parent
                                    anchors.margins: 9
                                    source: cell.icon !== "" ? ("image://icon/" + cell.icon) : ""
                                    asynchronous: true
                                    fillMode: Image.PreserveAspectFit
                                }
                                Text {
                                    anchors.centerIn: parent
                                    visible: cell.icon === ""
                                    text: cell.name.charAt(0).toUpperCase()
                                    font.family: Theme.type.family
                                    font.pixelSize: Theme.type.title
                                    font.weight: Theme.type.weightSemibold
                                    color: Theme.accent
                                }
                            }

                            Text {
                                width: grid.cellWidth - Theme.s.sm * 2
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: cell.name
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                                font.family: Theme.type.family
                                font.pixelSize: Theme.type.label
                                font.weight: cell.selected ? Theme.type.weightSemibold
                                                           : Theme.type.weightRegular
                                color: Theme.c.ink
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            hoverEnabled: true
                            onClicked: { grid.currentIndex = cell.index; cell.activate() }
                        }
                    }
                }

                // Stickers tab
                ColumnLayout {
                    spacing: Theme.s.lg

                    Text {
                        Layout.fillWidth: true
                        text: "Masaüstüne sürükleyip bırakabileceğin çıkartmalar. "
                              + "Düzenlemeyi aç, sticker'ı seç; masaüstüne tıklayarak yerleştir."
                        wrapMode: Text.WordWrap
                        font.family: Theme.type.family
                        font.pixelSize: Theme.type.body
                        color: Theme.c.inkMuted
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: Theme.s.md

                        Repeater {
                            model: ["✦", "☾", "⚡", "♥", "✿", "▲", "●", "♪", "☀", "◆", "✿", "☻"]
                            delegate: GlassSurface {
                                required property string modelData
                                width: 84; height: 84
                                radius: Theme.r.lg
                                backdrop: null
                                tint: Theme.accentSoft
                                tintOpacity: 0.7
                                sheen: 0.6
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.modelData ? parent.modelData : ""
                                    font.pixelSize: 34
                                    color: Theme.c.ink
                                }
                                MouseArea {
                                    anchors.fill: parent
                                    drag.target: parent
                                    onPressed: {
                                        // Create a sticker at the click point on the desktop.
                                        var p = mapToItem(null, width / 2, height / 2)
                                        if (root.apps && root.apps.addSticker)
                                            root.apps.addSticker(parent.modelData, p.x, p.y)
                                        root.stickerEditMode = true
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: Theme.s.sm
                        GlassButton { label: "Kapat"; onClicked: root.close() }
                        GlassButton {
                            label: root.stickerEditMode ? "Düzenlemeyi bitir" : "Sticker düzenle"
                            primary: true
                            onClicked: root.stickerEditMode = !root.stickerEditMode
                        }
                    }
                }
            }

            // ── footer: power ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.s.sm
                Item { Layout.fillWidth: true }
                GlassButton { label: "Kilitle";  onClicked: { root.close(); root.apps && root.apps.lockSession() } }
                GlassButton { label: "Oturumu kapat"; onClicked: root.apps && root.apps.logout() }
                GlassButton { label: "Uyku"; onClicked: root.apps && root.apps.suspend() }
                GlassButton { label: "Kapat"; danger: true; onClicked: root.apps && root.apps.shutdown() }
            }
        }
    }
}
