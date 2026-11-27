import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: panel
    required property var ui
    required property var theme
    property string confirmAction: ""

    Label {
        text: Texts.tr("Session")
        color: panel.theme.text
        font.family: panel.theme.font
        font.pixelSize: 17
        font.bold: true
    }

    Repeater {
        model: [
            { action: "lock", name: Texts.tr("Lock screen") },
            { action: "suspend", name: Texts.tr("Suspend") },
            { action: "logout", name: Texts.tr("Log out") },
            { action: "reboot", name: Texts.tr("Restart") },
            { action: "poweroff", name: Texts.tr("Shut down") }
        ]

        delegate: ItemDelegate {
            id: row
            required property var modelData
            Layout.fillWidth: true
            implicitHeight: 40
            text: panel?.confirmAction === modelData.action
                ? Texts.tr(modelData.action === "reboot" ? "Confirm restart" : "Confirm shutdown")
                : modelData.name
            onClicked: {
                if (["lock", "logout", "suspend"].includes(modelData.action) || panel.confirmAction === modelData.action)
                    panel.ui.sessionAction(modelData.action)
                else
                    panel.confirmAction = modelData.action
            }
            background: Rectangle {
                radius: 8
                color: row.hovered || row.activeFocus || panel?.confirmAction === row.modelData.action
                    ? (panel?.theme.raised ?? "transparent") : "transparent"
            }
            contentItem: Label {
                text: row.text
                color: panel.theme.text
                font.family: panel.theme.font
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
