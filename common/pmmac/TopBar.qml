import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Shapes
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: bar

    required property var ui
    required property var theme
    required property string applicationName

    anchors { top: true; left: true; right: true }
    implicitHeight: 39
    color: "transparent"
    WlrLayershell.namespace: "pmmac-bar"
    BackgroundEffect.blurRegion: theme.blur ? barRegion : null

    Region {
        id: barRegion
        item: appIsland
        radius: appIsland.radius
        Region { item: statusIsland; radius: statusIsland.radius }
    }
    mask: Region {
        item: appIsland
        radius: appIsland.radius
        Region { item: statusIsland; radius: statusIsland.radius }
    }

    SystemClock { id: clock; precision: SystemClock.Minutes }

    GlassPane {
        id: appIsland
        anchors { top: parent.top; left: parent.left; topMargin: 5; leftMargin: 10 }
        height: 29
        width: Math.min(appItems.implicitWidth + 8, Math.max(80, bar.width - statusIsland.width - 30))
        radius: 14
        theme: bar.theme
        baseOpacity: theme.barOpacity

        RowLayout {
            id: appItems
            anchors.fill: parent
            anchors.margins: 3
            spacing: 4

            BarButton {
                Accessible.name: "pmMac · " + Texts.tr("Session")
                onClicked: bar.ui.togglePopup("session")
                contentItem: Item {
                    implicitWidth: 17
                    implicitHeight: 15

                    Shape {
                        anchors.centerIn: parent
                        width: 17
                        height: 15

                        ShapePath {
                            strokeColor: bar.theme.text
                            strokeWidth: 2.3
                            fillColor: "transparent"
                            capStyle: ShapePath.RoundCap
                            joinStyle: ShapePath.RoundJoin
                            startX: 2
                            startY: 12.5
                            PathLine { x: 5.3; y: 3.5 }
                            PathLine { x: 8.5; y: 8.1 }
                            PathLine { x: 11.7; y: 3.5 }
                            PathLine { x: 15; y: 12.5 }
                        }
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.minimumWidth: 0
                Layout.rightMargin: 8
                visible: text !== ""
                text: bar.applicationName
                color: bar.theme.muted
                font.family: bar.theme.font
                font.pixelSize: 13
                elide: Text.ElideRight
            }
        }
    }

    GlassPane {
        id: statusIsland
        anchors { top: parent.top; right: parent.right; topMargin: 5; rightMargin: 10 }
        height: 29
        width: statusItems.implicitWidth + 8
        radius: 14
        theme: bar.theme
        baseOpacity: theme.barOpacity

        RowLayout {
            id: statusItems
            anchors.fill: parent
            anchors.margins: 3
            spacing: 2

            BarButton {
                text: Texts.tr("Overview")
                visible: bar.width > 535
                onClicked: bar.ui.overview()
            }
            BarButton { text: Texts.tr("Search"); onClicked: bar.ui.togglePopup("launcher") }
            BarButton { text: Texts.tr("Controls"); onClicked: bar.ui.togglePopup("dashboard") }
            Label {
                leftPadding: 6
                rightPadding: 7
                text: bar.width > 680
                    ? Texts.day(clock.date, true) + "  " + Texts.clock(clock.date)
                    : Texts.clock(clock.date)
                color: bar.theme.text
                font.family: bar.theme.font
                font.pixelSize: 13
                font.weight: Font.Medium
            }
        }
    }

    component BarButton: Button {
        id: control
        Layout.fillHeight: true
        horizontalPadding: 8
        verticalPadding: 2
        contentItem: Label {
            text: control.text
            color: bar.theme.text
            font.family: bar.theme.font
            font.pixelSize: 13
            font.weight: Font.Medium
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignHCenter
        }
        background: Rectangle {
            radius: 10
            color: control.hovered || control.activeFocus || control.down ? bar.theme.raised : "transparent"
        }
    }
}
