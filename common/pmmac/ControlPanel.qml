import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: panel

    required property var controls
    required property var ui
    required property var theme

    spacing: 9

    PanelLabel {
        text: Texts.tr("Control Center")
        color: panel.theme.text
        font.pixelSize: 18
        font.weight: Font.DemiBold
    }

    RowLayout {
        Layout.fillWidth: true
        spacing: 8

        StatusTile {
            caption: Texts.tr("Network")
            detail: Texts.tr(panel.controls.network)
            note: Texts.tr("Click to configure")
            onClicked: {
                panel.controls.openNetworkSettings()
                panel.ui.setPopup("")
            }
        }
        StatusTile {
            visible: panel.controls.hasBattery
            caption: Texts.tr("Battery") + " · " + Math.round((panel.controls.battery?.percentage ?? 0) * 100) + "%"
            detail: panel.controls.batteryStatus
            note: panel.controls.profileName(panel.controls.powerProfile)
            onClicked: panel.controls.cyclePowerProfile()
        }
    }

    ColumnLayout {
        Layout.fillWidth: true
        spacing: 4

        PanelLabel {
            text: panel.controls.audio ? Texts.tr("Volume") : Texts.tr("Volume unavailable")
            color: panel.theme.text
            font.weight: Font.DemiBold
        }

        RowLayout {
            Layout.fillWidth: true

            LevelSlider {
                Layout.fillWidth: true
                enabled: !!panel.controls.audio
                Accessible.name: Texts.tr("Volume")
                value: panel.controls.audio?.volume ?? 0
                onMoved: panel.controls.setVolume(value)
            }
            PillButton {
                enabled: !!panel.controls.audio
                text: panel.controls.audio?.muted ? Texts.tr("Unmute") : Texts.tr("Mute")
                onClicked: panel.controls.mute()
            }
        }
    }

    ColumnLayout {
        visible: panel.controls.brightness >= 0
        Layout.fillWidth: true
        spacing: 4

        PanelLabel {
            text: Texts.tr("Brightness")
            color: panel.theme.text
            font.weight: Font.DemiBold
        }
        LevelSlider {
            Layout.fillWidth: true
            Accessible.name: Texts.tr("Brightness")
            from: 1
            to: 100
            stepSize: 1
            value: panel.controls.brightness
            onPressedChanged: { if (!pressed && visible) panel.controls.setBrightness(value) }
        }
    }

    Item { Layout.fillHeight: true }

    RowLayout {
        Layout.fillWidth: true
        PillButton { Layout.fillWidth: true; text: Texts.tr("Wallpaper"); onClicked: panel.ui.togglePopup("wallpaper") }
        PillButton { Layout.fillWidth: true; text: Texts.tr("Session"); onClicked: panel.ui.togglePopup("session") }
    }

    component PanelLabel: Label {
        font.family: panel.theme.font
        font.pixelSize: 13
    }

    component StatusTile: Rectangle {
        id: status
        required property string caption
        required property string detail
        property string note: ""
        signal clicked()
        Layout.fillWidth: true
        Layout.minimumWidth: 0
        implicitHeight: note ? 68 : 52
        radius: 16
        color: tileMouse.containsMouse ? "#40e2eaff" : panel.theme.raised
        border.color: tileMouse.activeFocus ? panel.theme.accent : "#12ffffff"
        Accessible.role: Accessible.Button
        Accessible.name: caption + ", " + detail

        MouseArea {
            id: tileMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: status.clicked()
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 9
            spacing: 1
            PanelLabel {
                Layout.fillWidth: true
                text: status.caption
                color: panel.theme.text
                font.weight: Font.DemiBold
            }
            PanelLabel {
                Layout.fillWidth: true
                text: status.detail
                color: panel.theme.muted
                elide: Text.ElideRight
            }
            PanelLabel {
                visible: status.note !== ""
                Layout.fillWidth: true
                text: status.note
                color: panel.theme.accent
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }

    component LevelSlider: Slider {
        id: level
        implicitHeight: 30
        leftPadding: 0
        rightPadding: 0
        background: Rectangle {
            x: level.leftPadding
            y: (level.height - height) / 2
            width: level.availableWidth
            height: 25
            radius: 13
            color: panel.theme.raised
            border.color: level.activeFocus ? panel.theme.accent : "#16ffffff"
            opacity: level.enabled ? 1 : 0.60

            Rectangle {
                width: parent.width * level.position
                height: parent.height
                radius: parent.radius
                color: panel.theme.accent
            }
        }
        handle: Rectangle {
            x: level.leftPadding + level.visualPosition * (level.availableWidth - width)
            y: (level.height - height) / 2
            width: 15
            height: 15
            radius: 8
            color: panel.theme.text
            visible: level.enabled
        }
    }

    component PillButton: Button {
        id: button
        horizontalPadding: 11
        verticalPadding: 6
        contentItem: Label {
            text: button.text
            font.family: panel.theme.font
            color: button.enabled ? panel.theme.text : panel.theme.muted
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
