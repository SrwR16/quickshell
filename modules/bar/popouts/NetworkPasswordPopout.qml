import "root:/widgets"
import "root:/services"
import "root:/config"
import "root:/utils"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    property var popouts: parent?.parent?.parent  // Access Content component
    property string networkSsid: ""

    width: BarConfig.sizes.networkWidth
    height: Math.min(350, content.implicitHeight + 40)

    implicitWidth: BarConfig.sizes.networkWidth
    implicitHeight: Math.min(350, content.implicitHeight + 40)

    // Make this item focusable
    focus: true
    activeFocusOnTab: true

    // Focus the password input when this item becomes visible or gets focus
    onVisibleChanged: {
        if (visible) {
            console.log("NetworkPasswordPopout became visible, focusing input");
            Qt.callLater(() => {
                passwordInput.forceActiveFocus();
                console.log("Auto-focus on visible, input has focus:", passwordInput.activeFocus);
            });
        }
    }

    onActiveFocusChanged: {
        if (activeFocus) {
            console.log("NetworkPasswordPopout received active focus, delegating to input");
            passwordInput.forceActiveFocus();
        }
    }

    function open(ssid) {
        networkSsid = ssid;
        passwordInput.text = "";
        console.log("=== NetworkPasswordPopout.open() called ===");
        console.log("Opening password popout for SSID:", ssid);
        console.log("Password input exists:", passwordInput !== null);
        console.log("Password input visible:", passwordInput.visible);
        console.log("Password input enabled:", passwordInput.enabled);

        // Multiple focus strategies
        passwordInput.forceActiveFocus();
        console.log("Initial focus applied, input has focus:", passwordInput.activeFocus);

        // Try clicking the input as well
        Qt.callLater(() => {
            console.log("Delayed focus attempt...");
            passwordInput.forceActiveFocus();
            console.log("Delayed focus applied, input has focus:", passwordInput.activeFocus);

            // Simulate a click on the input
            const clickEvent = {
                x: passwordInput.width / 2,
                y: passwordInput.height / 2,
                button: Qt.LeftButton,
                buttons: Qt.LeftButton,
                modifiers: Qt.NoModifier
            };
            console.log("Simulating click on password input...");
            passwordInput.clicked(clickEvent);
        });
    }

    Component.onCompleted: {
        console.log("=== NetworkPasswordPopout created ===");
        console.log("Component path:", this);
        console.log("Parent hierarchy:", parent, "->", parent?.parent, "->", parent?.parent?.parent);
        if (Network.pendingConnectionSsid) {
            console.log("Initializing with pending SSID:", Network.pendingConnectionSsid);
            networkSsid = Network.pendingConnectionSsid;
        }
    }

    Timer {
        id: focusTimer
        interval: 100
        running: true
        repeat: false
        onTriggered: {
            console.log("Timer triggered, focusing password input");
            passwordInput.forceActiveFocus();
        }
    }

    Column {
        id: content
        width: root.width - 40
        spacing: Appearance.spacing.large
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 20

        // Main password entry card
        StyledRect {
            width: parent.width
            implicitHeight: mainContent.implicitHeight + 40
            color: Colours.palette.m3surface
            radius: Appearance.rounding.large

            // Add shadow/border for better visibility
            border.width: 2
            border.color: Colours.palette.m3primary

            Column {
                id: mainContent
                anchors.fill: parent
                anchors.margins: 20
                spacing: Appearance.spacing.large

                // Header section
                Row {
                    width: parent.width
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: "wifi_password"
                        color: Colours.palette.m3primary
                        font.pointSize: Appearance.font.size.extraLarge
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        StyledText {
                            text: qsTr("Enter WiFi Password")
                            font.bold: true
                            font.pointSize: Appearance.font.size.larger
                            color: Colours.palette.m3onSurface
                        }

                        StyledText {
                            text: root.networkSsid
                            color: Colours.palette.m3primary
                            font.pointSize: Appearance.font.size.normal
                            font.weight: Font.Medium
                        }
                    }
                }

                // Password input section
                Column {
                    width: parent.width
                    spacing: Appearance.spacing.normal

                    StyledText {
                        text: qsTr("Password")
                        font.bold: true
                        color: Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.normal
                    }

                    // Password input field with better styling
                    Rectangle {
                        width: parent.width
                        height: 56
                        color: passwordInput.activeFocus ? Colours.palette.m3surfaceContainer : Colours.palette.m3surfaceVariant
                        radius: Appearance.rounding.normal
                        border.width: passwordInput.activeFocus ? 3 : 1
                        border.color: passwordInput.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline

                        // Make it more visually prominent
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: -2
                            radius: parent.radius + 2
                            color: "transparent"
                            border.width: passwordInput.activeFocus ? 2 : 0
                            border.color: passwordInput.activeFocus ? Qt.rgba(Colours.palette.m3primary.r, Colours.palette.m3primary.g, Colours.palette.m3primary.b, 0.5) : "transparent"
                            visible: passwordInput.activeFocus
                        }

                        TextInput {
                            id: passwordInput
                            anchors.left: parent.left
                            anchors.right: toggleButton.left
                            anchors.top: parent.top
                            anchors.bottom: parent.bottom
                            anchors.margins: 16
                            anchors.rightMargin: 8

                            font.family: Appearance.font.family.sans
                            font.pointSize: Appearance.font.size.normal
                            color: Colours.palette.m3onSurface

                            echoMode: showPasswordToggle.checked ? TextInput.Normal : TextInput.Password
                            selectByMouse: true
                            activeFocusOnTab: true
                            focus: true  // Ensure it can receive focus

                            verticalAlignment: TextInput.AlignVCenter

                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                text: qsTr("Enter network password...")
                                color: Colours.palette.m3onSurfaceVariant
                                font: passwordInput.font
                                visible: passwordInput.text.length === 0 && !passwordInput.activeFocus
                            }

                            // Handle mouse clicks directly
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    console.log("TextInput MouseArea clicked - forcing focus");
                                    parent.forceActiveFocus();
                                    parent.cursorPosition = parent.positionAt(mouseX, mouseY);
                                    console.log("After click, input has focus:", parent.activeFocus);
                                }
                                cursorShape: Qt.IBeamCursor
                                // Don't prevent default TextInput behavior
                                propagateComposedEvents: true
                            }

                            Keys.onReturnPressed: {
                                if (text.length > 0) {
                                    connectButton.clicked();
                                }
                            }

                            onActiveFocusChanged: {
                                console.log("Password input focus changed to:", activeFocus);
                                if (activeFocus) {
                                    console.log("Password input received focus - ready for typing");
                                }
                            }

                            onTextChanged: {
                                console.log("Password text changed to:", text.length, "characters");
                            }

                            Component.onCompleted: {
                                console.log("Password TextInput created");
                            }
                        }

                            Keys.onReturnPressed: {
                                if (text.length > 0) {
                                    connectButton.clicked();
                                }
                            }

                            onActiveFocusChanged: {
                                console.log("Password input focus changed to:", activeFocus);
                            }

                            onTextChanged: {
                                console.log("Password text changed to:", text);
                            }

                            Component.onCompleted: {
                                console.log("Password TextInput created");
                            }
                        }

                        Button {
                            id: toggleButton
                            width: 40
                            height: 40
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.rightMargin: 8

                            background: Rectangle {
                                color: "transparent"
                                radius: Appearance.rounding.small
                            }

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: showPasswordToggle.checked ? "visibility_off" : "visibility"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.normal
                            }

                            onClicked: showPasswordToggle.checked = !showPasswordToggle.checked
                        }
                    }

                    CheckBox {
                        id: showPasswordToggle
                        text: qsTr("Show password")
                        font.pointSize: Appearance.font.size.small
                        checked: false
                    }
                }

                // Action buttons
                Row {
                    width: parent.width
                    spacing: Appearance.spacing.normal

                    Button {
                        text: qsTr("Cancel")
                        width: (parent.width - parent.spacing) / 2
                        height: 48

                        background: StyledRect {
                            color: Colours.palette.m3surfaceVariant
                            radius: Appearance.rounding.normal
                        }

                        contentItem: StyledText {
                            text: parent.text
                            color: Colours.palette.m3onSurfaceVariant
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pointSize: Appearance.font.size.normal
                        }

                        onClicked: {
                            if (root.popouts) {
                                root.popouts.hasCurrent = false;
                            }
                        }
                    }

                    Button {
                        id: connectButton
                        text: qsTr("Connect")
                        enabled: passwordInput.text.length > 0
                        width: (parent.width - parent.spacing) / 2
                        height: 48

                        background: StyledRect {
                            color: parent.enabled ? Colours.palette.m3primary : Colours.palette.m3surfaceVariant
                            radius: Appearance.rounding.normal
                        }

                        contentItem: StyledText {
                            text: parent.text
                            color: parent.enabled ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.pointSize: Appearance.font.size.normal
                            font.weight: Font.Medium
                        }

                        onClicked: {
                            console.log("Connecting to network:", root.networkSsid, "with password");
                            Network.connectToNetwork(root.networkSsid, passwordInput.text);
                            if (root.popouts) {
                                root.popouts.hasCurrent = false;
                            }
                        }
                    }
                }
            }
        }

        // Security info section
        StyledRect {
            width: parent.width
            implicitHeight: securityInfo.implicitHeight + 24
            color: Colours.palette.m3surfaceContainer
            radius: Appearance.rounding.normal

            Row {
                id: securityInfo
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                MaterialIcon {
                    text: "security"
                    color: Colours.palette.m3secondary
                    font.pointSize: Appearance.font.size.normal
                    anchors.verticalCenter: parent.verticalCenter
                }

                StyledText {
                    text: qsTr("Your password will be stored securely and encrypted")
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurfaceVariant
                    wrapMode: Text.WordWrap
                    width: parent.width - parent.children[0].width - parent.spacing
                    anchors.verticalCenter: parent.verticalCenter
                }
            }
        }
    }

    Connections {
        target: Network

        function onNetworkConnected(ssid) {
            console.log("Network connected:", ssid);
        }

        function onNetworkError(error) {
            console.error("Network connection error:", error);
        }
    }
}
