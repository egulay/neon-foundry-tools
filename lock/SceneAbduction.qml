pragma ComponentBehavior: Bound

import QtQuick
import "FoundrySprites.js" as Sprites

// The saucer crosses the top of the screen with its beam down, beetles bolting
// along the bottom. Nothing crosses the middle band where the field sits.
Item {
    id: root
    anchors.fill: parent

    readonly property int px: Math.max(6, Math.round(height / 115))
    readonly property int ufoPx: px * 2
    readonly property real ufoY: height * 0.12
    readonly property real ground: height * 0.86

    // --- the saucer ---------------------------------------------------------
    Item {
        id: saucer
        width: ufo.implicitWidth
        height: ufo.implicitHeight
        y: root.ufoY + Math.sin(drift * Math.PI * 6) * root.px * 2

        property real drift: 0
        NumberAnimation on drift {
            from: 0
            to: 1
            duration: 38000
            loops: Animation.Infinite
            running: true
        }
        x: -width + drift * (root.width + width * 2)

        FoundryPixel {
            id: ufo
            px: root.ufoPx
            frames: [Sprites.UFO]
            colors: Sprites.ufoColors()
            outlinePx: 2
            outlineColor: Sprites.BG
        }

        // Running lights cycling through the palette.
        Row {
            y: 3 * root.ufoPx
            Repeater {
                model: ufo.cols
                delegate: Rectangle {
                    required property int index
                    width: root.ufoPx
                    height: root.ufoPx
                    visible: Sprites.UFO[3][index] === "L"
                    color: Sprites.PALETTE[(Math.floor(index / 2) + lightPhase.value) % Sprites.PALETTE.length]
                }
            }
        }

        // Drives the running lights around the hull.
        QtObject {
            id: lightPhase
            property int value: 0
        }
        Timer {
            interval: 260
            running: true
            repeat: true
            onTriggered: lightPhase.value = lightPhase.value + 1
        }

        // The beam: a stack of widening, fading bands down to the ground.
        Item {
            z: -2
            x: parent.width / 2
            y: parent.height - root.ufoPx
            Repeater {
                model: 22
                delegate: Rectangle {
                    required property int index
                    readonly property real t: index / 22
                    width: root.px * 6 + t * root.px * 46
                    height: (root.ground - saucer.y - saucer.height) / 22
                    x: -width / 2
                    y: index * height
                    color: index % 2 ? Sprites.LINK : Sprites.PALETTE[4]
                    opacity: (1 - t) * 0.10
                }
            }
        }

        // One beetle caught in the beam, turning slowly as it rises.
        FoundryPixel {
            id: lifted
            px: root.px
            frames: [Sprites.rot90(Sprites.BUG_TWITCH)]
            colors: Sprites.bugColors(Sprites.PALETTE[3])
            outlinePx: 2
            outlineColor: Sprites.LINK
            x: parent.width / 2 - implicitWidth / 2
            y: parent.height + (root.ground - saucer.y - saucer.height) * rise
            opacity: 1 - rise * 0.5

            property real rise: 1
            SequentialAnimation on rise {
                loops: Animation.Infinite
                running: true
                NumberAnimation { from: 1; to: 0.05; duration: 6500; easing.type: Easing.InOutQuad }
                PauseAnimation { duration: 1800 }
            }
            rotation: (1 - rise) * 180
        }
    }

    // --- the ones that got away --------------------------------------------
    Repeater {
        model: 3
        delegate: Item {
            id: runner
            required property int index
            readonly property bool rightward: index % 2 === 0

            property real t: 0
            NumberAnimation on t {
                from: 0
                to: 1
                duration: 14000 + runner.index * 3500
                loops: Animation.Infinite
                running: true
            }

            width: bug.implicitWidth
            height: bug.implicitHeight
            x: {
                var span = root.width + width * 2
                var p = (t + index / 3) % 1
                return rightward ? (-width + p * span) : (root.width + width - p * span)
            }
            y: root.ground - height + index * root.px * 3

            FoundryPixel {
                id: bug
                px: root.px
                flip: !runner.rightward
                frames: Sprites.BUG_RUN
                frameIndex: scuttle.value
                colors: Sprites.bugColors(Sprites.PALETTE[(runner.index + 1) % Sprites.PALETTE.length])
                outlinePx: 2
                outlineColor: Sprites.BG
            }
            QtObject { id: scuttle; property int value: 0 }
            Timer { interval: 90; running: true; repeat: true; onTriggered: scuttle.value = scuttle.value + 1 }
        }
    }
}
