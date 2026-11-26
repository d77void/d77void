import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Scope {
    id: controls
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var battery: UPower.displayDevice
    property int brightness: -1
    property string network: "Unavailable"
    property string osdLabel: ""
    property real osdLevel: 0
    readonly property bool osdVisible: osdTimer.running

    PwObjectTracker { objects: [Pipewire.defaultAudioSink].filter(Boolean) }

    function show(label, level): void {
        osdLabel = label
        osdLevel = level
        osdTimer.restart()
    }

    function setVolume(volume): void {
        if (audio) {
            audio.volume = Math.min(1, Math.max(0, volume))
            show(audio.muted ? Texts.tr("Volume · Muted") : Texts.tr("Volume"), audio.muted ? 0 : audio.volume)
        }
    }

    function mute(): void {
        if (audio) {
            audio.muted = !audio.muted
            show(audio.muted ? Texts.tr("Volume · Muted") : Texts.tr("Volume"), audio.muted ? 0 : audio.volume)
        }
    }

    function refresh(): void {
        if (!briWrite.running)
            briRead.running = true
        networkRead.running = true
    }

    function setBrightness(level): void {
        if (brightness < 0)
            return
        const value = Math.min(100, Math.max(1, Math.round(level)))
        briWrite.exec(["brightnessctl", "-q", "set", value + "%"])
    }

    Component.onCompleted: refresh()
    Timer { id: osdTimer; interval: 1850 }
    Timer { interval: 10000; running: true; repeat: true; onTriggered: controls.refresh() }

    Process {
        id: briRead
        command: ["brightnessctl", "-m", "info"]
        stdout: StdioCollector {
            onStreamFinished: {
                const value = text.trim().split(",")[3]
                controls.brightness = value ? parseInt(value) : -1
            }
        }
        onExited: code => { if (code !== 0) controls.brightness = -1 }
    }

    Process {
        id: briWrite
        onExited: code => {
            if (code === 0) {
                const value = parseInt(command[3])
                controls.brightness = value
                controls.show(Texts.tr("Brightness"), value / 100)
            }
            briRead.running = true
        }
    }

    Process {
        id: networkRead
        command: ["nmcli", "-t", "-f", "STATE", "general", "status"]
        environment: ({ LC_ALL: "C" })
        stdout: StdioCollector {
            onStreamFinished: controls.network = text.trim() || "Unavailable"
        }
        onExited: code => { if (code !== 0) controls.network = "Unavailable" }
    }
}
