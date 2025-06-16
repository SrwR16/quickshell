pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<AccessPoint> networks: []
    readonly property list<KnownNetwork> knownNetworks: []
    readonly property AccessPoint active: networks.find(n => n.active) ?? null
    property bool enabled: true
    readonly property string status: "disconnected"
    property string pendingConnectionSsid: ""

    signal networkConnected(string ssid)
    signal networkDisconnected()
    signal networkForgotten(string ssid)
    signal networkError(string error)

    reloadableId: "network"

    function connectToNetwork(ssid, password) {
        console.log("Connecting to network:", ssid, password ? "with password" : "without password");
        if (password === undefined) password = "";

        connectProcess.command = password ?
            ["nmcli", "d", "wifi", "connect", ssid, "password", password] :
            ["nmcli", "d", "wifi", "connect", ssid];
        connectProcess.running = true;
    }

    function disconnectNetwork() {
        console.log("Disconnecting from current network");
        disconnectProcess.running = true;
    }

    function toggleWifi() {
        console.log("Toggling WiFi state, currently enabled:", enabled);
        const command = enabled ?
            ["nmcli", "radio", "wifi", "off"] :
            ["nmcli", "radio", "wifi", "on"];
        console.log("Executing command:", command.join(" "));
        toggleWifiProcess.command = command;
        toggleWifiProcess.running = true;
    }

    function refreshNetworks() {
        if (root.enabled) {
            getNetworks.running = true;
        } else {
            console.log("WiFi disabled, cannot refresh networks");
        }
    }

    function forgetNetwork(ssid) {
        console.log("Forgetting network:", ssid);
        forgetProcess.command = ["nmcli", "connection", "delete", ssid];
        forgetProcess.running = true;
    }

    function getKnownNetworks() {
        getKnownProcess.running = true;
    }

    function clearNetworks() {
        console.log("Clearing all networks");
        // Clear the networks list
        const rNetworks = root.networks;
        for (const network of [...rNetworks]) {
            rNetworks.splice(rNetworks.indexOf(network), 1);
            network.destroy();
        }
    }

    Process {
        id: connectProcess
        stdout: SplitParser {
            onRead: function(data) {
                console.log("Connect process output:", data);
                if (data.includes("successfully activated")) {
                    root.networkConnected(data);
                } else if (data.includes("Error:")) {
                    root.networkError(data);
                }
                getNetworks.running = true;
            }
        }
        stderr: SplitParser {
            onRead: function(data) {
                console.error("Connect process error:", data);
                root.networkError(data);
            }
        }
    }

    Process {
        id: disconnectProcess
        command: ["nmcli", "d", "disconnect", "wlan0"]
        stdout: SplitParser {
            onRead: function(data) {
                console.log("Disconnect process output:", data);
                root.networkDisconnected();
                getNetworks.running = true;
            }
        }
        stderr: SplitParser {
            onRead: function(data) {
                console.error("Disconnect process error:", data);
                root.networkError(data);
            }
        }
    }

    Process {
        id: toggleWifiProcess
        stdout: SplitParser {
            onRead: function(data) {
                console.log("WiFi toggle output:", data);
                // Force immediate status check after toggle
                Qt.callLater(() => {
                    wifiStatusProcess.running = true;
                });
            }
        }
        stderr: SplitParser {
            onRead: function(data) {
                console.error("WiFi toggle error:", data);
                root.networkError(data);
                // Still check status even if there's an error
                Qt.callLater(() => {
                    wifiStatusProcess.running = true;
                });
            }
        }
    }

    Process {
        id: forgetProcess
        stdout: SplitParser {
            onRead: function(data) {
                console.log("Forget process output:", data);
                if (data.includes("successfully deleted")) {
                    root.networkForgotten(data);
                } else if (data.includes("Error:")) {
                    root.networkError(data);
                }
                getNetworks.running = true;
                getKnownProcess.running = true;
            }
        }
        stderr: SplitParser {
            onRead: function(data) {
                console.error("Forget process error:", data);
                root.networkError(data);
            }
        }
    }

    Process {
        id: getKnownProcess
        command: ["nmcli", "-g", "NAME,TYPE", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const connections = text.trim().split("\n")
                    .filter(line => line.includes("802-11-wireless"))
                    .map(line => ({
                        name: line.split(":")[0]
                    }));

                const rKnownNetworks = root.knownNetworks;

                const destroyed = rKnownNetworks.filter(rn => !connections.find(c => c.name === rn.name));
                for (const network of destroyed)
                    rKnownNetworks.splice(rKnownNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const connection of connections) {
                    const match = rKnownNetworks.find(n => n.name === connection.name);
                    if (match) {
                        match.lastIpcObject = connection;
                    } else {
                        rKnownNetworks.push(knownComp.createObject(root, {
                            lastIpcObject: connection
                        }));
                    }
                }
            }
        }
    }

    Process {
        id: wifiStatusProcess
        running: true
        command: ["nmcli", "r", "wifi"]
        stdout: SplitParser {
            onRead: function(data) {
                const wasEnabled = root.enabled;
                const newEnabled = data.trim() === "enabled";
                console.log("WiFi status check: raw='" + data.trim() + "' enabled=" + newEnabled);

                if (root.enabled !== newEnabled) {
                    root.enabled = newEnabled;

                    if (newEnabled && !wasEnabled) {
                        // WiFi was just enabled, start scanning
                        console.log("WiFi enabled, starting network scan");
                        Qt.callLater(() => {
                            getNetworks.running = true;
                            getKnownProcess.running = true;
                        });
                    } else if (!newEnabled && wasEnabled) {
                        // WiFi was just disabled, clear networks
                        console.log("WiFi disabled, clearing networks");
                        clearNetworks();
                    }
                }

                // Only scan if WiFi is enabled
                if (root.enabled) {
                    Qt.callLater(() => {
                        getNetworks.running = true;
                        getKnownProcess.running = true;
                    });
                }

                // Schedule next check
                wifiStatusTimer.start();
            }
        }
        stderr: SplitParser {
            onRead: function(data) {
                console.error("WiFi status check error:", data);
                wifiStatusTimer.start();
            }
        }
    }

    Timer {
        id: wifiStatusTimer
        interval: 2000  // Check every 2 seconds
        onTriggered: {
            wifiStatusProcess.running = true;
        }
    }

    Process {
        id: getNetworks
        command: ["nmcli", "-g", "ACTIVE,SIGNAL,FREQ,SSID,BSSID", "d", "w"]
        stdout: StdioCollector {
            onStreamFinished: {
                // Only process results if WiFi is enabled
                if (!root.enabled) {
                    console.log("WiFi disabled, ignoring network scan results");
                    return;
                }

                const PLACEHOLDER = "STRINGWHICHHOPEFULLYWONTBEUSED";
                const rep = new RegExp("\\\\:", "g");
                const rep2 = new RegExp(PLACEHOLDER, "g");

                const networks = text.trim().split("\n")
                    .filter(line => line.trim() !== "" && line.includes(":"))
                    .map(n => {
                        try {
                            const net = n.replace(rep, PLACEHOLDER).split(":");
                            // Ensure we have all required fields
                            if (net.length < 4) {
                                console.warn("Skipping malformed network entry:", n);
                                return null;
                            }
                            return {
                                active: net[0] === "yes",
                                strength: parseInt(net[1]) || 0,
                                frequency: parseInt(net[2]) || 0,
                                ssid: net[3] || "Unknown",
                                bssid: net[4] ? net[4].replace(rep2, ":") : ""
                            };
                        } catch (error) {
                            console.error("Error parsing network entry:", n, error);
                            return null;
                        }
                    })
                    .filter(n => n !== null);
                const rNetworks = root.networks;

                const destroyed = rNetworks.filter(rn => !networks.find(n => n.frequency === rn.frequency && n.ssid === rn.ssid && n.bssid === rn.bssid));
                for (const network of destroyed)
                    rNetworks.splice(rNetworks.indexOf(network), 1).forEach(n => n.destroy());

                for (const network of networks) {
                    const match = rNetworks.find(n => n.frequency === network.frequency && n.ssid === network.ssid && n.bssid === network.bssid);
                    if (match) {
                        match.lastIpcObject = network;
                    } else {
                        rNetworks.push(apComp.createObject(root, {
                            lastIpcObject: network
                        }));
                    }
                }
            }
        }
        stderr: SplitParser {
            onRead: function(data) {
                console.error("Network scan error:", data);
            }
        }
    }

    component AccessPoint: QtObject {
        required property var lastIpcObject
        readonly property string ssid: lastIpcObject.ssid
        readonly property string bssid: lastIpcObject.bssid
        readonly property int strength: lastIpcObject.strength
        readonly property int frequency: lastIpcObject.frequency
        readonly property bool active: lastIpcObject.active
    }

    component KnownNetwork: QtObject {
        required property var lastIpcObject
        readonly property string name: lastIpcObject.name
    }

    Component {
        id: apComp

        AccessPoint {}
    }

    Component {
        id: knownComp

        KnownNetwork {}
    }
}
