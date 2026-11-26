import QtQuick
import Quickshell
import Quickshell.Io

Scope {
    id: root

    property var windows: []
    property var workspaces: []
    property bool available: false
    readonly property var focusedWindow: windows.find(window => window.is_focused) ?? null
    property int retryDelay: 250

    function action(...args): void {
        Quickshell.execDetached(["niri", "msg", "action", ...args])
    }

    function hidden(window): bool {
        return workspaces.some(workspace => workspace.id === window.workspace_id
            && workspace.name === "pmMac Hidden")
    }

    function windowAction(action, windows): void {
        if (available && windows.length && !windowWorker.running)
            windowWorker.exec(["python3", Quickshell.shellPath("window-state.py"),
                action, ...windows.map(window => String(window.id))])
    }

    function focusWindow(id): void {
        const window = windows.find(window => window.id === id)
        if (!available || !window)
            return
        if (hidden(window))
            windowAction("restore", [window])
        else
            action("focus-window", "--id", String(id))
    }

    function receive(line): void {
        let event
        try {
            event = JSON.parse(line)
        } catch (error) {
            console.warn("Invalid Niri event:", error)
            return
        }

        if (event.WindowsChanged) {
            windows = event.WindowsChanged.windows
            available = true
            retryDelay = 250
        } else if (event.WindowOpenedOrChanged) {
            const changed = event.WindowOpenedOrChanged.window
            const updated = windows.map(window => window.id === changed.id ? changed : window)
            if (!updated.includes(changed))
                updated.push(changed)
            windows = changed.is_focused
                ? updated.map(window => Object.assign({}, window, { is_focused: window.id === changed.id }))
                : updated
        } else if (event.WindowClosed) {
            windows = windows.filter(window => window.id !== event.WindowClosed.id)
        } else if (event.WindowFocusChanged) {
            windows = windows.map(window => Object.assign({}, window, {
                is_focused: window.id === event.WindowFocusChanged.id
            }))
        } else if (event.WorkspacesChanged) {
            workspaces = event.WorkspacesChanged.workspaces
        } else if (event.WorkspaceActivated) {
            const activation = event.WorkspaceActivated
            const active = workspaces.find(workspace => workspace.id === activation.id)
            if (active) {
                workspaces = workspaces.map(workspace => Object.assign({}, workspace, {
                    is_active: workspace.output === active.output
                        ? workspace.id === active.id : workspace.is_active,
                    is_focused: activation.focused
                        ? workspace.id === active.id : workspace.is_focused
                }))
            }
        } else if (event.WorkspaceActiveWindowChanged) {
            const change = event.WorkspaceActiveWindowChanged
            workspaces = workspaces.map(workspace => workspace.id === change.workspace_id
                ? Object.assign({}, workspace, { active_window_id: change.active_window_id }) : workspace)
        }
    }

    Process {
        id: windowWorker
        stderr: StdioCollector { id: windowError }
        onExited: code => {
            if (code !== 0)
                console.warn("Could not change window visibility:", windowError.text.trim())
        }
    }

    // Niri sends the initial state as the first events of each connection.
    Process {
        id: stream
        command: ["niri", "msg", "--json", "event-stream"]
        running: true
        stdout: SplitParser { onRead: line => root.receive(line) }
        onExited: {
            root.available = false
            root.windows = []
            root.workspaces = []
            reconnect.start()
        }
    }

    Timer {
        id: reconnect
        interval: root.retryDelay
        onTriggered: {
            root.retryDelay = Math.min(8000, root.retryDelay * 2)
            stream.running = true
        }
    }
}
