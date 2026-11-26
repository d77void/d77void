import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: osd
    required property var controls
    required property var theme

    anchors.bottom: true
    margins.bottom: 22
    exclusionMode: ExclusionMode.Normal
    implicitWidth: 216
    implicitHeight: 64
    color: "transparent"
    WlrLayershell.namespace: "pmmac-osd"
    WlrLayershell.layer: WlrLayer.Overlay
    mask: Region {}

    GlassPane {
        anchors.fill: parent
        radius: 20
        theme: osd.theme
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 12
            Label { text: osd.controls.osdLabel; color: osd.theme.text }
            ProgressBar { Layout.fillWidth: true; value: osd.controls.osdLevel }
        }
    }
}
