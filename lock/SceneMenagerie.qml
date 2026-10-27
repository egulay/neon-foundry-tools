pragma ComponentBehavior: Bound

import QtQuick
import "FoundrySprites.js" as Sprites

// Off shift: the cat crosses and settles, the lamb grazes, the devil takes its
// slow walk. The quietest of the four scenes.
Item {
    id: root
    anchors.fill: parent

    readonly property int px: Math.max(7, Math.round(height / 95))
    readonly property real ground: height * 0.82

    // --- the lamb: grazing, with its breathing aura -------------------------
    Item {
        id: lamb
        x: root.width * 0.10
        y: root.ground - height
        width: lambSprite.implicitWidth
        height: lambSprite.implicitHeight

        FoundryPixel {
            id: lambSprite
            px: root.px
            frames: Sprites.LAMB_GRAZE
            frameIndex: lambStep.value
            colors: Sprites.LAMB_COLORS
            outlinePx: 2
            outlineColor: Sprites.LAMB_AURA
            opacity: 0.80 + 0.20 * breathe
            property real breathe: 0
            SequentialAnimation on breathe {
                loops: Animation.Infinite
                running: true
                NumberAnimation { from: 0; to: 1; duration: 2600; easing.type: Easing.InOutSine }
                NumberAnimation { from: 1; to: 0; duration: 2600; easing.type: Easing.InOutSine }
            }
        }
        QtObject { id: lambStep; property int value: 0 }
        Timer { interval: 700; running: true; repeat: true; onTriggered: lambStep.value = lambStep.value + 1 }

        // Pale motes circling slowly above its back.
        Repeater {
            model: 5
            delegate: Rectangle {
                required property int index
                width: 3
                height: 3
                color: index % 2 ? Sprites.LAMB_AURA : Sprites.LAMB_WOOL
                opacity: 0.8
                x: lamb.width / 2 + Math.cos(orbit.a + index * 1.256) * lamb.width * 0.7
                y: -lamb.height * 0.25 + Math.sin(orbit.a + index * 1.256) * lamb.height * 0.2
            }
        }
    }

    QtObject {
        id: orbit
        property real a: 0
    }
    NumberAnimation {
        target: orbit
        property: "a"
        from: 0
        to: Math.PI * 2
        duration: 9000
        loops: Animation.Infinite
        running: true
    }

    // --- the cat: walks in from the right, then sits --------------------------
    Item {
        id: cat
        width: catSprite.implicitWidth
        height: catSprite.implicitHeight
        y: root.ground - height

        // Walks across the clear span between the lamb and the devil, pauses
        // to sit in the middle of it, then walks on. `walking` drives both the
        // position and which sprite set is showing. Keeping it inside that
        // span is what stops the cat strolling through the other two.
        readonly property real spanFrom: root.width * 0.62
        readonly property real spanTo: root.width * 0.33
        property real t: 0
        property bool walking: true
        SequentialAnimation on t {
            loops: Animation.Infinite
            running: true
            NumberAnimation { from: 0; to: 0.45; duration: 11000 }
            ScriptAction { script: cat.walking = false }
            PauseAnimation { duration: 7000 }
            ScriptAction { script: cat.walking = true }
            NumberAnimation { from: 0.45; to: 1; duration: 13000 }
        }
        x: spanFrom + t * (spanTo - spanFrom)

        FoundryPixel {
            id: catSprite
            px: root.px
            flip: true  // travelling right to left
            frames: cat.walking ? Sprites.CAT_WALK : Sprites.CAT_SIT
            frameIndex: catStep.value
            // A #07070a cat body disappears entirely once the wallpaper behind
            // it has been blurred and scrimmed — all that survives is the gold
            // rim. Lifted just far enough off black to read as a black cat
            // rather than a wireframe one.
            colors: ({ "#": "#17171d", "T": "#17171d", "E": Sprites.CAT_EYE })
            // The gold rim is what makes a near-black cat visible at all.
            outlinePx: 2
            outlineColor: Sprites.CAT_GOLD
        }
        QtObject { id: catStep; property int value: 0 }
        Timer {
            interval: cat.walking ? 150 : 900
            running: true
            repeat: true
            onTriggered: catStep.value = catStep.value + 1
        }

        // Gold twinkles blinking in and out around the halo.
        Repeater {
            model: 6
            delegate: Rectangle {
                required property int index
                width: 3
                height: 3
                color: index % 2 ? Sprites.CAT_GOLD : Sprites.CAT_HALO_HI
                x: cat.width / 2 + Math.cos(orbit.a * 1.4 + index * 1.047) * cat.width * 0.85
                y: cat.height / 2 + Math.sin(orbit.a * 1.4 + index * 1.047) * cat.height * 0.7
                opacity: 0.35 + 0.45 * Math.abs(Math.sin(orbit.a * 2 + index))
            }
        }
    }

    // --- the devil: never hurries -------------------------------------------
    Item {
        id: devil
        width: devilSprite.implicitWidth
        height: devilSprite.implicitHeight
        y: root.ground - height
        x: root.width * 0.78 + Math.sin(orbit.a * 0.4) * root.width * 0.03

        FoundryPixel {
            id: devilSprite
            px: root.px
            frames: Sprites.DEVIL
            frameIndex: devilStep.value
            colors: Sprites.DEVIL_COLORS
            outlinePx: 2
            outlineColor: Sprites.DEVIL_DARK
        }
        QtObject { id: devilStep; property int value: 0 }
        Timer { interval: 820; running: true; repeat: true; onTriggered: devilStep.value = devilStep.value + 1 }

        // Embers drifting up from its feet.
        Repeater {
            model: 7
            delegate: Rectangle {
                id: emberDot
                required property int index
                width: 3
                height: 3
                color: index % 3 === 0 ? "#f5c542" : (index % 3 === 1 ? Sprites.PALETTE[1] : Sprites.DEVIL_RED)
                x: devil.width * (0.2 + 0.1 * index)
                y: devil.height - (ember.t * devil.height * 0.55) - index * 3
                opacity: (1 - ember.t) * 0.8

                QtObject { id: ember; property real t: 0 }
                NumberAnimation {
                    target: ember
                    property: "t"
                    from: 0
                    to: 1
                    duration: 2400 + emberDot.index * 260
                    loops: Animation.Infinite
                    running: true
                }
            }
        }
    }
}
