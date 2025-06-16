import QtQuick

// Basic shortcut implementation for niri
Item {
    property string name
    property string description

    signal pressed()
    signal released()

    // For niri, shortcuts would be handled via keybinds in the compositor config
    // This is a placeholder to prevent errors
}
