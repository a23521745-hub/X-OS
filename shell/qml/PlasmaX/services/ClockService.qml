// ClockService — shared time/date source for TopBar, Launcher and LockScreen.
import QtQuick

Item {
    id: root

    property string timeString: Qt.formatTime(now, "HH:mm")
    property string dateString: Qt.formatDate(now, "dddd, d MMMM")
    property string shortDateString: Qt.formatDate(now, "dd.MM")
    property string secondsString: Qt.formatTime(now, "ss")
    property var now: new Date()

    function refresh() { now = new Date() }

    Timer {
        interval: 1000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }
}
