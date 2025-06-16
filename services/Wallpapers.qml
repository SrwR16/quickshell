pragma Singleton

import "root:/utils/scripts/fuzzysort.js" as Fuzzy
import "root:/utils"
import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: root

    readonly property string path: "/home/sarw/Pictures/Wallpapers"
    readonly property list<string> extensions: ["jpg", "jpeg", "png", "webp", "tif", "tiff"]

    Component.onCompleted: {
        console.log("Wallpaper path:", path);
    }

    readonly property list<Wallpaper> list: wallpapers.instances
    property bool showPreview: false
    readonly property string current: showPreview ? previewPath : actualCurrent
    property string previewPath
    property string actualCurrent: list.length > 0 ? list[0].path : ""

    readonly property list<var> preppedWalls: list.map(w => ({
                name: Fuzzy.prepare(w.name),
                path: Fuzzy.prepare(w.path),
                wall: w
            }))

    function fuzzyQuery(search: string): var {
        return Fuzzy.go(search, preppedWalls, {
            all: true,
            keys: ["name", "path"],
            scoreFn: r => r[0].score * 0.9 + r[1].score * 0.1
        }).map(r => r.obj.wall);
    }

    function setWallpaper(path: string): void {
        actualCurrent = path;
        setWall.path = path;
        setWall.startDetached();
    }

    function preview(path: string): void {
        previewPath = path;
        showPreview = true;
        getPreviewColoursProc.running = true;
    }

    function stopPreview(): void {
        showPreview = false;
        Colours.endPreviewOnNextChange = true;
    }

    reloadableId: "wallpapers"

    IpcHandler {
        target: "wallpaper"

        function get(): string {
            return root.actualCurrent;
        }

        function set(path: string): void {
            root.setWallpaper(path);
        }

        function list(): string {
            return root.list.map(w => w.path).join("\n");
        }
    }

    Process {
        id: getPreviewColoursProc

        // For now, skip color extraction since caelestia is not available
        // Just show preview without color updates
        onRunningChanged: {
            if (running) {
                // Simulate the color loading process
                running = false;
                Colours.showPreview = true;
            }
        }
    }

    Process {
        id: setWall

        property string path

        command: ["swww", "img", path]
    }

    Process {
        running: true
        command: ["find", root.path, "-type", "d", "-path", '*/.*', "-prune", "-o", "-not", "-name", '.*', "-type", "f", "-print"]
        stdout: StdioCollector {
            onStreamFinished: {
                console.log("Found wallpaper files:", text.trim());
                const files = text.trim().split("\n").filter(w => root.extensions.includes(w.slice(w.lastIndexOf(".") + 1)));
                console.log("Filtered wallpaper files:", files);
                wallpapers.model = files.sort();
            }
        }
    }

    Variants {
        id: wallpapers

        Wallpaper {}
    }

    component Wallpaper: QtObject {
        required property string modelData
        readonly property string path: modelData
        readonly property string name: path.slice(path.lastIndexOf("/") + 1, path.lastIndexOf("."))
    }
}
