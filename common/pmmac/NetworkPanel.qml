import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.Models
import Quickshell
import Quickshell.Io
import Quickshell.Networking

ColumnLayout {
    id: panel

    required property var theme
    required property var ui
    readonly property var wifiDevices: Networking.devices.values.filter(device =>
        device.type === DeviceType.Wifi && device.nmManaged)
    readonly property var wiredDevices: Networking.devices.values.filter(device =>
        device.type === DeviceType.Wired && device.nmManaged)
    readonly property var wifiNetworks: {
        const networks = []
        for (const device of wifiDevices) {
            for (const network of device.networks.values) {
                if (network.name)
                    networks.push(network)
            }
        }
        return networks.sort((a, b) => Number(b.connected) - Number(a.connected)
            || Number(b.known) - Number(a.known)
            || b.signalStrength - a.signalStrength
            || a.name.localeCompare(b.name))
    }
    readonly property bool wifiEnabled: Networking.wifiEnabled
    property var pendingNetwork: null
    property bool pendingDisconnect: false
    property var passwordNetwork: null
    property string message: ""
    property bool editorAvailable: false
    spacing: 9

    function passwordSupported(network): bool {
        return network.security === WifiSecurityType.WpaPsk
            || network.security === WifiSecurityType.Wpa2Psk
            || network.security === WifiSecurityType.Sae
    }

    function openNetwork(network, wireless): void {
        if (pendingNetwork)
            return
        message = ""
        passwordNetwork = null
        password.clear()
        if (network.connected) {
            pendingDisconnect = true
            pendingNetwork = network
            connectTimeout.restart()
            network.disconnect()
        } else if (wireless && !network.known && passwordSupported(network)) {
            askForPassword(network)
        } else if (wireless && !network.known
                   && network.security !== WifiSecurityType.Open && network.security !== WifiSecurityType.Owe) {
            message = Texts.tr("This network needs an advanced connection profile.")
        } else {
            pendingNetwork = network
            connectTimeout.restart()
            network.connect()
        }
    }

    function askForPassword(network): void {
        password.clear()
        passwordNetwork = network
        password.forceActiveFocus()
    }

    function submitPassword(): void {
        if (!passwordNetwork || pendingNetwork || !password.text)
            return
        const network = passwordNetwork
        const secret = password.text
        password.clear()
        passwordNetwork = null
        message = ""
        pendingNetwork = network
        connectTimeout.restart()
        network.connectWithPsk(secret)
    }

    function finishConnection(): void {
        connectTimeout.stop()
        pendingNetwork = null
        pendingDisconnect = false
    }

    Connections {
        target: panel.pendingNetwork

        function onConnectedChanged() {
            if (target && target.connected !== panel.pendingDisconnect)
                panel.finishConnection()
        }

        function onConnectionFailed(reason) {
            const network = target
            const wasDisconnecting = panel.pendingDisconnect
            panel.finishConnection()
            if (wasDisconnecting) {
                panel.message = Texts.tr("Could not disconnect from the network.")
            } else if (reason === ConnectionFailReason.NoSecrets && network && panel.passwordSupported(network)) {
                panel.message = Texts.tr("Check the Wi-Fi password and try again.")
                panel.askForPassword(network)
            } else {
                panel.message = Texts.tr("Could not connect. Check the network and try again.")
            }
        }
    }

    Timer {
        id: connectTimeout
        interval: 45000
        onTriggered: {
            panel.message = Texts.tr(panel.pendingDisconnect
                ? "Could not disconnect from the network." : "The connection took too long. Try again.")
            panel.finishConnection()
        }
    }

    Instantiator {
        model: ScriptModel { values: panel.wifiEnabled ? panel.wifiDevices : [] }
        delegate: QtObject {
            required property var modelData
            Component.onCompleted: modelData.scannerEnabled = true
            Component.onDestruction: {
                if (modelData)
                    modelData.scannerEnabled = false
            }
        }
    }

    Timer { id: initialScan; interval: 4500; running: panel.wifiEnabled && panel.wifiDevices.length > 0 }

    Process {
        command: ["sh", "-c", "command -v nm-connection-editor >/dev/null"]
        running: true
        onExited: code => { panel.editorAvailable = code === 0 }
    }

    RowLayout {
        Layout.fillWidth: true

        Pill {
            text: Texts.tr("Back")
            onClicked: panel.ui.setPopup("dashboard")
        }

        Label {
            Layout.fillWidth: true
            text: Texts.tr("Network")
            color: panel.theme.text
            font.family: panel.theme.font
            font.pixelSize: 18
            font.weight: Font.DemiBold
        }

        Switch {
            visible: panel.wifiDevices.length > 0
            enabled: Networking.wifiHardwareEnabled && !panel.pendingNetwork
            text: "Wi-Fi"
            checked: panel.wifiEnabled
            onToggled: {
                password.clear()
                panel.passwordNetwork = null
                panel.message = ""
                Networking.wifiEnabled = checked
            }
        }
    }

    Repeater {
        model: ScriptModel { values: panel.wiredDevices }
        delegate: ConnectionRow {
            required property var modelData
            readonly property var connection: modelData?.network
            Layout.fillWidth: true
            name: "Ethernet"
            detail: connection?.connected ? Texts.tr("connected")
                : modelData?.hasLink ? Texts.tr("disconnected") : Texts.tr("Cable unplugged")
            connected: connection?.connected ?? false
            actionable: !!connection && (connected || !!modelData?.hasLink)
            busy: panel.pendingNetwork === connection && !!connection || (connection?.stateChanging ?? false)
            onActivated: panel.openNetwork(connection, false)
        }
    }

    Rectangle {
        visible: !!panel.passwordNetwork
        Layout.fillWidth: true
        implicitHeight: passwordForm.implicitHeight + 16
        radius: 12
        color: panel.theme.raised

        ColumnLayout {
            id: passwordForm
            anchors.fill: parent
            anchors.margins: 8

            Label {
                Layout.fillWidth: true
                text: panel.passwordNetwork?.name ?? ""
                textFormat: Text.PlainText
                elide: Text.ElideRight
                color: panel.theme.text
                font.family: panel.theme.font
                font.weight: Font.DemiBold
            }

            TextField {
                id: password
                Layout.fillWidth: true
                placeholderText: Texts.tr("Enter password")
                echoMode: TextInput.Password
                inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                onAccepted: panel.submitPassword()
            }

            RowLayout {
                Layout.alignment: Qt.AlignRight
                Pill {
                    text: Texts.tr("Cancel")
                    onClicked: {
                        password.clear()
                        panel.passwordNetwork = null
                        panel.message = ""
                    }
                }
                Pill {
                    text: Texts.tr("Connect")
                    enabled: !!password.text
                    onClicked: panel.submitPassword()
                }
            }
        }
    }

    Label {
        Layout.fillWidth: true
        visible: !!panel.message
        text: panel.message
        wrapMode: Text.WordWrap
        color: panel.theme.accent
        font.family: panel.theme.font
    }

    ListView {
        id: networks
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        spacing: 5
        model: ScriptModel { values: panel.wifiEnabled ? panel.wifiNetworks : [] }
        ScrollBar.vertical: ScrollBar {}

        delegate: ConnectionRow {
            required property var modelData
            width: networks.width
            name: modelData?.name ?? ""
            connected: modelData?.connected ?? false
            actionable: true
            busy: panel.pendingNetwork === modelData || (modelData?.stateChanging ?? false)
            detail: (connected ? Texts.tr("connected") : modelData?.known ? Texts.tr("Saved")
                : modelData?.security === WifiSecurityType.Open ? Texts.tr("Open network")
                : Texts.tr("Secured")) + " · " + Math.round((modelData?.signalStrength ?? 0) * 100) + "%"
            onActivated: panel.openNetwork(modelData, true)
        }

        Label {
            anchors.centerIn: parent
            width: parent.width
            visible: networks.count === 0
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            color: panel.theme.muted
            font.family: panel.theme.font
            text: Networking.backend !== NetworkBackendType.NetworkManager
                ? Texts.tr("NetworkManager unavailable")
                : panel.wifiDevices.length === 0 ? Texts.tr("No Wi-Fi device")
                : !Networking.wifiHardwareEnabled ? Texts.tr("Wi-Fi is blocked by a hardware switch")
                : !panel.wifiEnabled ? Texts.tr("Wi-Fi is off")
                : initialScan.running ? Texts.tr("Looking for Wi-Fi networks…")
                : Texts.tr("No Wi-Fi networks found")
        }
    }

    Pill {
        visible: panel.editorAvailable
        Layout.alignment: Qt.AlignRight
        text: Texts.tr("Advanced settings")
        onClicked: {
            panel.ui.setPopup("")
            Quickshell.execDetached(["nm-connection-editor"])
        }
    }

    component ConnectionRow: Rectangle {
        id: row

        required property string name
        required property string detail
        required property bool connected
        required property bool actionable
        property bool busy: false
        signal activated()
        implicitHeight: 49
        radius: 11
        color: panel.theme.raised

        RowLayout {
            anchors.fill: parent
            anchors.margins: 7
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 1
                Label {
                    Layout.fillWidth: true
                    text: row.name
                    textFormat: Text.PlainText
                    elide: Text.ElideRight
                    color: panel.theme.text
                    font.family: panel.theme.font
                    font.weight: Font.DemiBold
                }
                Label {
                    Layout.fillWidth: true
                    text: row.detail
                    elide: Text.ElideRight
                    color: row.connected ? panel.theme.accent : panel.theme.muted
                    font.family: panel.theme.font
                }
            }
            Pill {
                visible: row.actionable
                enabled: !row.busy && !panel.pendingNetwork && !panel.passwordNetwork
                text: row.busy ? Texts.tr("Please wait…")
                    : row.connected ? Texts.tr("Disconnect") : Texts.tr("Connect")
                onClicked: row.activated()
            }
        }
    }

    component Pill: Button {
        id: button
        horizontalPadding: 9
        verticalPadding: 5

        contentItem: Label {
            text: button.text
            color: button.enabled ? panel.theme.text : panel.theme.muted
            font.family: panel.theme.font
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: height / 2
            color: button.hovered || button.down ? "#40e2eaff" : panel.theme.raised
            border.color: button.activeFocus ? panel.theme.accent : "#16ffffff"
        }
    }
}
