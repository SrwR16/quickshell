pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    property bool powered
    property bool discovering
    readonly property list<Device> devices: []

    signal deviceConnected(string address)
    signal deviceDisconnected(string address)
    signal devicePaired(string address)
    signal bluetoothError(string error)

    function togglePower() {
        if (powered) {
            powerProcess.command = ["bluetoothctl", "power", "off"];
        } else {
            powerProcess.command = ["bluetoothctl", "power", "on"];
        }
        powerProcess.running = true;
        Qt.callLater(() => getInfo.running = true);
    }

    function toggleDiscovery() {
        if (discovering) {
            discoveryProcess.command = ["bluetoothctl", "scan", "off"];
        } else {
            discoveryProcess.command = ["bluetoothctl", "scan", "on"];
        }
        discoveryProcess.running = true;
        Qt.callLater(() => getInfo.running = true);
    }

    function connectDevice(address) {
        console.log("Connecting to device:", address);
        connectProcess.command = ["bluetoothctl", "connect", address];
        connectProcess.running = true;
    }

    function disconnectDevice(address) {
        console.log("Disconnecting from device:", address);
        disconnectProcess.command = ["bluetoothctl", "disconnect", address];
        disconnectProcess.running = true;
    }

    function pairDevice(address) {
        console.log("Pairing with device:", address);
        pairProcess.command = ["bluetoothctl", "pair", address];
        pairProcess.running = true;
    }

    function unpairDevice(address) {
        console.log("Unpairing device:", address);
        unpairProcess.command = ["bluetoothctl", "remove", address];
        unpairProcess.running = true;
        Qt.callLater(() => getDevices.running = true);
    }

    function trustDevice(address) {
        console.log("Trusting device:", address);
        trustProcess.command = ["bluetoothctl", "trust", address];
        trustProcess.running = true;
        Qt.callLater(() => getDevices.running = true);
    }

    function scanForDevices() {
        scanProcess.running = true;
    }

    function makeDiscoverable() {
        discoverableProcess.command = ["bluetoothctl", "discoverable", "on"];
        discoverableProcess.running = true;
    }

    Process {
        id: connectProcess
        stdout: SplitParser {
            onRead: {
                console.log("Bluetooth connect output:", data);
                if (data.includes("Connection successful")) {
                    root.deviceConnected(data);
                } else if (data.includes("Failed")) {
                    root.bluetoothError(data);
                }
                getDevices.running = true;
            }
        }
        stderr: SplitParser {
            onRead: {
                console.error("Bluetooth connect error:", data);
                root.bluetoothError(data);
            }
        }
    }

    Process {
        id: disconnectProcess
        stdout: SplitParser {
            onRead: {
                console.log("Bluetooth disconnect output:", data);
                if (data.includes("Successful disconnected")) {
                    root.deviceDisconnected(data);
                }
                getDevices.running = true;
            }
        }
        stderr: SplitParser {
            onRead: {
                console.error("Bluetooth disconnect error:", data);
                root.bluetoothError(data);
            }
        }
    }

    Process {
        id: pairProcess
        stdout: SplitParser {
            onRead: {
                if (data.includes("Pairing successful")) {
                    root.devicePaired(data);
                } else if (data.includes("Failed")) {
                    root.bluetoothError(data);
                }
                getDevices.running = true;
            }
        }
    }

    Process {
        id: powerProcess
        stdout: SplitParser {
            onRead: {
                getInfo.running = true;
            }
        }
    }

    Process {
        id: discoveryProcess
        stdout: SplitParser {
            onRead: {
                getInfo.running = true;
            }
        }
    }

    Process {
        id: unpairProcess
        stdout: SplitParser {
            onRead: {
                getDevices.running = true;
            }
        }
    }

    Process {
        id: trustProcess
        stdout: SplitParser {
            onRead: {
                getDevices.running = true;
            }
        }
    }

    Process {
        id: scanProcess
        command: ["bluetoothctl", "scan", "on"]
        stdout: SplitParser {
            onRead: {
                console.log("Scanning for devices...");
                Qt.callLater(() => {
                    // Stop scan after 10 seconds
                    scanStopTimer.start();
                });
            }
        }
    }

    Process {
        id: scanStopProcess
        command: ["bluetoothctl", "scan", "off"]
        stdout: SplitParser {
            onRead: {
                getDevices.running = true;
            }
        }
    }

    Process {
        id: discoverableProcess
        stdout: SplitParser {
            onRead: {
                console.log("Made discoverable");
            }
        }
    }

    Timer {
        id: scanStopTimer
        interval: 10000
        onTriggered: scanStopProcess.running = true
    }

    Process {
        running: true
        command: ["bluetoothctl"]
        stdout: SplitParser {
            onRead: {
                getInfo.running = true;
                getDevices.running = true;
            }
        }
    }

    Process {
        id: getInfo

        running: true
        command: ["bluetoothctl", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.powered = text.includes("Powered: yes");
                root.discovering = text.includes("Discovering: yes");
            }
        }
    }

    Process {
        id: getDevices

        running: true
        command: ["fish", "-c", `
            for a in (bluetoothctl devices)
                if string match -q 'Device *' $a
                    bluetoothctl info (string split ' ' $a)[2]
                    echo
                end
            end`]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const devices = text.trim().split("\n\n")
                        .filter(d => d.trim() !== "")
                        .map(d => {
                            const nameMatch = d.match(/Name: (.*)/);
                            const aliasMatch = d.match(/Alias: (.*)/);
                            const addressMatch = d.match(/Device ([0-9A-Fa-f:]{17})/);
                            const iconMatch = d.match(/Icon: (.*)/);

                            if (!addressMatch) return null;

                            return {
                                name: nameMatch ? nameMatch[1] : "Unknown",
                                alias: aliasMatch ? aliasMatch[1] : "Unknown",
                                address: addressMatch[1],
                                icon: iconMatch ? iconMatch[1] : "audio-headphones",
                                connected: d.includes("Connected: yes"),
                                paired: d.includes("Paired: yes"),
                                trusted: d.includes("Trusted: yes")
                            };
                        })
                        .filter(d => d !== null);

                    const rDevices = root.devices;

                    const destroyed = rDevices.filter(rd => !devices.find(d => d.address === rd.address));
                    for (const device of destroyed)
                        rDevices.splice(rDevices.indexOf(device), 1).forEach(d => d.destroy());

                    for (const device of devices) {
                        const match = rDevices.find(d => d.address === device.address);
                        if (match) {
                            match.lastIpcObject = device;
                        } else {
                            rDevices.push(deviceComp.createObject(root, {
                                lastIpcObject: device
                            }));
                        }
                    }
                } catch (error) {
                    console.error("Error parsing Bluetooth devices:", error);
                }
            }
        }
    }

    component Device: QtObject {
        required property var lastIpcObject
        readonly property string name: lastIpcObject.name
        readonly property string alias: lastIpcObject.alias
        readonly property string address: lastIpcObject.address
        readonly property string icon: lastIpcObject.icon
        readonly property bool connected: lastIpcObject.connected
        readonly property bool paired: lastIpcObject.paired
        readonly property bool trusted: lastIpcObject.trusted

        function connect() {
            root.connectDevice(address);
        }

        function disconnect() {
            root.disconnectDevice(address);
        }

        function pair() {
            root.pairDevice(address);
        }

        function unpair() {
            root.unpairDevice(address);
        }

        function trust() {
            root.trustDevice(address);
        }
    }

    Component {
        id: deviceComp

        Device {}
    }
}
