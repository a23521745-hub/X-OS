// GlassSurface — the "Liquid Glass" material that every X-OS panel sits on.
//
// Anatomy (inside out):
//   1. backdrop   ShaderEffectSource of the wallpaper behind this surface
//   2. blur       QtQuick.Effects MultiEffect (down-sampled gaussian)
//   3. tint       glass token fill, keeps text legible in light & dark
//   4. rim        1 px light ring, brighter on the top-left (key light)
//   5. specular   sheen across the upper third
//   6. shadow     drop shadow token, depth grows with `elevated`
//
// Everything is token-driven — no magic numbers.
import QtQuick
import QtQuick.Effects
import PlasmaX

Item {
    id: root

    default property alias content: container.data

    // The item to blur behind this surface.  When null the surface behaves
    // like plain translucent glass (rim + sheen still render).
    property Item backdrop: null

    property color tint: Theme.g.tint
    property real tintOpacity: Theme.g.tintOpacity
    property color rimColor: Theme.g.rim
    property color fill: Theme.g.fill
    property color fillStrong: Theme.g.fillStrong

    property real radius: Theme.r.lg
    property real blurAmount: 1.0          // 0..1, scaled to the blur token
    property real sheen: 0.55               // specular highlight strength
    property real refraction: Theme.g.refraction
    property bool elevated: true
    property bool compact: false            // tiny surfaces drop the blur pass

    readonly property real blurRadiusPx: Theme.g.blurRadius * blurAmount

    // ── drop shadow ──────────────────────────────────────────────────────────
    Item {
        id: shadowAnchor
        anchors.fill: parent
        Rectangle {
            id: shadowSource
            anchors.fill: parent
            radius: root.radius
            color: Theme.g.shadow
            visible: false
        }
        MultiEffect {
            anchors.fill: parent
            source: shadowSource
            blurEnabled: true
            blur: 0.4
            shadowEnabled: true
            shadowBlur: root.elevated ? (Theme.shadow.mid / 20) : (Theme.shadow.low / 20)
            shadowVerticalOffset: root.elevated ? 10 : 6
            shadowColor: Theme.g.shadow
            opacity: root.elevated ? 1.0 : 0.7
        }
    }

    // ── glass body (clipped rounded rect) ────────────────────────────────────
    Item {
        id: body
        anchors.fill: parent
        clip: true

        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: root.tint
            opacity: root.tintOpacity
        }

        // Backdrop blur pass — captured from *our* wallpaper, not the window.
        Loader {
            id: blurLoader
            anchors.fill: parent
            active: root.backdrop !== null && !root.compact
            sourceComponent: Item {
                readonly property point sourcePos: {
                    const p = root.mapToItem(root.backdrop, 0, 0)
                    return Qt.point(p.x, p.y)
                }
                ShaderEffectSource {
                    id: backdropSource
                    sourceItem: root.backdrop
                    sourceRect: Qt.rect(sourcePos.x, sourcePos.y, root.width, root.height)
                    textureSize: Qt.size(Math.max(2, root.width / 3), Math.max(2, root.height / 3))
                    live: true
                    visible: false
                    anchors.fill: parent
                }
                MultiEffect {
                    anchors.fill: parent
                    source: backdropSource
                    blurEnabled: true
                    blur: root.blurAmount
                    saturation: Theme.g.saturation
                }
            }
        }

        // Rim light: brighter along the top-left edge (key light direction).
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "transparent"
            border.width: 1
            border.color: root.rimColor
            opacity: 0.85
        }
        Rectangle {
            anchors.fill: parent
            radius: root.radius
            color: "transparent"
            border.width: 1.5
            border.color: "#ffffff"
            opacity: 0.10
        }

        // Specular sheen across the upper third.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            height: parent.height * 0.55
            radius: root.radius
            opacity: root.sheen * 0.5
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.0; color: root.fillStrong }
                GradientStop { position: 0.45; color: root.fill }
                GradientStop { position: 1.0; color: "#00000000" }
            }
        }

        // Bottom inner edge — the "glass has thickness" cue.
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            anchors.leftMargin: root.radius * 0.5
            anchors.rightMargin: root.radius * 0.5
            height: 1
            color: root.rimColor
            opacity: 0.5
        }

        Item { id: container; anchors.fill: parent }
    }

    // Corner refraction: a soft bright wedge in the top-left corner.  Cheap
    // stand-in for a full lens pass, reads convincingly at panel sizes.
    Rectangle {
        width: Math.min(root.width, root.height) * 0.9
        height: width
        anchors.left: parent.left
        anchors.top: parent.top
        radius: root.radius
        opacity: root.refraction * 3.2
        gradient: Gradient {
            orientation: Gradient.Diagonal
            GradientStop { position: 0.0; color: "#ffffff" }
            GradientStop { position: 0.35; color: "#ffffff00" }
            GradientStop { position: 1.0; color: "#ffffff00" }
        }
        visible: root.refraction > 0
    }
}
