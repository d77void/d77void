import QtQuick
import Quickshell

QtObject {
    // Desktop file IDs, in display order.
    property list<string> pinnedApps: ["librewolf.desktop", "pcmanfm.desktop", "Alacritty.desktop"]
    property var appAliases: ({ "LibreWolf": "librewolf.desktop", "Pcmanfm": "pcmanfm.desktop" })
    property string outputName: ""
    property string wallpaperDirectory: Quickshell.env("PMMAC_WALLPAPER_DIR") || Quickshell.env("HOME") + "/Wallpaper"
    property int dockHeight: 77
    property real dockHoverScale: 1.20
    property bool autoHideDock: false
    property bool backgroundBlur: true
    property real surfaceOpacity: 0.73
}
