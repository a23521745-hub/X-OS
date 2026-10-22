// Ambient wallpaper.  Three drifting light fields rendered with QtQuick.Shapes
// radial gradients — cheap, resolution independent and it gives the glass
// surfaces something rich to refract.
import QtQuick
import QtQuick.Shapes
import PlasmaX

Item {
    id: root

    property string mode: "aurora"
    property real parallaxX: 0
    property real parallaxY: 0
    // Autonomous ambient drift — separate from the parallax bindings above so
    // the animation never overwrites them.
    property real wobble: 0
    readonly property real drift: root.parallaxX * 0.5
    readonly property bool reducedMotion: Theme.motion.reducedMotionScale === 0

    Rectangle {
        anchors.fill: parent
        color: root.mode === "light" ? Theme.light.canvas : Theme.dark.canvas

        Behavior on color {
            ColorAnimation { duration: Theme.motion.slow; easing.bezierCurve: Theme.motion.easeStandard }
        }
    }

    // Soft grain to avoid gradient banding on cheap panels.
    Image {
        anchors.fill: parent
        source: "qrc:/plasmx/noise.png"
        fillMode: Image.Tile
        opacity: Theme.glassDark.grain
        visible: status === Image.Ready
    }

    Shape {
        anchors.fill: parent
        opacity: 0.9

        ShapePath {
            fillGradient: RadialGradient {
                centerX: root.width * 0.22 + root.drift
                centerY: root.height * 0.18 + root.parallaxY * 0.4 + root.wobble * root.height
                centerRadius: Math.max(root.width, root.height) * 0.62
                GradientStop { position: 0.0; color: root.mode === "ember" ? "#FF7A4540" : "#7C5CFF55" }
                GradientStop { position: 0.55; color: "#7C5CFF14" }
                GradientStop { position: 1.0; color: "#00000000" }
            }
            strokeWidth: 0
            startX: 0; startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    Shape {
        anchors.fill: parent
        opacity: 0.8

        ShapePath {
            fillGradient: RadialGradient {
                centerX: root.width * 0.82 - root.drift * 0.6
                centerY: root.height * 0.72
                centerRadius: Math.max(root.width, root.height) * 0.55
                GradientStop { position: 0.0; color: root.mode === "ember" ? "#FFB34740" : "#38D9E83D" }
                GradientStop { position: 0.6; color: "#38D9E80F" }
                GradientStop { position: 1.0; color: "#00000000" }
            }
            strokeWidth: 0
            startX: 0; startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    Shape {
        anchors.fill: parent
        opacity: 0.65

        ShapePath {
            fillGradient: RadialGradient {
                centerX: root.width * 0.55 + root.drift * 1.4
                centerY: root.height * 0.95
                centerRadius: Math.max(root.width, root.height) * 0.48
                GradientStop { position: 0.0; color: root.mode === "ember" ? "#FF5FA230" : "#FF5FA22E" }
                GradientStop { position: 1.0; color: "#00000000" }
            }
            strokeWidth: 0
            startX: 0; startY: 0
            PathLine { x: root.width; y: 0 }
            PathLine { x: root.width; y: root.height }
            PathLine { x: 0; y: root.height }
            PathLine { x: 0; y: 0 }
        }
    }

    // Slow "living" drift, deliberately subtle: 22 s round trip, 3.5 % travel.
    SequentialAnimation on wobble {
        running: !root.reducedMotion
        loops: Animation.Infinite
        NumberAnimation { to: 0.035; duration: 11000; easing.type: Easing.InOutSine }
        NumberAnimation { to: -0.035; duration: 11000; easing.type: Easing.InOutSine }
    }
}
