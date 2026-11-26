//@ pragma IconTheme WhiteSur-pmMac
//@ pragma StateDir $BASE/pmmac
import QtQuick
import Quickshell
import Quickshell.Io

ShellRoot {
    id: shell

    readonly property var screen: Quickshell.screens.find(screen => screen.name === shellSettings.outputName)
        ?? Quickshell.screens[0] ?? null
    readonly property var activeWindow: niriService.focusedWindow
    readonly property string applicationName: activeWindow
        ? applicationService.forWindow(activeWindow)?.name || activeWindow.app_id || activeWindow.title || ""
        : ""
    property string popup: ""

    function togglePopup(name): void {
        setPopup(popup === name ? "" : name)
    }

    function setPopup(name): void {
        if (name && dockLoader.item)
            dockLoader.item.selectedGroup = ""
        popup = name
    }

    function overview(): void {
        popup = ""
        niriService.action("toggle-overview")
    }

    function sessionAction(action): void {
        popup = ""
        if (action === "lock") {
            Quickshell.execDetached(["qs", "--no-duplicate", "--path", Quickshell.shellPath("locker.qml")])
        } else if (action === "logout") {
            niriService.action("quit")
        } else if (["suspend", "reboot", "poweroff"].includes(action)) {
            Quickshell.execDetached(["loginctl", action])
        }
    }

    Settings { id: shellSettings }
    Theme {
        id: shellTheme
        opacity: shellSettings.surfaceOpacity
        blur: shellSettings.backgroundBlur
        mix: wallpaperService.state.mix ?? 0.5
        palette: wallpaperService.state.palette ?? null
    }
    Niri { id: niriService }
    Applications { id: applicationService; settings: shellSettings; windows: niriService.windows }
    Controls { id: controlService }
    Wallpaper { id: wallpaperService }

    Loader {
        id: dockLoader
        active: !!shell.screen
        sourceComponent: Dock {
            screen: shell.screen
            niri: niriService
            apps: applicationService
            settings: shellSettings
            theme: shellTheme
            Connections {
                target: dockLoader.item
                function onChoosingChanged() {
                    if (dockLoader.item?.choosing)
                        shell.popup = ""
                }
            }
        }
    }

    Loader {
        active: !!shell.screen
        sourceComponent: TopBar {
            screen: shell.screen
            ui: shell
            theme: shellTheme
            applicationName: shell.applicationName
        }
    }

    Loader {
        active: !!shell.screen && controlService.osdVisible
        sourceComponent: Osd {
            screen: shell.screen
            controls: controlService
            theme: shellTheme
        }
    }

    Loader {
        active: !!shell.screen && shell.popup !== ""
        sourceComponent: PopupSurface {
            screen: shell.screen
            theme: shellTheme
            corner: shell.popup !== "launcher" && shell.popup !== "wallpaper"
            onLeft: shell.popup === "session"
            implicitWidth: Math.max(1, Math.min(shell.screen?.width - 28 || 260,
                shell.popup === "wallpaper" ? 706 : shell.popup === "launcher" ? 540 : 326))
            implicitHeight: {
                const heights = { launcher: 356, dashboard: 310, session: 290, wallpaper: 496 }
                return Math.max(1, Math.min(shell.screen?.height - 60 || 200, heights[shell.popup] ?? 200))
            }
            body: {
                const panels = { launcher, dashboard, session, wallpaper }
                return panels[shell.popup] ?? null
            }
            onDismissed: shell.popup = ""
        }
    }

    Component {
        id: launcher
        LauncherPanel {
            apps: applicationService
            theme: shellTheme
            onLaunched: shell.popup = ""
        }
    }
    Component { id: dashboard; ControlPanel { controls: controlService; ui: shell; theme: shellTheme } }
    Component { id: session; SessionPanel { ui: shell; theme: shellTheme } }
    Component {
        id: wallpaper
        WallpaperPanel {
            wallpaper: wallpaperService
            theme: shellTheme
            wallpaperDirectory: shellSettings.wallpaperDirectory
        }
    }

    IpcHandler {
        target: "launcher"
        function toggle(): void { shell.togglePopup("launcher") }
        function open(): void { shell.setPopup("launcher") }
        function close(): void { if (shell.popup === "launcher") shell.setPopup("") }
    }
    IpcHandler {
        target: "dashboard"
        function toggle(): void { shell.togglePopup("dashboard") }
        function open(): void { shell.setPopup("dashboard") }
        function close(): void { if (shell.popup === "dashboard") shell.setPopup("") }
    }
    IpcHandler {
        target: "session"
        function toggle(): void { shell.togglePopup("session") }
        function open(): void { shell.setPopup("session") }
        function close(): void { if (shell.popup === "session") shell.setPopup("") }
    }
    IpcHandler {
        target: "wallpaper"
        function toggle(): void { shell.togglePopup("wallpaper") }
        function open(): void { shell.setPopup("wallpaper") }
        function close(): void { if (shell.popup === "wallpaper") shell.setPopup("") }
    }
    IpcHandler {
        target: "overview"
        function toggle(): void { shell.overview() }
    }
    IpcHandler {
        target: "lockscreen"
        function lock(): void { shell.sessionAction("lock") }
    }
    IpcHandler {
        target: "osd"
        function volumeUp(): void { controlService.setVolume((controlService.audio?.volume ?? 0) + 0.05) }
        function volumeDown(): void { controlService.setVolume((controlService.audio?.volume ?? 0) - 0.05) }
        function volumeMuteToggle(): void { controlService.mute() }
        function brightnessUp(): void { controlService.setBrightness(controlService.brightness + 5) }
        function brightnessDown(): void { controlService.setBrightness(controlService.brightness - 5) }
    }
}
