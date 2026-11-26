import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell

ColumnLayout {
    id: panel

    required property var wallpaper
    required property var theme
    required property string wallpaperDirectory
    readonly property string home: Quickshell.env("HOME")
    spacing: 9

    function url(path): url {
        return "file://" + path.split("/").map(encodeURIComponent).join("/")
    }

    function takeFocus(): void {
        grid.forceActiveFocus()
    }

    FolderListModel {
        id: files
        folder: panel.url(panel.wallpaperDirectory || panel.home)
        nameFilters: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.bmp", "*.gif", "*.tiff"]
        showDirsFirst: true
        showOnlyReadable: true
        onFolderChanged: grid.currentIndex = 0
    }

    RowLayout {
        Layout.fillWidth: true
        Label { text: Texts.tr("Wallpaper"); color: panel.theme.text; font.pixelSize: 17; font.bold: true }
        Item { Layout.fillWidth: true }
        Button {
            text: Texts.tr("Home")
            onClicked: files.folder = panel.url(panel.home)
        }
        Button {
            text: Texts.tr("Up")
            enabled: files.parentFolder.toString() !== ""
            onClicked: files.folder = files.parentFolder
        }
    }

    Label {
        Layout.fillWidth: true
        text: decodeURIComponent(files.folder.toString().replace(/^file:\/\//, ""))
        color: panel.theme.muted
        elide: Text.ElideMiddle
    }

    GridView {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: files
        cellWidth: width / Math.max(2, Math.floor(width / 155))
        cellHeight: 112
        keyNavigationEnabled: true
        ScrollBar.vertical: ScrollBar {}
        Keys.onReturnPressed: currentItem?.activate()

        delegate: ItemDelegate {
            id: tile
            required property string fileName
            required property string filePath
            required property bool fileIsDir
            width: grid.cellWidth - 6
            height: grid.cellHeight - 6
            highlighted: GridView.isCurrentItem || panel.wallpaper.state.path === filePath
            Accessible.name: fileName

            function activate(): void {
                if (fileIsDir)
                    files.folder = panel.url(filePath)
                else
                    panel.wallpaper.run("apply", filePath)
            }

            onClicked: activate()

            background: Rectangle {
                radius: 8
                color: panel.theme.raised
                border.color: tile.highlighted || tile.hovered ? panel.theme.accent : panel.theme.outline
            }

            contentItem: ColumnLayout {
                spacing: 4
                Image {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: !tile.fileIsDir
                    source: visible ? panel.url(tile.filePath) : ""
                    asynchronous: true
                    sourceSize.width: 300
                    sourceSize.height: 155
                    fillMode: Image.PreserveAspectCrop
                }
                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: tile.fileIsDir
                    verticalAlignment: Text.AlignVCenter
                    horizontalAlignment: Text.AlignHCenter
                    text: tile.fileName + (tile.fileIsDir ? "/" : "")
                    elide: Text.ElideMiddle
                    color: panel.theme.text
                }
            }
        }

        Label {
            anchors.centerIn: parent
            text: Texts.tr("No images in this folder")
            visible: files.status === FolderListModel.Ready && files.count === 0
            color: panel.theme.muted
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Label { text: Texts.tr("Color intensity"); color: panel.theme.text }
        Slider {
            Layout.fillWidth: true
            value: panel.wallpaper.state.mix ?? 0.5
            stepSize: 0.05
            onPressedChanged: { if (!pressed) panel.wallpaper.run("mix", value) }
        }
    }
    Label {
        Layout.fillWidth: true
        visible: panel.wallpaper.busy || !!panel.wallpaper.error
        text: panel.wallpaper.busy ? Texts.tr("Updating wallpaper settings…") : panel.wallpaper.error
        color: panel.theme.accent
        elide: Text.ElideRight
    }
}
