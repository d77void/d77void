import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Widgets

PanelWindow {
    id: dock
    required property var niri
    required property var apps
    required property var settings
    required property var theme

    property string selectedGroup: ""
    property int selectedRow: 0
    property bool contextMenu: false
    readonly property var group: apps.groups.find(item => item.key === selectedGroup) ?? null
    readonly property var choices: menuItems()
    readonly property bool choosing: selectedGroup !== "" && !!group
    readonly property int dockHeight: settings.dockHeight
    property bool revealed: false
    readonly property bool shown: !settings.autoHideDock || revealed || choosing
    readonly property int availableWidth: Math.max(1, (screen?.width ?? 800) - 20)

    anchors.bottom: true
    margins.bottom: settings.autoHideDock ? 0 : 10
    implicitWidth: Math.min(availableWidth, Math.max(dockFrame.width, choosing ? 336 : 0))
    implicitHeight: shown ? dockHeight + (choosing ? picker.height + 8 : 0) : 4
    color: "transparent"
    exclusiveZone: settings.autoHideDock ? 0 : dockHeight
    WlrLayershell.namespace: "pmmac-dock"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: choosing ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    BackgroundEffect.blurRegion: theme.blur && shown ? paneBlur : null
    Region {
        id: paneBlur
        item: dockFrame
        radius: dockFrame.radius
        Region { item: dock.choosing ? picker : null; radius: picker.radius }
    }

    mask: Region {
        item: dock.shown ? dockFrame : revealStrip
        radius: dock.shown ? dockFrame.radius : 0
        Region { item: dock.choosing ? picker : null; radius: picker.radius }
    }

    onChoosingChanged: {
        if (!choosing && settings.autoHideDock && !dockHover.hovered)
            hideDelay.restart()
    }

    Timer {
        id: hideDelay
        interval: 520
        onTriggered: { if (!dockHover.hovered && !dock.choosing) dock.revealed = false }
    }

    Item {
        id: revealStrip
        anchors.fill: parent
        visible: !dock.shown

        HoverHandler {
            onHoveredChanged: {
                if (hovered) {
                    dock.revealed = true
                    hideDelay.restart()
                }
            }
        }
    }

    onChoicesChanged: Qt.callLater(reconcilePicker)

    function reconcilePicker(): void {
        const count = choices.length
        if (selectedGroup && count === 0)
            selectedGroup = ""
        selectedRow = Math.max(0, Math.min(selectedRow, count - 1))
    }

    function menuItems(): var {
        if (!group)
            return []
        const items = group.windows.map(window => ({
            key: "window:" + window.id,
            text: window.title || Texts.tr("Untitled window"),
            windowId: window.id
        }))
        if (group.entry) {
            items.push({ key: "launch", text: Texts.tr("Open new instance") })
            if (contextMenu)
                items.push({ key: "pin", text: Texts.tr(apps.isPinned(group.entry)
                    ? "Unpin from Dock" : "Pin to Dock") })
        }
        return items
    }

    function openPicker(item, showContext): void {
        apps.pinError = ""
        contextMenu = showContext
        selectedRow = 0
        selectedGroup = item.key
        picker.forceActiveFocus()
    }

    function activate(item, secondary): void {
        if (selectedGroup === item.key) {
            selectedGroup = ""
        } else if (secondary && (item.entry || item.windows.length > 0)) {
            openPicker(item, true)
        } else if (item.windows.length === 0) {
            selectedGroup = ""
            apps.launch(item.entry)
        } else if (item.windows.every(window => niri.hidden(window))) {
            niri.windowAction("restore", item.windows)
        } else if (item.focused) {
            const windows = item.windows.slice().sort((a, b) => Number(b.is_focused) - Number(a.is_focused))
            niri.windowAction("hide", windows)
        } else if (item.windows.length > 1) {
            openPicker(item, false)
        } else {
            selectedGroup = ""
            if (!item.focused)
                niri.focusWindow(item.windows[0].id)
        }
    }

    function perform(choice): void {
        if (!choice)
            return
        if (choice.key === "pin") {
            apps.togglePin(group?.entry)
        } else {
            const entry = group?.entry
            selectedGroup = ""
            if (choice.key === "launch")
                apps.launch(entry)
            else
                niri.focusWindow(choice.windowId)
        }
    }

    GlassPane {
        id: dockFrame
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        width: Math.min(dock.availableWidth, Math.max(106, appsRow.implicitWidth + 22))
        height: dock.dockHeight
        visible: dock.shown
        radius: Math.min(28, height / 2)
        theme: dock.theme
        baseOpacity: Math.max(0, dock.theme.opacity - 0.10)

        HoverHandler {
            id: dockHover
            blocking: false
            onHoveredChanged: {
                if (hovered)
                    hideDelay.stop()
                else if (settings.autoHideDock)
                    hideDelay.restart()
            }
        }

        Flickable {
            id: dockScroll
            anchors.fill: parent
            anchors.margins: 8
            clip: true
            contentWidth: Math.max(width, appsRow.implicitWidth)
            contentHeight: height
            interactive: contentWidth > width
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.horizontal: ScrollBar { policy: ScrollBar.AsNeeded }

            Row {
                id: appsRow
                x: Math.max(0, (dockScroll.width - width) / 2)
                height: dockScroll.height
                spacing: 6

                Label {
                    visible: !niri.available || apps.groups.length === 0
                    anchors.verticalCenter: parent.verticalCenter
                    leftPadding: 8
                    rightPadding: 8
                    text: !niri.available ? Texts.tr("Niri disconnected") : Texts.tr("No open applications")
                    color: theme.muted
                    font.family: theme.font
                }

                Repeater {
                    model: ScriptModel { values: apps.groups.map(item => item.key) }

                    delegate: Control {
                        id: tile
                        required property string modelData
                        readonly property var app: apps.groups.find(item => item.key === modelData)
                        padding: 0
                        topInset: 4
                        bottomInset: 8
                        width: 57
                        height: appsRow.height
                        hoverEnabled: true
                        Accessible.role: Accessible.Button
                        Accessible.name: app?.name ?? ""

                        background: Rectangle {
                            radius: 18
                            color: tile.hovered
                                || dock.selectedGroup === tile.modelData
                                ? theme.raised : "transparent"
                        }

                        contentItem: Item {
                            IconImage {
                                anchors.horizontalCenter: parent.horizontalCenter
                                y: Math.max(8, parent.height - implicitSize - 10)
                                implicitSize: Math.min(44, Math.max(16, parent.height - 20))
                                transformOrigin: Item.Bottom
                                scale: tile.hovered ? settings.dockHoverScale : 1
                                Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                source: apps.icon(tile.app?.entry)
                            }

                            Rectangle {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom
                                anchors.bottomMargin: 1
                                height: 4
                                width: tile.app?.focused ? 12 : 4
                                radius: 2
                                color: tile.app?.focused ? theme.accent : theme.muted
                                visible: (tile.app?.windows.length ?? 0) > 0
                            }
                        }

                        TapHandler {
                            acceptedButtons: Qt.LeftButton
                            onTapped: tile.app && dock.activate(tile.app, false)
                        }
                        TapHandler {
                            acceptedButtons: Qt.RightButton
                            onTapped: tile.app && dock.activate(tile.app, true)
                        }
                    }
                }
            }
        }
    }

    GlassPane {
        id: picker
        visible: dock.choosing
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: dockFrame.top
        anchors.bottomMargin: 8
        width: Math.min(parent.width, 336)
        height: pickerLayout.implicitHeight + 20
        radius: 22
        theme: dock.theme
        focus: visible

        Keys.onEscapePressed: dock.selectedGroup = ""
        Keys.onUpPressed: dock.selectedRow = Math.max(0, dock.selectedRow - 1)
        Keys.onDownPressed: dock.selectedRow = Math.min(dock.choices.length - 1, dock.selectedRow + 1)
        Keys.onReturnPressed: dock.perform(dock.choices[dock.selectedRow])
        Keys.onEnterPressed: dock.perform(dock.choices[dock.selectedRow])

        ColumnLayout {
            id: pickerLayout
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            Label {
                Layout.fillWidth: true
                leftPadding: 8
                text: dock.group?.name ?? ""
                elide: Text.ElideRight
                color: theme.accent
                font.family: theme.font
                font.bold: true
            }

            ListView {
                id: windowList
                Layout.fillWidth: true
                implicitHeight: Math.min(240, count * 36)
                clip: true
                model: ScriptModel { values: dock.choices.map(choice => choice.key) }
                currentIndex: dock.selectedRow
                ScrollBar.vertical: ScrollBar {}

                delegate: ItemDelegate {
                    id: choice
                    required property int index
                    required property string modelData
                    readonly property var option: dock.choices.find(item => item.key === modelData)
                    width: ListView.view.width
                    height: 36
                    text: option?.text ?? ""
                    onClicked: dock.perform(option)
                    contentItem: Label {
                        text: choice.text
                        color: theme.text
                        font.family: theme.font
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: 8
                        color: choice.hovered || choice.index === dock.selectedRow
                            ? theme.raised : "transparent"
                    }
                }
            }

            Label {
                Layout.fillWidth: true
                visible: !!apps.pinError
                text: apps.pinError
                color: theme.accent
                font.family: theme.font
                wrapMode: Text.WordWrap
            }
        }
    }
}
