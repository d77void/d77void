import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Pam
import Quickshell.Wayland

// Utumno uses one session-lock surface per output and one PAM conversation.
ShellRoot {
    id: root
    property bool busy: false
    property string answer: ""
    property string message: ""
    readonly property url wallpaper: {
        const state = wallpaperFile.text()
        if (!state)
            return ""
        try {
            const path = JSON.parse(state).path
            return path ? "file://" + path.split("/").map(encodeURIComponent).join("/") : ""
        } catch (error) {
            console.warn("Could not read the wallpaper state:", error)
            return ""
        }
    }

    Theme { id: lockTheme }

    Component.onCompleted: {
        Quickshell.watchFiles = false
        if (!Quickshell.env("NIRI_SOCKET"))
            Qt.quit()
        else
            safetyCheck.running = true
    }

    Process {
        id: safetyCheck
        command: ["sh", "-c",
            "test -r /etc/pam.d/amorphis && awk '/^NoNewPrivs:/ { safe = ($2 == 0) } END { exit !safe }' /proc/self/status"]
        onExited: code => {
            if (code === 0)
                lock.locked = true
            else {
                console.warn("Session lock requires the Amorphis PAM service and NoNewPrivs=0")
                Qt.quit()
            }
        }
    }

    FileView {
        id: wallpaperFile
        path: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/pmmac/wallpaper.json"
        printErrors: false
    }

    function authenticate(password): void {
        if (busy)
            return
        answer = password
        busy = true
        message = ""
        if (!pam.start())
            failed(Texts.tr("Authentication is unavailable."))
    }

    function failed(error): void {
        answer = ""
        message = error
        busy = false
    }

    PamContext {
        id: pam
        configDirectory: "/etc/pam.d"
        config: "amorphis"

        onPamMessage: {
            if (!responseRequired)
                return
            if (responseVisible || !root.answer) {
                abort()
                root.failed(Texts.tr("The authentication request could not be completed."))
                return
            }
            const response = root.answer
            root.answer = ""
            respond(response)
        }

        onError: root.failed(Texts.tr("Authentication is unavailable."))
        onCompleted: result => {
            if (result === PamResult.Success) {
                root.answer = ""
                lock.locked = false
                Qt.quit()
            } else {
                root.failed(result === PamResult.Failed
                    ? Texts.tr("Password not accepted.") : Texts.tr("Authentication could not be completed."))
            }
        }
    }

    WlSessionLock {
        id: lock
        locked: false
        WlSessionLockSurface {
            LockSurface {
                anchors.fill: parent
                controller: root
                theme: lockTheme
                userName: Quickshell.env("USER") || Texts.tr("User")
                wallpaper: root.wallpaper
            }
        }
    }
}
