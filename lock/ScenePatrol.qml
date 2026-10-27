pragma ComponentBehavior: Bound

import QtQuick
import "FoundrySprites.js" as Sprites

// The snake crawling out of a wormhole and away across the foot of the screen.
//
// Drawn the way the wallpapers draw it: a snake pinned to the grid and
// fourteen segments long reads as a dotted circuit trace at panel scale, so the
// path is eased and sampled densely. The body comes out solid, tapers to the
// tail, and carries the two alternating greens, wider head, eyes and tongue.
Item {
    id: root
    anchors.fill: parent

    readonly property int px: Math.max(6, Math.round(height / 115))
    readonly property int girth: Math.max(10, Math.round(height / 46))
    // Samples, not segments: at a spacing of girth*0.2 this is a body about
    // 24 times its own width, which is snake-shaped. Shorter than that and
    // it reads as a worm.
    readonly property int bodyLength: 120

    // Where the tail comes out. The body is hidden before the path starts, so
    // the snake appears to pour from the hole rather than popping into being.
    readonly property real holeX: width * 0.12
    readonly property real holeY: height * 0.84

    // A gentle wave along the bottom, running off the right-hand edge.
    readonly property var path: {
        if (width <= 0 || height <= 0)
            return []
        var ctrl = [
            { "fx": 0.12, "fy": 0.84 },
            { "fx": 0.28, "fy": 0.90 },
            { "fx": 0.45, "fy": 0.82 },
            { "fx": 0.62, "fy": 0.90 },
            { "fx": 0.80, "fy": 0.82 },
            { "fx": 1.00, "fy": 0.88 },
            { "fx": 1.25, "fy": 0.82 }
        ]
        var pts = []
        for (var i = 0; i < ctrl.length; i++)
            pts.push({ "x": ctrl[i].fx * width, "y": ctrl[i].fy * height })
        return Sprites.resample(Sprites.chaikin(pts, 3), Math.max(2, girth * 0.2))
    }

    property real travel: 0
    NumberAnimation on travel {
        from: 0
        to: 1
        duration: 52000
        loops: Animation.Infinite
        running: true
    }
    readonly property int headIndex: path.length
        ? Math.floor(travel * (path.length - 1))
        : 0

    function pointAt(i) {
        if (i < 0 || i >= path.length)
            return null
        return path[i]
    }

    // --- wormhole: three rings, pink and cyan, around a dark core -----------
    Item {
        x: root.holeX
        y: root.holeY

        Repeater {
            model: 3
            delegate: Item {
                id: ringItem
                required property int index
                readonly property real radius: (index + 1) * root.px * 3.0
                readonly property int count: 6 + index * 4
                rotation: spin.a * (index % 2 ? -1 : 1)

                Repeater {
                    model: ringItem.count
                    delegate: Rectangle {
                        required property int index
                        width: Math.max(2, root.px)
                        height: Math.max(2, root.px)
                        color: (index + ringItem.index) % 2 ? Sprites.PALETTE[3] : Sprites.PALETTE[2]
                        opacity: 0.9 - ringItem.index * 0.2
                        x: Math.cos(index * 2 * Math.PI / ringItem.count) * ringItem.radius
                        y: Math.sin(index * 2 * Math.PI / ringItem.count) * ringItem.radius
                    }
                }
            }
        }

        Rectangle {
            width: root.px * 2
            height: root.px * 2
            x: -root.px
            y: -root.px
            color: "#050508"
        }
    }

    QtObject {
        id: spin
        property real a: 0
    }
    NumberAnimation {
        target: spin
        property: "a"
        from: 0
        to: 360
        duration: 7000
        loops: Animation.Infinite
        running: true
    }

    // --- body: tail first, so each blob is overlapped by the one ahead ------
    Repeater {
        model: root.bodyLength
        delegate: Rectangle {
            id: seg
            required property int index
            // index 0 is the neck; the tail is the far end of the model.
            readonly property int back: root.bodyLength - 1 - index
            readonly property var pt: root.pointAt(root.headIndex - back)
            readonly property real taper: 1 - (back / root.bodyLength) * 0.68

            visible: pt !== null
            width: Math.max(3, Math.round(root.girth * taper))
            height: width
            x: pt ? pt.x - width / 2 : -9999
            y: pt ? pt.y - height / 2 : -9999
            // Scales band along the body; alternating per sample at this
            // density would just read as noise.
            color: Math.floor(back / 4) % 2 ? "#8fbf00" : Sprites.PALETTE[0]
        }
    }

    // --- head ---------------------------------------------------------------
    Item {
        id: head
        readonly property var pt: root.pointAt(root.headIndex)
        readonly property var ahead: root.pointAt(Math.max(0, root.headIndex - 8))
        readonly property real dxRaw: pt && ahead ? pt.x - ahead.x : 1
        readonly property real dyRaw: pt && ahead ? pt.y - ahead.y : 0
        readonly property real mag: Math.max(0.0001, Math.sqrt(dxRaw * dxRaw + dyRaw * dyRaw))
        readonly property real dx: dxRaw / mag
        readonly property real dy: dyRaw / mag
        readonly property int hs: Math.round(root.girth * 1.15)
        readonly property int eye: Math.max(3, Math.round(root.girth * 0.26))

        visible: pt !== null
        x: pt ? pt.x : -9999
        y: pt ? pt.y : -9999

        Rectangle {
            x: -head.hs / 2
            y: -head.hs / 2
            width: head.hs
            height: head.hs
            color: Sprites.PALETTE[0]
        }

        // Eyes on the leading side.
        Repeater {
            model: 2
            delegate: Rectangle {
                required property int index
                readonly property real side: index === 0 ? 1 : -1
                width: head.eye
                height: head.eye
                color: "#121215"
                x: head.dx * root.girth * 0.20 + (-head.dy) * side * root.girth * 0.28 - width / 2
                y: head.dy * root.girth * 0.20 + (head.dx) * side * root.girth * 0.28 - height / 2
            }
        }

        // Forked tongue, flicking ahead.
        Repeater {
            model: 3
            delegate: Rectangle {
                required property int index
                // 0 is the tip at the mouth, 1 and 2 are the two forks.
                readonly property real fork: index === 0 ? 0 : (index === 1 ? 1 : -1)
                readonly property real reach: index === 0 ? 0.0 : 0.30
                width: head.eye
                height: head.eye
                color: Sprites.PALETTE[3]
                visible: tongue.out
                x: head.dx * (head.hs / 2 + root.girth * (0.08 + reach))
                   + (-head.dy) * fork * root.girth * 0.20 - width / 2
                y: head.dy * (head.hs / 2 + root.girth * (0.08 + reach))
                   + (head.dx) * fork * root.girth * 0.20 - height / 2
            }
        }
    }

    // The tongue flicks rather than hanging out permanently.
    QtObject {
        id: tongue
        property bool out: true
    }
    Timer {
        interval: 900
        running: true
        repeat: true
        onTriggered: tongue.out = !tongue.out
    }

    // --- beetles keeping out of its way -------------------------------------
    Repeater {
        model: 2
        delegate: Item {
            id: runner
            required property int index

            property real t: 0
            NumberAnimation on t {
                from: 0
                to: 1
                duration: 16000 + runner.index * 4200
                loops: Animation.Infinite
                running: true
            }
            width: bug.implicitWidth
            height: bug.implicitHeight
            x: root.width + width - ((t + runner.index / 2) % 1) * (root.width + width * 2)
            y: root.height * 0.95 - height

            FoundryPixel {
                id: bug
                px: root.px
                flip: true
                frames: Sprites.BUG_RUN
                frameIndex: scuttle.value
                colors: Sprites.bugColors(Sprites.PALETTE[(runner.index + 2) % Sprites.PALETTE.length])
                outlinePx: 2
                outlineColor: Sprites.BG
            }
            QtObject { id: scuttle; property int value: 0 }
            Timer { interval: 95; running: true; repeat: true; onTriggered: scuttle.value = scuttle.value + 1 }
        }
    }
}
