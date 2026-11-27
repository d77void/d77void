import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Services.Pipewire
import Quickshell.Services.UPower

Scope {
    id: controls
    readonly property var audio: Pipewire.defaultAudioSink?.audio ?? null
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery?.isLaptopBattery ?? false
    readonly property int batteryPercent: hasBattery
        ? Math.round(Math.min(1, Math.max(0, battery.percentage)) * 100) : 0
    readonly property bool charging: hasBattery && battery.state === UPowerDeviceState.Charging
    readonly property string batteryStatus: {
        if (!hasBattery)
            return ""
        if (charging)
            return battery.timeToFull > 0 ? Texts.tr("%1 until full").arg(duration(battery.timeToFull)) : Texts.tr("Charging")
        if (battery.state === UPowerDeviceState.Discharging)
            return battery.timeToEmpty > 0 ? Texts.tr("%1 remaining").arg(duration(battery.timeToEmpty)) : Texts.tr("On battery")
        if (battery.state === UPowerDeviceState.FullyCharged)
            return Texts.tr("Fully charged")
        return Texts.tr("Plugged in")
    }
    // Power profiles in the order the battery tile cycles through them.
    readonly property var powerProfiles: PowerProfiles.hasPerformanceProfile
        ? [PowerProfile.PowerSaver, PowerProfile.Balanced, PowerProfile.Performance]
        : [PowerProfile.PowerSaver, PowerProfile.Balanced]
    readonly property int powerProfile: PowerProfiles.profile
    property int brightness: -1
    readonly property string network: Networking.backend !== NetworkBackendType.NetworkManager
        ? "Unavailable" : Networking.devices.values.some(device => device.connected) ? "connected" : "disconnected"
    property string osdLabel: ""
    property real osdLevel: 0
    // -1 for a level OSD (volume, brightness); otherwise the index of the
    // power profile shown, in powerProfiles.
    property int osdProfile: -1
    readonly property bool osdVisible: osdTimer.running

    PwObjectTracker { objects: [Pipewire.defaultAudioSink].filter(Boolean) }

    function show(label, level): void {
        osdLabel = label
        osdLevel = level
        osdProfile = -1
        osdTimer.restart()
    }

    function duration(seconds: real): string {
        const total = Math.round(seconds / 60)
        const hours = Math.floor(total / 60)
        return hours > 0 ? hours + " h " + total % 60 + " min" : total + " min"
    }

    function profileName(profile: int): string {
        switch (profile) {
        case PowerProfile.PowerSaver: return Texts.tr("Power saver")
        case PowerProfile.Performance: return Texts.tr("Performance")
        default: return Texts.tr("Balanced")
        }
    }

    function cyclePowerProfile(): void {
        const next = powerProfiles[(powerProfiles.indexOf(powerProfile) + 1) % powerProfiles.length]
        PowerProfiles.profile = next
        osdLabel = profileName(next)
        osdProfile = powerProfiles.indexOf(next)
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

}
