import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root
    required property var settings
    required property var windows

    property string pinError: ""
    readonly property var pins: {
        const saved = pinFile.text()
        if (saved) {
            try {
                const entries = JSON.parse(saved)
                if (Array.isArray(entries) && entries.every(id => typeof id === "string"))
                    return entries
            } catch (error) {
                console.warn("Invalid saved dock pins:", error)
            }
        }
        return settings.pinnedApps
    }

    FileView {
        id: pinFile
        path: Quickshell.statePath("dock-pins.json")
        blockLoading: true
        blockWrites: true
        printErrors: false
        onSaveFailed: error => {
            root.pinError = Texts.tr("Could not save dock pins.")
            console.warn("Could not save dock pins:", error)
        }
    }

    function isPinned(entry): bool {
        return entry && pins.some(id => desktopId(id) === entry.id)
    }

    function togglePin(entry): void {
        if (!entry)
            return
        pinError = ""
        const updated = isPinned(entry)
            ? pins.filter(id => desktopId(id) !== entry.id)
            : Array.from(pins).concat(entry.id + ".desktop")
        pinFile.setText(JSON.stringify(updated) + "\n")
    }

    readonly property var entries: DesktopEntries.applications.values
    readonly property var index: {
        const ids = new Map()
        const classes = new Map()
        for (const entry of entries) {
            ids.set(entry.id, entry)
            const startup = entry.startupClass.toLowerCase()
            if (startup && !classes.has(startup))
                classes.set(startup, entry)
        }
        return { ids, classes }
    }
    readonly property var groups: buildGroups()

    function desktopId(identifier): string {
        return identifier.endsWith(".desktop") ? identifier.slice(0, -8) : identifier
    }

    function byId(identifier): var {
        const id = desktopId(identifier)
        return index.ids.get(id) ?? DesktopEntries.byId(id)
    }

    function forWindow(window): var {
        const appId = window.app_id
        if (!appId)
            return null
        const alias = settings.appAliases[appId]
        if (typeof alias === "string")
            return byId(alias)
        return byId(appId) ?? index.classes.get(appId.toLowerCase()) ?? null
    }

    function launch(entry): void {
        if (!entry)
            return
        // gtk-launch can't pick a terminal for Terminal=true entries: run
        // those through terminal.sh, which finds whichever one is installed.
        if (entry.runInTerminal && entry.command.length > 0) {
            Quickshell.execDetached({
                command: ["sh", Quickshell.shellPath("terminal.sh")].concat(entry.command),
                workingDirectory: entry.workingDirectory || Quickshell.env("HOME")
            })
        } else {
            Quickshell.execDetached(["gtk-launch", entry.id + ".desktop"])
        }
    }

    function icon(entry): string {
        const icon = entry?.id === "pcmanfm" ? "folder" : entry?.icon
        return Quickshell.iconPath(icon || "application-x-executable", "application-x-executable")
    }

    function buildGroups(): var {
        const groups = new Map()
        for (const pin of pins) {
            const entry = byId(pin)
            if (!entry)
                continue
            const key = "desktop:" + entry.id
            if (!groups.has(key))
                groups.set(key, { key, entry, name: entry.name, windows: [], focused: false })
        }

        for (const window of windows) {
            const entry = forWindow(window)
            const key = entry ? "desktop:" + entry.id
                : window.app_id ? "app:" + window.app_id : "window:" + window.id
            if (!groups.has(key)) {
                groups.set(key, {
                    key, entry, name: entry?.name || window.app_id || window.title || Texts.tr("Window"),
                    windows: [], focused: false
                })
            }
            const group = groups.get(key)
            group.windows.push(window)
            group.focused = group.focused || window.is_focused
        }
        return Array.from(groups.values())
    }
}
