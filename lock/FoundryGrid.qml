pragma ComponentBehavior: Bound

import QtQuick
import "FoundrySprites.js" as Sprites

// The faint grid the characters move along, over the blurred wallpaper.
// The wallpapers draw it at 55% opacity in the line colour; here it sits lower
// still, because it is competing with a photograph rather than a flat ground.
Item {
    id: root
    property int cell: 120
    property real lineOpacity: 0.30

    Repeater {
        model: Math.max(0, Math.floor(root.width / root.cell))
        delegate: Rectangle {
            required property int index
            x: (index + 1) * root.cell
            width: 1
            height: root.height
            color: Sprites.LINE
            opacity: root.lineOpacity
        }
    }

    Repeater {
        model: Math.max(0, Math.floor(root.height / root.cell))
        delegate: Rectangle {
            required property int index
            y: (index + 1) * root.cell
            width: root.width
            height: 1
            color: Sprites.LINE
            opacity: root.lineOpacity
        }
    }
}
