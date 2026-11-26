import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: popup
    required property var theme
    required property Component body
    property bool corner: false
    property bool onLeft: false
    signal dismissed()

    anchors { top: popup.corner; right: popup.corner && !popup.onLeft; left: popup.corner && popup.onLeft }
    margins { top: 8; right: 10; left: 10 }
    exclusionMode: ExclusionMode.Normal
    color: "transparent"
    WlrLayershell.namespace: "pmmac-popup"
    WlrLayershell.layer: WlrLayer.Overlay
    BackgroundEffect.blurRegion: theme.blur ? popupBlur : null
    Region { id: popupBlur; item: pane; radius: pane.radius }
    mask: Region { item: pane; radius: pane.radius }
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.Exclusive

    Shortcut {
        sequence: "Escape"
        enabled: popup.visible
        onActivated: popup.dismissed()
    }

    GlassPane {
        id: pane
        anchors.fill: parent
        theme: popup.theme
        radius: 28

        FocusScope {
            id: focusScope
            anchors.fill: parent
            anchors.margins: 17
            focus: true
            Loader {
                anchors.fill: parent
                sourceComponent: popup.body
                onLoaded: {
                    if (item.takeFocus)
                        item.takeFocus()
                    else
                        focusScope.forceActiveFocus()
                }
            }
        }
    }
}
