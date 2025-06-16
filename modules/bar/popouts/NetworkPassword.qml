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

    property string networkSsid: ""
    property bool isOpen: false

    width: parent ? parent.width : 350
    height: isOpen ? Math.min(280, contentColumn.implicitHeight + 32) : 0
    visible: isOpen

    // Position as overlay within the parent popout
    anchors.left: parent ? parent.left : undefined
    anchors.right: parent ? parent.right : undefined
    anchors.top: parent ? parent.top : undefined
    anchors.topMargin: 10

    function open(ssid) {
        networkSsid = ssid;
        isOpen = true;
        // Use multiple approaches to ensure focus
        Qt.callLater(() => {
            passwordField.forceActiveFocus();
        });
        // Backup approach with timer
        focusTimer.restart();
    }

    function close() {
        isOpen = false;
        passwordField.text = "";
        showPassword.checked = false;
    }

    // Semi-transparent background
    Rectangle {
        anchors.fill: parent
        color: Qt.rgba(0, 0, 0, 0.3)
        radius: Appearance.rounding.normal
    }

    // Background click handler - only outside content area
    MouseArea {
        anchors.fill: parent
        onClicked: {
            // Check if click is outside the content area
            var contentBounds = content.mapToItem(root, 0, 0, content.width, content.height);
            if (mouseX < contentBounds.x || mouseX > contentBounds.x + content.width ||
                mouseY < contentBounds.y || mouseY > contentBounds.y + content.height) {
                root.close();
            }
        }
    }

    // Popup content - centered in the overlay
    StyledRect {
        id: content
        anchors.centerIn: parent
        width: Math.min(parent.width - 40, 320)
        height: contentColumn.implicitHeight + 32
        color: Colours.palette.m3surfaceContainer
        radius: Appearance.rounding.large
        border.width: 2
        border.color: Colours.palette.m3primary

        Column {
            id: contentColumn
            anchors.fill: parent
            anchors.margins: Appearance.padding.normal
            spacing: Appearance.spacing.normal

            // Header
            RowLayout {
                width: parent.width
                spacing: Appearance.spacing.small

                MaterialIcon {
                    text: "wifi_password"
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.large
                    Layout.alignment: Qt.AlignVCenter
                }

                Column {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2

                    StyledText {
                        text: qsTr("Connect to WiFi")
                        font.bold: true
                        font.pointSize: Appearance.font.size.normal
                        color: Colours.palette.m3primary
                    }

                    StyledText {
                        text: root.networkSsid
                        font.pointSize: Appearance.font.size.small
                        color: Colours.palette.m3onSurface
                        elide: Text.ElideRight
                        width: Math.min(implicitWidth, 180)
                    }
                }

                Button {
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    background: Item {}

                    MaterialIcon {
                        anchors.centerIn: parent
                        text: "close"
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.small
                    }

                    onClicked: root.close()
                }
            }

            // Password input section
            Column {
                width: parent.width
                spacing: Appearance.spacing.small

                StyledText {
                    text: qsTr("Password")
                    font.bold: true
                    font.pointSize: Appearance.font.size.small
                    color: Colours.palette.m3onSurface
                }

                StyledRect {
                    width: parent.width
                    height: 40
                    color: Colours.palette.m3surface
                    radius: Appearance.rounding.small
                    border.width: passwordField.activeFocus ? 2 : 1
                    border.color: passwordField.activeFocus ? Colours.palette.m3primary : Colours.palette.m3outline

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: Appearance.padding.small
                        spacing: Appearance.spacing.small

                        TextInput {
                            id: passwordField
                            Layout.fillWidth: true
                            font.family: Appearance.font.family
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurface
                            echoMode: showPassword.checked ? TextInput.Normal : TextInput.Password
                            selectByMouse: true
                            selectionColor: Colours.palette.m3primary
                            selectedTextColor: Colours.palette.m3onPrimary
                            focus: true

                            Text {
                                anchors.fill: parent
                                text: qsTr("Enter password...")
                                font: passwordField.font
                                color: Colours.palette.m3onSurfaceVariant
                                visible: passwordField.text === "" && !passwordField.activeFocus
                                verticalAlignment: Text.AlignVCenter
                            }

                            Keys.onReturnPressed: {
                                if (text.length > 0) {
                                    connectBtn.clicked();
                                }
                            }

                            Keys.onEscapePressed: {
                                root.close();
                            }

                            onActiveFocusChanged: {
                                console.log("Password field focus changed to:", activeFocus);
                            }

                            onTextChanged: {
                                console.log("Password field text changed to:", text.length, "characters");
                            }

                            // Make the text input clickable
                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    parent.forceActiveFocus();
                                    parent.cursorPosition = parent.positionAt(mouseX, mouseY);
                                }
                                // Don't accept the event so TextInput can still handle it
                                onPressed: mouse.accepted = false
                                onReleased: mouse.accepted = false
                            }
                        }

                        Button {
                            id: showPasswordBtn
                            Layout.preferredWidth: 24
                            Layout.preferredHeight: 24
                            background: Item {}

                            MaterialIcon {
                                anchors.centerIn: parent
                                text: showPassword.checked ? "visibility_off" : "visibility"
                                color: Colours.palette.m3onSurfaceVariant
                                font.pointSize: Appearance.font.size.smaller
                            }

                            onClicked: showPassword.checked = !showPassword.checked
                        }
                    }
                }

                CheckBox {
                    id: showPassword
                    text: qsTr("Show password")
                    font.pointSize: Appearance.font.size.smaller
                }
            }

            // Action buttons
            RowLayout {
                width: parent.width
                spacing: Appearance.spacing.small

                Item { Layout.fillWidth: true }

                Button {
                    text: qsTr("Cancel")
                    Layout.minimumWidth: 60
                    font.pointSize: Appearance.font.size.small

                    background: StyledRect {
                        color: "transparent"
                        border.width: 1
                        border.color: Colours.palette.m3outline
                        radius: Appearance.rounding.small
                    }

                    onClicked: root.close()
                }

                Button {
                    id: connectBtn
                    text: qsTr("Connect")
                    enabled: passwordField.text.length > 0
                    Layout.minimumWidth: 60
                    font.pointSize: Appearance.font.size.small

                    background: StyledRect {
                        color: parent.enabled ? Colours.palette.m3primary : Colours.palette.m3surfaceVariant
                        radius: Appearance.rounding.small
                    }

                    contentItem: StyledText {
                        text: parent.text
                        color: parent.enabled ? Colours.palette.m3onPrimary : Colours.palette.m3onSurfaceVariant
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pointSize: Appearance.font.size.small
                    }

                    onClicked: {
                        console.log("Connecting to network:", root.networkSsid, "with password");
                        Network.connectToNetwork(root.networkSsid, passwordField.text);
                        root.close();
                    }
                }
            }
        }
    }

    Behavior on height {
        NumberAnimation {
            duration: Appearance.anim.durations.fast
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Appearance.anim.curves.standard
        }
    }

    // Timer to ensure focus is set
    Timer {
        id: focusTimer
        interval: 100
        onTriggered: {
            passwordField.forceActiveFocus();
            console.log("Focus timer triggered, field has focus:", passwordField.activeFocus);
        }
    }

    Connections {
        target: Network

        function onNetworkConnected(ssid) {
            if (root.isOpen) {
                root.close();
            }
        }

        function onNetworkError(error) {
            console.error("Network connection error:", error);
            // Keep dialog open on error so user can try again
        }
    }
}
