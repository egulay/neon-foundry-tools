import QtQuick

// Picks one of the four scenes. A fresh draw every time the lock view is
// built, so locking the screen twice rarely shows the same thing twice.
//
// Set `variant` to 0-3 to pin one instead (SceneCrew, SceneAbduction,
// SceneMenagerie, ScenePatrol, in that order).
Loader {
    id: root

    property int variant: -1              // -1 picks at random
    readonly property var scenes: [
        "SceneCrew.qml",
        "SceneAbduction.qml",
        "SceneMenagerie.qml",
        "ScenePatrol.qml"
    ]
    readonly property int chosen: variant >= 0
        ? variant % scenes.length
        : Math.floor(Math.random() * scenes.length)

    source: scenes[chosen]
    asynchronous: true

    // Everything here is decoration. If a scene ever fails to load, the lock
    // screen must still come up with its password field: swallow it and show
    // nothing rather than taking the view down.
    onStatusChanged: {
        if (status === Loader.Error) {
            console.warn("Neon Foundry: lock scene failed to load:", source)
            source = ""
        }
    }
}
