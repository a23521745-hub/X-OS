// DesktopLayer — wallpaper-space region reserved for icons & windows.
// v0.1 keeps it deliberately empty (window icons arrive with the session
// integration milestone); it exists so panels can reserve insets correctly.
import QtQuick
import PlasmaX

Item {
    id: root

    property int topInset: 0
    property int bottomInset: 0
    property int leftInset: Theme.s.lg
    property int rightInset: Theme.s.lg

    // Placeholder grid hint for where user icons snap to.
    readonly property real cellW: 96
    readonly property real cellH: 108

    Column {
        spacing: Theme.s.xs
        x: root.leftInset
        y: root.topInset
        opacity: 0.0

        Text { text: "Desktop"; color: Theme.c.inkMuted }
    }
}
