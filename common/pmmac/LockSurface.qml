import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell

Rectangle {
    id: surface
    required property var controller
    required property var theme
    property url wallpaper
    property string userName

    gradient: Gradient {
        GradientStop { position: 0; color: "#162d33" }
        GradientStop { position: 0.58; color: "#365a54" }
        GradientStop { position: 1; color: "#15282c" }
    }

    Image {
        anchors.fill: parent
        source: surface.wallpaper
        fillMode: Image.PreserveAspectCrop
        asynchronous: true
        sourceSize.height: 2160
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#76101923" }
            GradientStop { position: 0.50; color: "#24101923" }
            GradientStop { position: 1; color: "#a8101923" }
        }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        y: Math.round(surface.height * 0.13)
        spacing: 3

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Texts.day(clock.date, false)
            color: surface.theme.text
            font.family: surface.theme.font
            font.pixelSize: Math.max(15, Math.min(25, surface.height * 0.036))
            font.weight: Font.Medium
        }

        Label {
            Layout.alignment: Qt.AlignHCenter
            text: Texts.clock(clock.date, "")
            color: surface.theme.text
            font.family: surface.theme.font
            font.pixelSize: Math.max(56, Math.min(120, surface.height * 0.16))
            font.weight: Font.DemiBold
            font.letterSpacing: -3
        }
    }

    ColumnLayout {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: Math.max(18, parent.height * 0.10)
        width: Math.min(270, parent.width - 28)
        spacing: 10

        Rectangle {
            Layout.alignment: Qt.AlignHCenter
            Layout.preferredWidth: 58
            Layout.preferredHeight: 58
            radius: 29
            color: "#b42b4946"
            border.color: surface.theme.accent

            Label {
                anchors.centerIn: parent
                text: surface.userName.slice(0, 1).toUpperCase()
                color: surface.theme.text
                font.family: surface.theme.font
                font.pixelSize: 27
                font.weight: Font.DemiBold
            }
        }

        Label {
            Layout.fillWidth: true
            text: surface.userName
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            color: surface.theme.text
            font.family: surface.theme.font
            font.pixelSize: 16
            font.weight: Font.DemiBold
        }

        TextField {
            id: password
            Layout.fillWidth: true
            implicitHeight: 42
            leftPadding: 14
            rightPadding: 42
            color: surface.theme.text
            placeholderTextColor: surface.theme.muted
            placeholderText: Texts.tr("Enter password")
            font.family: surface.theme.font
            echoMode: TextInput.Password
            inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
            readOnly: surface.controller.busy
            focus: true
            Component.onCompleted: forceActiveFocus()
            Keys.onEscapePressed: clear()
            onAccepted: submit()

            function submit(): void {
                const input = text
                if (input && !surface.controller.busy) {
                    clear()
                    surface.controller.authenticate(input)
                }
            }

            background: GlassPane {
                theme: surface.theme
                baseOpacity: 0.62
                radius: 19
                border.color: password.activeFocus ? surface.theme.accent : surface.theme.outline
            }

            Button {
                id: submitButton
                anchors.right: parent.right
                anchors.rightMargin: 5
                anchors.verticalCenter: parent.verticalCenter
                width: 32
                height: 32
                focusPolicy: Qt.NoFocus
                enabled: !surface.controller.busy && password.length > 0
                text: "→"
                Accessible.name: Texts.tr("Unlock")
                onClicked: password.submit()
                contentItem: Label {
                    text: submitButton.text
                    color: submitButton.enabled ? surface.theme.text : surface.theme.muted
                    font.pixelSize: 18
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }
                background: Rectangle {
                    radius: 11
                    color: submitButton.enabled ? surface.theme.raised : "transparent"
                }
            }

            Connections {
                target: surface.controller
                function onBusyChanged() {
                    if (surface.controller.busy)
                        password.clear()
                }
            }
        }

        Label {
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            color: surface.theme.text
            text: surface.controller.busy ? Texts.tr("Checking password…") : surface.controller.message
            visible: text !== ""
            wrapMode: Text.WordWrap
        }
    }
}
