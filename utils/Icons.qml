pragma Singleton

import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property var osIcons: ({
            almalinux: "",
            alpine: "",
            arch: "",
            archcraft: "",
            arcolinux: "",
            artix: "",
            centos: "",
            debian: "",
            devuan: "",
            elementary: "",
            endeavouros: "",
            fedora: "",
            freebsd: "",
            garuda: "",
            gentoo: "",
            hyperbola: "",
            kali: "",
            linuxmint: "󰣭",
            mageia: "",
            openmandriva: "",
            manjaro: "",
            neon: "",
            nixos: "",
            opensuse: "",
            suse: "",
            sles: "",
            sles_sap: "",
            "opensuse-tumbleweed": "",
            parrot: "",
            pop: "",
            raspbian: "",
            rhel: "",
            rocky: "",
            slackware: "",
            solus: "",
            steamos: "",
            tails: "",
            trisquel: "",
            ubuntu: "",
            vanilla: "",
            void: "",
            zorin: ""
        })

    readonly property var weatherIcons: ({
            "113": "clear_day",
            "116": "partly_cloudy_day",
            "119": "cloud",
            "122": "cloud",
            "143": "foggy",
            "176": "rainy",
            "179": "rainy",
            "182": "rainy",
            "185": "rainy",
            "200": "thunderstorm",
            "227": "cloudy_snowing",
            "230": "snowing_heavy",
            "248": "foggy",
            "260": "foggy",
            "263": "rainy",
            "266": "rainy",
            "281": "rainy",
            "284": "rainy",
            "293": "rainy",
            "296": "rainy",
            "299": "rainy",
            "302": "weather_hail",
            "305": "rainy",
            "308": "weather_hail",
            "311": "rainy",
            "314": "rainy",
            "317": "rainy",
            "320": "cloudy_snowing",
            "323": "cloudy_snowing",
            "326": "cloudy_snowing",
            "329": "snowing_heavy",
            "332": "snowing_heavy",
            "335": "snowing",
            "338": "snowing_heavy",
            "350": "rainy",
            "353": "rainy",
            "356": "rainy",
            "359": "weather_hail",
            "362": "rainy",
            "365": "rainy",
            "368": "cloudy_snowing",
            "371": "snowing",
            "374": "rainy",
            "377": "rainy",
            "386": "thunderstorm",
            "389": "thunderstorm",
            "392": "thunderstorm",
            "395": "snowing"
        })

    readonly property var desktopEntrySubs: ({})

    readonly property var categoryIcons: ({
            WebBrowser: "web",
            Printing: "print",
            Security: "security",
            Network: "chat",
            Archiving: "archive",
            Compression: "archive",
            Development: "code",
            IDE: "code",
            TextEditor: "edit_note",
            Audio: "music_note",
            Music: "music_note",
            Player: "music_note",
            Recorder: "mic",
            Game: "sports_esports",
            FileTools: "folder",
            FileManager: "folder",
            Filesystem: "folder",
            FileTransfer: "folder",
            Settings: "settings",
            DesktopSettings: "settings",
            HardwareSettings: "settings",
            TerminalEmulator: "terminal",
            ConsoleOnly: "terminal",
            Utility: "build",
            Monitor: "monitor_heart",
            Midi: "graphic_eq",
            Mixer: "graphic_eq",
            AudioVideoEditing: "video_settings",
            AudioVideo: "music_video",
            Video: "videocam",
            Building: "construction",
            Graphics: "photo_library",
            "2DGraphics": "photo_library",
            RasterGraphics: "photo_library",
            TV: "tv",
            System: "host",
            Office: "content_paste"
        })

    property string osIcon: ""
    property string osName

    function getDesktopEntry(name: string): DesktopEntry {
        name = name.toLowerCase().replace(/ /g, "-");

        if (desktopEntrySubs.hasOwnProperty(name))
            name = desktopEntrySubs[name];

        return DesktopEntries.applications.values.find(a => a.id.toLowerCase() === name) ?? null;
    }

    function getAppIcon(name: string, fallback: string): string {
        return Quickshell.iconPath(getDesktopEntry(name)?.icon, fallback);
    }

    function getAppCategoryIcon(name: string, fallback: string): string {
        if (!name) return fallback;

        const desktopEntry = getDesktopEntry(name);
        const categories = desktopEntry?.categories;

        // First try to match by categories
        if (categories) {
            for (const [key, value] of Object.entries(categoryIcons)) {
                if (categories.includes(key)) {
                    console.log(`Icon found by category for ${name}: ${value}`);
                    return value;
                }
            }
        }

        // If no category match, try some common app name patterns
        const lowerName = name.toLowerCase();

        // Common app patterns
        if (lowerName.includes('file') || lowerName.includes('nautilus') || lowerName.includes('thunar') ||
            lowerName === 'files' || lowerName === 'org.gnome.nautilus' || lowerName === 'nemo' ||
            lowerName === 'org.gnome.files' || lowerName === 'pcmanfm') {
            console.log(`Icon found by pattern for ${name}: folder`);
            return "folder";
        }
        if (lowerName.includes('browser') || lowerName.includes('firefox') || lowerName.includes('chrome')) {
            return "web";
        }
        if (lowerName.includes('terminal') || lowerName.includes('konsole') || lowerName.includes('alacritty')) {
            return "terminal";
        }
        if (lowerName.includes('code') || lowerName.includes('editor') || lowerName.includes('vim')) {
            return "code";
        }
        if (lowerName.includes('music') || lowerName.includes('audio') || lowerName.includes('spotify')) {
            return "music_note";
        }
        if (lowerName.includes('video') || lowerName.includes('vlc') || lowerName.includes('player')) {
            return "play_arrow";
        }
        if (lowerName.includes('game')) {
            return "sports_esports";
        }
        if (lowerName.includes('settings') || lowerName.includes('control')) {
            return "settings";
        }

        console.log(`No icon match found for ${name}, using fallback: ${fallback}`);
        return fallback;
    }

    function getNetworkIcon(strength: int): string {
        if (strength >= 80)
            return "signal_wifi_4_bar";
        if (strength >= 60)
            return "network_wifi_3_bar";
        if (strength >= 40)
            return "network_wifi_2_bar";
        if (strength >= 20)
            return "network_wifi_1_bar";
        return "signal_wifi_0_bar";
    }

    function getBluetoothIcon(icon: string): string {
        if (icon.includes("headset") || icon.includes("headphones"))
            return "headphones";
        if (icon.includes("audio"))
            return "speaker";
        if (icon.includes("phone"))
            return "smartphone";
        return "bluetooth";
    }

    function getWeatherIcon(code: string): string {
        if (weatherIcons.hasOwnProperty(code))
            return weatherIcons[code];
        return "air";
    }

    FileView {
        path: "/etc/os-release"
        onLoaded: {
            const lines = text().split("\n");
            let osId = lines.find(l => l.startsWith("ID="))?.split("=")[1];
            if (root.osIcons.hasOwnProperty(osId))
                root.osIcon = root.osIcons[osId];
            else {
                const osIdLike = lines.find(l => l.startsWith("ID_LIKE="))?.split("=")[1];
                if (osIdLike)
                    for (const id of osIdLike.split(" "))
                        if (root.osIcons.hasOwnProperty(id))
                            return root.osIcon = root.osIcons[id];
            }

            let nameLine = lines.find(l => l.startsWith("PRETTY_NAME="));
            if (!nameLine)
                nameLine = lines.find(l => l.startsWith("NAME="));
            root.osName = nameLine.split("=")[1].slice(1, -1);
        }
    }
}
