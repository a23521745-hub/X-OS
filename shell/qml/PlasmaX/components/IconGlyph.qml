// IconGlyph — vector icon primitive.
//
// X-OS ships its own geometric icon set (design/branding/icons.svg, aligned to
// a 24 px grid with 1.5 px strokes).  Using an SVG sprite keeps us clear of
// third-party icon licensing while staying crisp at any DPI.
import QtQuick

Item {
    id: root

    property string name: ""
    property color color: "#FFFFFF"

    readonly property int cell: 24
    readonly property int iconId: names.indexOf(root.name)
    readonly property bool available: iconId >= 0 && sprite.status === Image.Ready

    // Keep in sync with design/branding/icons.svg symbol order.
    readonly property var names: [
        "launcher", "wifi", "volume", "battery", "shield", "bell",
        "search", "settings", "power", "lock", "clock", "media",
        "grid", "sticker", "sun", "moon", "chevron", "close", "xos"
    ]

    width: cell
    height: cell
    visible: available

    Image {
        id: sprite
        anchors.fill: parent
        source: root.available ? "qrc:/plasmx/icons.svg" : ""
        sourceClipRect: Qt.rect(root.iconId * root.cell, 0, root.cell, root.cell)
        fillMode: Image.PreserveAspectFit
        asynchronous: false
        visible: true
        // Image.colorization avoids pulling in Qt5Compat just to tint icons.
        colorizationEnabled: root.color !== "#FFFFFF"
        colorizationColor: root.color
    }
}
