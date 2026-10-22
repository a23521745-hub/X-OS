// X-OS PlasmaX shell entry point.
//
// One frameless, full-screen window hosts every surface (wallpaper, panels,
// overlays).  Keeping the whole shell in a single window means the desktop
// background, the "liquid glass" panels and the sticker layer all share one
// scene graph, so glass can refract *our own* wallpaper instead of relying on
// the compositor's blur behind the window.
import QtQuick
import QtQuick.Window
import PlasmaX

Window {
    id: shell

    required property var api          // xos.api  (XosApi singleton, C++)
    required property var apps         // xos.apps (DesktopApps model, C++)
    required property var system       // xos.system (SystemStatus, C++)
    required property var settings     // xos.settings (SettingsStore, C++)
    required property var defender     // xos.defender (XDefenderClient, C++)
    property var notifications: []     // reserved for the notification daemon bridge

    readonly property bool compact: width < 1100
    readonly property bool darkMode: !Theme.lightMode

    visible: true
    color: "transparent"
    flags: Qt.FramelessWindowHint
    title: "PlasmaX"

    // ── Wallpaper ────────────────────────────────────────────────────────────
    Wallpaper {
        id: wallpaper
        anchors.fill: parent
        mode: shell.settings ? shell.settings.wallpaperId : "aurora"
        parallaxX: shell.api ? shell.api.pointerX : 0
        parallaxY: shell.api ? shell.api.pointerY : 0
    }

    // ── Desktop (windows live behind us; we only draw icons + stickers) ──────
    DesktopLayer {
        id: desktop
        anchors.fill: parent
        topInset: topBar.height + Theme.topBarInset * 2
        bottomInset: dock.height + Theme.dockInset * 2
    }

    StickerLayer {
        id: stickers
        anchors.fill: parent
        topInset: desktop.topInset
        bottomInset: desktop.bottomInset
        editMode: launcher.stickerEditMode
        settingsBridge: shell.settings
        stickers: shell.settings ? shell.settings.stickers : []
    }

    // ── Panels ───────────────────────────────────────────────────────────────
    TopBar {
        id: topBar
        width: parent.width - Theme.topBarInset * 2
        x: Theme.topBarInset
        y: Theme.topBarInset
        api: shell.api
        system: shell.system
        defender: shell.defender
        onLauncherRequested: launcher.toggle()
        onControlCenterRequested: controlCenter.visible ? controlCenter.close() : controlCenter.open()
        onNotificationsRequested: notifCenter.visible ? notifCenter.close() : notifCenter.open()
    }

    Dock {
        id: dock
        anchors.horizontalCenter: parent.horizontalCenter
        y: parent.height - height - Theme.dockInset
        apps: shell.apps
        hidden: controlCenter.expanded || launcher.visible || lockScreen.visible
        onLauncherRequested: launcher.toggle()
    }

    Launcher {
        id: launcher
        anchors.fill: parent
        apps: shell.apps
        backdrop: wallpaper
        onStickerEditModeChanged: stickers.editMode = stickerEditMode
    }

    ControlCenter {
        id: controlCenter
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Theme.topBarInset * 2 + topBar.height + 6
        anchors.rightMargin: Theme.topBarInset
        system: shell.system
        defender: shell.defender
        api: shell.api
    }

    NotificationCenter {
        id: notifCenter
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.topMargin: Theme.topBarInset * 2 + topBar.height + 6
        anchors.rightMargin: Theme.topBarInset
        model: shell.notifications
        onCloseRequested: close()
    }

    LockScreen {
        id: lockScreen
        anchors.fill: parent
        api: shell.api
        visible: false
    }

    // ── Keys & global gestures ───────────────────────────────────────────────
    Item {
        id: keySink
        anchors.fill: parent
        z: -1
        focus: true
        Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Meta && !event.isAutoRepeat) {
                launcher.toggle()
                event.accepted = true
            } else if (event.key === Qt.Key_Escape) {
                if (launcher.visible) launcher.close()
                else if (controlCenter.visible) controlCenter.close()
                else if (notifCenter.visible) notifCenter.close()
                if (stickers.editMode) launcher.stickerEditMode = false
                event.accepted = true
            }
        }
    }

    function showLockScreen() { lockScreen.visible = true }
    function hideLockScreen() { lockScreen.visible = false }

    Component.onCompleted: {
        if (shell.api) shell.api.attachShell(shell)
    }
}
