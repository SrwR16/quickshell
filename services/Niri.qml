pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property list<Client> clients: []
    readonly property list<Workspace> workspaces: []
    property Client activeClient: null
    property Workspace activeWorkspace: null
    property string focusedMonitor: ""
    readonly property int activeWsId: activeWorkspace?.id ?? 1
    property point cursorPos

    function reload() {
        getClients.running = true;
        getWorkspaces.running = true;
        getActiveWindow.running = true;
    }

    function dispatch(request) {
        Process.execute(["niri", "msg", request]);
    }

    Component.onCompleted: reload()

    // Monitor for niri events
    Process {
        running: true
        command: ["niri", "msg", "event-stream"]
        stdout: SplitParser {
            onRead: Qt.callLater(root.reload)
        }
    }

    Process {
        id: getClients
        command: ["niri", "msg", "windows"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rClients = root.clients;

                    // Clear existing clients
                    for (const client of rClients)
                        client.destroy();
                    rClients.length = 0;

                    // Parse text output from niri
                    const lines = text.trim().split('\n');
                    let currentClient = null;

                    for (const line of lines) {
                        if (line.startsWith('Window ID ')) {
                            if (currentClient) {
                                rClients.push(clientComp.createObject(root, {
                                    lastIpcObject: currentClient
                                }));
                            }
                            const idMatch = line.match(/Window ID (\d+)(?:\: \(focused\))?/);
                            const isFocused = line.includes('(focused)');
                            currentClient = {
                                id: parseInt(idMatch[1]),
                                title: "",
                                app_id: "",
                                is_focused: isFocused,
                                workspace: 1
                            };
                        } else if (line.includes('Title: ')) {
                            if (currentClient) {
                                currentClient.title = line.replace(/.*Title: "(.*)".*/, '$1');
                            }
                        } else if (line.includes('App ID: ')) {
                            if (currentClient) {
                                currentClient.app_id = line.replace(/.*App ID: "(.*)".*/, '$1');
                            }
                        } else if (line.includes('Workspace ID: ')) {
                            if (currentClient) {
                                currentClient.workspace = parseInt(line.replace(/.*Workspace ID: (\d+).*/, '$1'));
                            }
                        }
                    }

                    // Add the last client
                    if (currentClient) {
                        rClients.push(clientComp.createObject(root, {
                            lastIpcObject: currentClient
                        }));
                    }

                    // Find the focused client
                    root.activeClient = rClients.find(c => c.isFocused) || null;
                } catch (e) {
                    console.error("Failed to parse niri windows:", e);
                }
            }
        }
    }

    Process {
        id: getWorkspaces
        command: ["niri", "msg", "workspaces"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const rWorkspaces = root.workspaces;

                    // Clear existing workspaces
                    for (const workspace of rWorkspaces)
                        workspace.destroy();
                    rWorkspaces.length = 0;

                    // Parse text output from niri
                    const lines = text.trim().split('\n');

                    for (const line of lines) {
                        if (line.match(/^\s*[\*\s]\s*(\d+)/)) {
                            const isActive = line.trim().startsWith('*');
                            const id = parseInt(line.replace(/^\s*[\*\s]\s*(\d+).*/, '$1'));

                            const workspaceData = {
                                id: id,
                                name: id.toString(),
                                is_active: isActive,
                                is_empty: false
                            };

                            rWorkspaces.push(workspaceComp.createObject(root, {
                                lastIpcObject: workspaceData
                            }));
                        }
                    }

                    // Find active workspace
                    root.activeWorkspace = rWorkspaces.find(w => w.isActive) || rWorkspaces[0] || null;
                } catch (e) {
                    console.error("Failed to parse niri workspaces:", e);
                }
            }
        }
    }

    Process {
        id: getActiveWindow
        command: ["niri", "msg", "focused-window"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    if (text.trim()) {
                        const lines = text.trim().split('\n');
                        const idLine = lines[0];
                        if (idLine.includes('Window ID ')) {
                            const idMatch = idLine.match(/Window ID (\d+)/);
                            if (idMatch) {
                                const focusedId = parseInt(idMatch[1]);
                                root.activeClient = root.clients.find(c => c.id === focusedId) || null;
                            }
                        }
                    } else {
                        root.activeClient = null;
                    }
                } catch (e) {
                    console.error("Failed to parse niri focused window:", e);
                    root.activeClient = null;
                }
            }
        }
    }

    component Client: QtObject {
        required property var lastIpcObject
        readonly property int id: lastIpcObject.id ?? 0
        readonly property string title: lastIpcObject.title ?? ""
        readonly property string app_id: lastIpcObject.app_id ?? ""
        readonly property bool isFocused: lastIpcObject.is_focused ?? false
        readonly property int workspace: lastIpcObject.workspace ?? 1
    }

    component Workspace: QtObject {
        required property var lastIpcObject
        readonly property int id: lastIpcObject.id ?? 1
        readonly property string name: lastIpcObject.name ?? ""
        readonly property bool isActive: lastIpcObject.is_active ?? false
        readonly property bool isEmpty: lastIpcObject.is_empty ?? true
    }

    Component {
        id: clientComp
        Client {}
    }

    Component {
        id: workspaceComp
        Workspace {}
    }
}
