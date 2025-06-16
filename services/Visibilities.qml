pragma Singleton

import Quickshell

Singleton {
    property var screens: ({})
    property var panels: ({})

    function getForActive(): PersistentProperties {
        // For niri, we'll use the first screen since it doesn't have the same monitor focus concept
        return Object.values(screens)[0] || null;
    }
}
