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

    width: BarConfig.sizes.bluetoothWidth
    height: Math.min(650, content.implicitHeight + 20)

    contentHeight: content.implicitHeight

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
                    text: Bluetooth.powered ? "bluetooth" : "bluetooth_disabled"
                    color: Bluetooth.powered ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.larger
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 4

                    StyledText {
                        text: qsTr("Bluetooth")
                        font.bold: true
                        font.pointSize: Appearance.font.size.normal
                    }

                    StyledText {
                        text: {
                            if (!Bluetooth.powered) return qsTr("Disabled");
                            const connectedDevices = Bluetooth.devices.filter(d => d.connected);
                            if (connectedDevices.length === 0) {
                                return qsTr("No devices connected");
                            } else if (connectedDevices.length === 1) {
                                return qsTr("Connected to: %1").arg(connectedDevices[0].alias);
                            } else {
                                return qsTr("Connected to %1 devices").arg(connectedDevices.length);
                            }
                        }
                        color: Bluetooth.devices.some(d => d.connected) ? Colours.palette.m3primary : Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.small
                    }
                }

                Switch {
                    checked: Bluetooth.powered
                    onToggled: Bluetooth.togglePower()
                }
            }
        }

        // Control Panel
        StyledRect {
            visible: Bluetooth.powered
            width: parent.width
            implicitHeight: controlsLayout.implicitHeight + Appearance.padding.normal * 2
            color: Colours.palette.m3surfaceContainer
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: controlsLayout
                anchors.fill: parent
                anchors.margins: Appearance.padding.normal
                spacing: Appearance.spacing.normal

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.normal

                    StyledText {
                        text: qsTr("Discovery:")
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Switch {
                        checked: Bluetooth.discovering
                        onToggled: Bluetooth.toggleDiscovery()
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item { Layout.fillWidth: true }

                    StyledText {
                        visible: Bluetooth.discovering
                        text: qsTr("Scanning...")
                        color: Colours.palette.m3primary
                        font.pointSize: Appearance.font.size.small
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Appearance.spacing.small

                    Button {
                        text: qsTr("Scan for Devices")
                        onClicked: Bluetooth.scanForDevices()
                        Layout.fillWidth: true
                    }

                    Button {
                        text: qsTr("Make Discoverable")
                        onClicked: Bluetooth.makeDiscoverable()
                        Layout.fillWidth: true
                    }
                }
            }
        }

        // Connected Devices Section
        StyledText {
            visible: Bluetooth.devices.some(d => d.connected)
            text: qsTr("Connected Devices")
            font.bold: true
            font.pointSize: Appearance.font.size.normal
            color: Colours.palette.m3primary
        }

        Repeater {
            model: ScriptModel {
                values: Bluetooth.devices.filter(d => d.connected)
            }

            delegate: StyledRect {
                required property Bluetooth.Device modelData

                width: parent.width
                implicitHeight: connectedLayout.implicitHeight + Appearance.padding.normal * 2
                color: Colours.palette.m3primaryContainer
                radius: Appearance.rounding.normal
                border.width: 1
                border.color: Colours.palette.m3primary

                RowLayout {
                    id: connectedLayout
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: Icons.getBluetoothIcon(modelData.icon)
                        color: Colours.palette.m3onPrimaryContainer
                        font.pointSize: Appearance.font.size.larger
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        StyledText {
                            text: modelData.alias
                            font.bold: true
                            color: Colours.palette.m3onPrimaryContainer
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, parent.width)
                        }

                        Row {
                            spacing: 8

                            StyledText {
                                text: qsTr("Connected")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3primary
                            }

                            StyledText {
                                visible: modelData.trusted
                                text: "• " + qsTr("Trusted")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onPrimaryContainer
                            }
                        }

                        StyledText {
                            text: modelData.address
                            font.pointSize: Appearance.font.size.smaller
                            color: Colours.palette.m3onPrimaryContainer
                            opacity: 0.7
                        }
                    }

                    Button {
                        text: qsTr("Disconnect")
                        onClicked: modelData.disconnect()
                        Layout.alignment: Qt.AlignVCenter
                    }
                }
            }
        }

        // Paired Devices Section
        StyledText {
            visible: Bluetooth.devices.some(d => d.paired && !d.connected)
            text: qsTr("Paired Devices")
            font.bold: true
            font.pointSize: Appearance.font.size.normal
        }

        Repeater {
            model: ScriptModel {
                values: Bluetooth.devices.filter(d => d.paired && !d.connected)
            }

            delegate: StyledRect {
                required property Bluetooth.Device modelData

                width: parent.width
                implicitHeight: pairedLayout.implicitHeight + Appearance.padding.normal * 2
                color: pairedMa.containsMouse ? Colours.palette.m3surfaceVariant : Colours.palette.m3surface
                radius: Appearance.rounding.normal

                RowLayout {
                    id: pairedLayout
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: Icons.getBluetoothIcon(modelData.icon)
                        color: Colours.palette.m3onSurface
                        font.pointSize: Appearance.font.size.large
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        StyledText {
                            text: modelData.alias
                            font.bold: true
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, parent.width)
                        }

                        Row {
                            spacing: 8

                            StyledText {
                                text: qsTr("Paired")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3secondary
                            }

                            StyledText {
                                visible: modelData.trusted
                                text: "• " + qsTr("Trusted")
                                font.pointSize: Appearance.font.size.small
                                color: Colours.palette.m3onSurfaceVariant
                            }
                        }

                        StyledText {
                            text: modelData.address
                            font.pointSize: Appearance.font.size.smaller
                            color: Colours.palette.m3onSurfaceVariant
                            opacity: 0.7
                        }
                    }

                    RowLayout {
                        spacing: Appearance.spacing.small
                        Layout.alignment: Qt.AlignVCenter

                        Button {
                            text: qsTr("Connect")
                            onClicked: modelData.connect()
                        }

                        Button {
                            text: qsTr("Remove")
                            onClicked: modelData.unpair()
                        }

                        Button {
                            visible: !modelData.trusted
                            text: qsTr("Trust")
                            onClicked: modelData.trust()
                        }
                    }
                }

                MouseArea {
                    id: pairedMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }

        // Available Devices Section
        StyledText {
            visible: Bluetooth.devices.some(d => !d.paired)
            text: qsTr("Available Devices")
            font.bold: true
            font.pointSize: Appearance.font.size.normal
        }

        Repeater {
            model: ScriptModel {
                values: Bluetooth.devices.filter(d => !d.paired).slice(0, 8)
            }

            delegate: StyledRect {
                required property Bluetooth.Device modelData

                width: parent.width
                implicitHeight: availableLayout.implicitHeight + Appearance.padding.normal * 2
                color: availableMa.containsMouse ? Colours.palette.m3surfaceVariant : Colours.palette.m3surface
                radius: Appearance.rounding.normal

                RowLayout {
                    id: availableLayout
                    anchors.fill: parent
                    anchors.margins: Appearance.padding.normal
                    spacing: Appearance.spacing.normal

                    MaterialIcon {
                        text: Icons.getBluetoothIcon(modelData.icon)
                        color: Colours.palette.m3onSurfaceVariant
                        font.pointSize: Appearance.font.size.large
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Column {
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        spacing: 4

                        StyledText {
                            text: modelData.alias
                            color: Colours.palette.m3onSurface
                            elide: Text.ElideRight
                            width: Math.min(implicitWidth, parent.width)
                        }

                        StyledText {
                            text: qsTr("Available to pair")
                            font.pointSize: Appearance.font.size.small
                            color: Colours.palette.m3onSurfaceVariant
                        }

                        StyledText {
                            text: modelData.address
                            font.pointSize: Appearance.font.size.smaller
                            color: Colours.palette.m3onSurfaceVariant
                            opacity: 0.7
                        }
                    }

                    Button {
                        text: qsTr("Pair")
                        onClicked: modelData.pair()
                        Layout.alignment: Qt.AlignVCenter
                    }
                }

                MouseArea {
                    id: availableMa
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }
            }
        }

        // Empty state
        StyledRect {
            visible: Bluetooth.powered && Bluetooth.devices.length === 0
            width: parent.width
            implicitHeight: emptyLayout.implicitHeight + Appearance.padding.large * 2
            color: Colours.palette.m3surfaceContainer
            radius: Appearance.rounding.normal

            ColumnLayout {
                id: emptyLayout
                anchors.fill: parent
                anchors.margins: Appearance.padding.large
                spacing: Appearance.spacing.normal

                MaterialIcon {
                    text: "bluetooth_searching"
                    color: Colours.palette.m3onSurfaceVariant
                    font.pointSize: Appearance.font.size.extraLarge
                    Layout.alignment: Qt.AlignHCenter
                }

                StyledText {
                    text: qsTr("No devices found")
                    font.bold: true
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                    Layout.fillWidth: true
                }

                StyledText {
                    text: qsTr("Make sure the device you want to connect is discoverable, then click \"Scan for Devices\"")
                    color: Colours.palette.m3onSurfaceVariant
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    font.pointSize: Appearance.font.size.small
                }
            }
        }
    }

    Connections {
        target: Bluetooth

        function onDeviceConnected(address) {
            console.log("Device connected:", address);
        }

        function onDeviceDisconnected(address) {
            console.log("Device disconnected:", address);
        }

        function onDevicePaired(address) {
            console.log("Device paired:", address);
        }

        function onBluetoothError(error) {
            console.error("Bluetooth error:", error);
        }
    }
}
