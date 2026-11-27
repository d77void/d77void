import QtQuick

Rectangle {
    id: pane

    required property var theme
    property real baseOpacity: theme.opacity

    radius: 26
    border.color: theme.outline
    gradient: Gradient {
        GradientStop { position: 0; color: pane.theme.glassTop(pane.baseOpacity) }
        GradientStop { position: 0.44; color: pane.theme.glassBase(pane.baseOpacity) }
        GradientStop { position: 1; color: pane.theme.glassBottom(pane.baseOpacity) }
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        radius: Math.max(0, pane.radius - 1)
        color: "transparent"
        border.color: "#14ffffff"
    }
}
