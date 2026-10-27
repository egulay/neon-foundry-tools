pragma ComponentBehavior: Bound

import QtQuick

// One pixel-art character, drawn as a grid of Rectangles.
//
// A sprite is a list of equal-length strings; each character either maps to a
// colour through `colors` or is skipped. `outlinePx` stamps the whole shape in
// one flat colour at small offsets first, which is what keeps the black cat
// readable against a near-black background — without it the cat is
// a hole in the wallpaper.
//
// Rectangles rather than a Canvas: the lock screen is composited by the GPU
// and a repainting Canvas at panel resolution is the one thing on this screen
// that could stutter while someone is typing a password.
Item {
    id: root

    property var frames: []          // list of sprite matrices
    property int frameIndex: 0
    property var colors: ({})        // character -> colour
    property int px: 4               // size of one sprite pixel
    property bool flip: false        // face the other way
    property real outlinePx: 0       // halo offset, in screen pixels
    property color outlineColor: "transparent"
    property bool diagonalOutline: false

    readonly property var frame: frames.length ? frames[((frameIndex % frames.length) + frames.length) % frames.length] : []
    readonly property int cols: frame.length ? frame[0].length : 0
    readonly property int rows: frame.length

    implicitWidth: cols * px
    implicitHeight: rows * px

    // Flattened {x, y, colour} cells for the halo passes and the body pass.
    readonly property var cells: {
        var f = root.frame
        if (!f || !f.length)
            return []
        var out = []
        var w = f[0].length
        var y, x, ch, cx

        if (root.outlinePx > 0) {
            var offsets = [[1, 0], [-1, 0], [0, 1], [0, -1]]
            if (root.diagonalOutline)
                offsets = offsets.concat([[1, 1], [-1, -1], [1, -1], [-1, 1]])
            var halo = String(root.outlineColor)
            for (var o = 0; o < offsets.length; o++) {
                for (y = 0; y < f.length; y++) {
                    for (x = 0; x < w; x++) {
                        ch = f[y][x]
                        if (ch === "." || !root.colors[ch])
                            continue
                        cx = root.flip ? (w - 1 - x) : x
                        out.push({
                            "cx": cx * root.px + offsets[o][0] * root.outlinePx,
                            "cy": y * root.px + offsets[o][1] * root.outlinePx,
                            "col": halo
                        })
                    }
                }
            }
        }

        for (y = 0; y < f.length; y++) {
            for (x = 0; x < w; x++) {
                ch = f[y][x]
                var col = root.colors[ch]
                if (ch === "." || !col)
                    continue
                cx = root.flip ? (w - 1 - x) : x
                out.push({ "cx": cx * root.px, "cy": y * root.px, "col": String(col) })
            }
        }
        return out
    }

    Repeater {
        model: root.cells
        delegate: Rectangle {
            required property var modelData
            x: modelData.cx
            y: modelData.cy
            width: root.px
            height: root.px
            color: modelData.col
        }
    }
}
