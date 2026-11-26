import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: osd
    required property var controls
    required property var theme

    // Power profile changes get a macOS-style card: the mode name over one
    // segment per profile, the active one lit. Volume and brightness keep the
    // level bar.
    readonly property bool profileMode: controls.osdProfile >= 0

    anchors.bottom: true
    margins.bottom: 22
    exclusionMode: ExclusionMode.Normal
    implicitWidth: profileMode ? 252 : 216
    implicitHeight: profileMode ? 104 : 64
    color: "transparent"
    WlrLayershell.namespace: "pmmac-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}

    GlassPane {
        anchors.fill: parent
        radius: osd.profileMode ? 24 : 20
        theme: osd.theme

        ColumnLayout {
            visible: !osd.profileMode
            anchors.fill: parent
            anchors.margins: 12
            Label { text: osd.controls.osdLabel; color: osd.theme.text }
            ProgressBar { Layout.fillWidth: true; value: osd.controls.osdLevel }
        }

        ColumnLayout {
            visible: osd.profileMode
            anchors.fill: parent
            anchors.margins: 14
            spacing: 4

            Label {
                Layout.alignment: Qt.AlignHCenter
                text: Texts.tr("Power Mode")
                color: osd.theme.muted
                font.family: osd.theme.font
                font.pixelSize: 12
            }
            Label {
                Layout.alignment: Qt.AlignHCenter
                text: osd.controls.osdLabel
                color: osd.theme.text
                font.family: osd.theme.font
                font.pixelSize: 19
                font.weight: Font.DemiBold
            }
            Item { Layout.fillHeight: true }
            RowLayout {
                Layout.fillWidth: true
                spacing: 6
                Repeater {
                    model: osd.controls.powerProfiles.length
                    Rectangle {
                        required property int index
                        Layout.fillWidth: true
                        implicitHeight: 7
                        radius: 4
                        color: index === osd.controls.osdProfile ? osd.theme.accent : osd.theme.raised
                        border.color: "#16ffffff"
                    }
                }
            }
        }
    }
}
