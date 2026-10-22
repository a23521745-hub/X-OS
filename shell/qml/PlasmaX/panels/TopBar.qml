// TopBar — floating glass status bar.
// Left: launcher button + active window title.  Center: clock chip.
// Right: status indicators (net, volume, battery, X-Defender) + control
// center + notifications + user menu.  Auto-hides over fullscreen surfaces.
import QtQuick
import PlasmaX

Item {
    id: root

    property var api
    property var system
    property var defender
    property bool menuOpen: false

    signal launcherRequested()
    signal controlCenterRequested()
    signal notificationsRequested()

    height: Theme.topBarHeight
    z: 100

    GlassSurface {
        id: bar
        anchors.fill: parent
        radius: Theme.r.pill
        backdrop: null
        tintOpacity: 0.42
        fillStrong: Theme.g.fillStrong
        sheen: 0.5
        compact: true
        elevated: true
    }

    // ── left cluster ─────────────────────────────────────────────────────────
    Row {
        anchors.left: parent.left
        anchors.leftMargin: Theme.s.xs
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.s.xs

        Chip {
            glyph: "⌘"
            label: "X"
            active: root.menuOpen
            onClicked: root.launcherRequested()
        }

        Chip {
            id: titleChip
            visible: root.api && root.api.activeWindowTitle !== ""
            label: root.api ? root.api.activeWindowTitle : ""
            onClicked: root.launcherRequested()
        }
    }

    // ── center clock ─────────────────────────────────────────────────────────
    ClockService { id: clock }

    Chip {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.verticalCenter: parent.verticalCenter
        glyph: "◷"
        label: clock.timeString + "   ·   " + clock.dateString
        onClicked: root.launcherRequested()
    }

    // ── right cluster ────────────────────────────────────────────────────────
    Row {
        anchors.right: parent.right
        anchors.rightMargin: Theme.s.xs
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.s.xs

        Chip {
            visible: root.system && root.system.networkLabel !== ""
            glyph: "wifi"
            label: root.system ? root.system.networkLabel : ""
            onClicked: root.controlCenterRequested()
        }

        Chip {
            visible: root.system && root.system.batteryPercent >= 0
            glyph: "⌁"
            label: (root.system ? root.system.batteryPercent : 0) + "%"
                    + (root.system && root.system.onBattery ? " ⚡" : "")
            onClicked: root.controlCenterRequested()
        }

        Chip {
            id: shieldChip
            visible: root.defender !== null && root.defender !== undefined
            glyph: "🛡"
            label: root.defender ? root.defender.statusLabel : ""
            active: root.defender && root.defender.threats > 0
            onClicked: root.controlCenterRequested()
        }

        Chip {
            glyph: "☾"
            onClicked: root.api && root.api.toggleThemeMode()
        }

        Chip {
            glyph: "🔔"
            onClicked: root.notificationsRequested()
        }

        Chip {
            glyph: "⚙"
            label: ""
            onClicked: root.controlCenterRequested()
        }
    }

    // Fullscreen auto-hide: when a surface claims the whole screen, melt away.
    opacity: (root.api && root.api.fullscreenActive) ? 0.0 : 1.0
    Behavior on opacity { NumberAnimation { duration: Theme.motion.base } }
    enabled: opacity > 0.1
}
