import "root:/widgets"
import "root:/services"
import "root:/config"
import "root:/utils"
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

ScrollView {
    id: root

    property var popouts: parent?.parent?.parent  // Access Content component

    width: BarConfig.sizes.networkWidth
    height: Math.min(600, content.implicitHeight + 20)

    contentHeight: content.implicitHeight

    // Main content
    Column {
        id: content
        width: root.width - 20
        spacing: Appearance.spacing.normal
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: 10

        // Header
        StyledRect {
            width: parent.width
            implicitHeight: headerLayout.implicitHeight + Appearance.padding.normal * 2
            color: Colours.palette.m3surfaceContainerLow
            radius: Appearance.rounding.normal

            RowLayout {
                id: headerLayout
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "wifi"
                    color: Colours.palette.m3primary
                    font.pointSize: Appearance.font.size.larger
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        text: qsTr("WiFi Network")
                        font.bold: true
                        font.pointSize: Appearance.font.size.normal
                    }

                    StyledText {
                        text: {
                            if (!Network.enabled) {
                                return qsTr("WiFi is disabled");
                            } else if (Network.active) {
                                return qsTr("Connected to: %1").arg(Network.active.ssid);
                            } else {
                                return qsTr("Not connected");
                            }
                        }
                        color: {
                            if (!Network.enabled) {
                                return Colours.palette.m3error;
                            } else if (Network.active) {
                                return Colours.palette.m3primary;
                            } else {
                                return Colours.palette.m3onSurfaceVariant;
                            }
                        }
                        font.pointSize: Appearance.font.size.small
                    }
                }

                Switch {
                    checked: Network.enabled
                    onToggled: Network.toggleWifi()
                }
            }
        }

        // Current Connection Details
        StyledRect {
            visible: Network.enabled && Network.active
            width: parent.width
            implicitHeight: connectionDetails.implicitHeight + Appearance.padding.normal * 2
            color: Colours.palette.m3surfaceContainer
            radius: Appearance.rounding.normal

            Column {
                id: connectionDetails
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.small

                StyledText {
                    text: qsTr("Connection Details")
                    font.bold: true
                    color: Colours.palette.m3primary
                }

                Row {
                    spacing: Appearance.spacing.normal
                    width: parent.width

                    MaterialIcon {
                        text: Icons.getNetworkIcon(Network.active ? Network.active.strength : 0)
                        color: Colours.palette.m3onSurface
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        spacing: 2

                        StyledText {
                            text: qsTr("Signal: %1%").arg(Network.active ? Network.active.strength : 0)
                            font.pointSize: Appearance.font.size.small
                        }

                        StyledText {
                            text: qsTr("Frequency: %1 MHz").arg(Network.active ? Network.active.frequency : 0)
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurfaceVariant
                        }
                    }
                }

                RowLayout {
                    width: parent.width
                    spacing: Appearance.spacing.small

                    Button {
                        text: qsTr("Disconnect")
                        onClicked: Network.disconnectNetwork()
                    }

                    Button {
                        text: qsTr("Forget")
                        onClicked: {
                            if (Network.active) {
                                Network.forgetNetwork(Network.active.ssid);
                            }
                        }
                    }

                    Button {
                        Layout.fillWidth: true
                        text: qsTr("Refresh")
                        onClicked: {
                            Network.refreshNetworks();
                            Network.getKnownNetworks();
                        }
                    }
                }
            }
        }

        // Available Networks Section
        StyledText {
            text: qsTr("Available Networks")
            font.bold: true
            font.pointSize: Appearance.font.size.normal
            visible: Network.enabled && Network.networks.length > 0
        }

        // WiFi Disabled Message
        StyledRect {
            visible: !Network.enabled
            width: parent.width
            implicitHeight: disabledMessage.implicitHeight + Appearance.padding.normal * 2
            color: Colours.palette.m3errorContainer
            radius: Appearance.rounding.normal

            Column {
                id: disabledMessage
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.small

                Row {
                    spacing: Appearance.spacing.normal
                    width: parent.width

                    MaterialIcon {
                        text: "wifi_off"
                        color: Colours.palette.m3error
                        font.pointSize: Appearance.font.size.larger
                        anchors.verticalCenter: parent.verticalCenter
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 4

                        StyledText {
                            text: qsTr("WiFi is Disabled")
                            font.bold: true
                            color: Colours.palette.m3onErrorContainer
                            font.pointSize: Appearance.font.size.normal
                        }

                        StyledText {
                            text: qsTr("Enable WiFi to see available networks")
                            color: Colours.palette.m3onErrorContainer
                            font.pointSize: Appearance.font.size.small
                        }
                    }
                }
            }
        }

        // Network List
        Repeater {
            model: Network.enabled ? Network.networks.slice(0, 12) : []

            delegate: StyledRect {
                required property var modelData

                width: parent.width
                implicitHeight: networkLayout.implicitHeight + Appearance.padding.small * 2
                color: networkMa.containsMouse ? Colours.palette.m3surfaceVariant : Colours.palette.m3surface
                radius: Appearance.rounding.small

                border.width: modelData.active ? 2 : 0
                border.color: Colours.palette.m3primary

                RowLayout {
                    id: networkLayout
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.small
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: Icons.getNetworkIcon(modelData.strength)
                        color: modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 2

                        StyledText {
                            text: modelData.ssid
                            font.bold: modelData.active
                            color: modelData.active ? Colours.palette.m3primary : Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, parent.width)
                        }

                        Row {
                            spacing: 8

                            StyledText {
                                text: qsTr("%1%").arg(modelData.strength)
                                font.pointSize: Appearance.font.size.smaller
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                text: "•"
                                font.pointSize: Appearance.font.size.smaller
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                text: qsTr("%1 MHz").arg(modelData.frequency)
                                font.pointSize: Appearance.font.size.smaller
                                color: Colours.palette.m3onSurfaceVariant
                            }

                            StyledText {
                                visible: Network.knownNetworks.some(kn => kn.name === modelData.ssid)
                                text: "• " + qsTr("Saved")
                                font.pointSize: Appearance.font.size.smaller
                                color: Colours.palette.m3secondary
                            }
                        }
                    }

                    Button {
                        visible: !modelData.active
                        text: Network.knownNetworks.some(kn => kn.name === modelData.ssid) ? qsTr("Connect") : qsTr("Join")
                        Layout.alignment: Qt.AlignVCenter
                        onClicked: {
                            if (Network.knownNetworks.some(kn => kn.name === modelData.ssid)) {
                                Network.connectToNetwork(modelData.ssid);
                            } else {
                                // Switch to password popout and pass the SSID
                                console.log("Switching to password popout for SSID:", modelData.ssid);
                                if (root.popouts) {
                                    console.log("Found popouts parent, switching to networkpassword");
                                    // Store the SSID globally for the password popout
                                    Network.pendingConnectionSsid = modelData.ssid;
                                    root.popouts.currentName = "networkpassword";

                                    // Try to call the open function on the password popout
                                    Qt.callLater(() => {
                                        const popoutChildren = root.popouts.content?.children || [];
                                        const passwordPopout = popoutChildren.find(child => child.name === "networkpassword");
                                        console.log("Found password popout:", passwordPopout !== undefined);
                                        if (passwordPopout && passwordPopout.item && passwordPopout.item.open) {
                                            console.log("Calling open on password popout");
                                            passwordPopout.item.open(modelData.ssid);
                                        }
                                    });
                                } else {
                                    console.log("Could not find popouts parent");
                                }
                            }
                        }
                    }
                }

                MouseArea {
                    id: networkMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.RightButton

                    onClicked: (mouse) => {
                        if (mouse.button === Qt.RightButton && Network.knownNetworks.some(kn => kn.name === modelData.ssid)) {
                            contextMenu.networkSsid = modelData.ssid;
                            contextMenu.popup();
                        }
                    }
                }
            }
        }

        StyledText {
            visible: Network.networks.length === 0 && Network.enabled
            text: qsTr("No networks found. Click refresh to scan again.")
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
        }

        StyledText {
            visible: !Network.enabled
            text: qsTr("WiFi is disabled. Turn on WiFi to see available networks.")
            color: Colours.palette.m3onSurfaceVariant
            horizontalAlignment: Text.AlignHCenter
            width: parent.width
            wrapMode: Text.WordWrap
        }
    }

    // Context Menu for saved networks
    Menu {
        id: contextMenu

        property string networkSsid: ""

        MenuItem {
            text: qsTr("Forget Network")
            onTriggered: Network.forgetNetwork(contextMenu.networkSsid)
        }
    }

    Connections {
        target: Network

        function onNetworkConnected(ssid) {
            console.log("Connected to", ssid);
        }

        function onNetworkDisconnected() {
            console.log("Disconnected from network");
        }

        function onNetworkForgotten(ssid) {
            console.log("Forgotten network", ssid);
        }

        function onNetworkError(error) {
            console.error("Network error:", error);
        }
    }
}
