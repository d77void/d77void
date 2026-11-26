import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: service

    property var state: ({ mix: 0.5 })
    property string error: ""
    readonly property bool busy: worker.running
    readonly property string statePath: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/pmmac/wallpaper.json"
    property var pending: []

    function run(action, value): void {
        const command = ["python3", Quickshell.shellPath("wallpaper.py"), action]
        if (value !== undefined)
            command.push(String(value))
        if (worker.running || pending.length) {
            pending = pending.filter(request => request[2] !== action)
            pending = pending.concat([command])
        } else {
            worker.exec(command)
        }
    }

    function runPending(): void {
        if (!worker.running && pending.length) {
            const next = pending[0]
            pending = pending.slice(1)
            worker.exec(next)
        }
    }

    Component.onCompleted: run("restore")

    FileView {
        id: saved
        path: service.statePath
        watchChanges: true
        printErrors: false
        onFileChanged: reload()
        onLoaded: {
            try {
                service.state = JSON.parse(text())
            } catch (error) {
                console.warn("Invalid pmMac wallpaper state:", error)
            }
        }
    }

    Process {
        id: worker
        stderr: StdioCollector { id: workerError }
        onExited: code => {
            saved.reload()
            service.error = code === 0 ? "" : Texts.tr("Could not update wallpaper.")
            if (code !== 0)
                console.warn("Could not update wallpaper:", workerError.text.trim())
            Qt.callLater(service.runPending)
        }
    }

    Connections {
        target: Quickshell
        function onScreensChanged() { service.run("restore") }
    }
}
