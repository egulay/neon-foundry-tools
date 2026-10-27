pragma ComponentBehavior: Bound

import QtQuick
import "FoundrySprites.js" as Sprites

// Shift in progress: the crew hauling blocks along a lane near the foot of the
// screen, well clear of the password field in the middle.
Item {
    id: root
    anchors.fill: parent

    readonly property int px: Math.max(6, Math.round(height / 105))
    readonly property real lane: height * 0.80
    readonly property real laneBack: height * 0.70

    // Nine in the wallpapers; five here — a lock screen is not a building site
    // and a password field needs quiet around it.
    Repeater {
        model: 5
        delegate: Item {
            id: walker
            required property int index

            readonly property int kind: index % 3
            readonly property bool outbound: index % 2 === 0
            readonly property string hat: Sprites.PALETTE[index % Sprites.PALETTE.length]
            readonly property string tool: Sprites.PALETTE[(index + 2) % Sprites.PALETTE.length]
            readonly property real speed: 26000 + index * 5200
            readonly property real t0: index / 5

            property real t: 0
            NumberAnimation on t {
                from: 0
                to: 1
                duration: walker.speed
                loops: Animation.Infinite
                running: true
            }

            width: sprite.implicitWidth
            height: sprite.implicitHeight
            // Outbound walk left to right with a block; empties come back.
            x: {
                var span = root.width + width * 2
                var p = (t + t0) % 1
                return outbound ? (-width + p * span) : (root.width + width - p * span)
            }
            y: (outbound ? root.lane : root.laneBack) - height

            FoundryPixel {
                id: sprite
                px: root.px
                flip: !walker.outbound
                frames: Sprites.workerWalkFrames(walker.kind)
                frameIndex: step.value
                colors: Sprites.workerColors(walker.hat, walker.tool,
                                             walker.outbound ? Sprites.PALETTE[(walker.index + 1) % Sprites.PALETTE.length] : "")
                // A dark rim rather than a glow: it keeps every figure legible
                // over a bright wallpaper without painting a visible disc.
                outlinePx: 2
                outlineColor: Sprites.BG
            }

            QtObject {
                id: step
                property int value: 0
            }
            Timer {
                interval: 130
                running: true
                repeat: true
                onTriggered: step.value = step.value + 1
            }

        }
    }

    // Blocks already set down at the end of the lane.
    Row {
        x: root.width * 0.12
        y: root.lane - root.px * 2
        spacing: 2
        Repeater {
            model: 5
            delegate: Rectangle {
                required property int index
                width: root.px * 2
                height: root.px * 2
                color: Sprites.PALETTE[index % Sprites.PALETTE.length]
                opacity: 0.85
            }
        }
    }
}
