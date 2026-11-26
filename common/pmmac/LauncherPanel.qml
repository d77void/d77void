import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell.Widgets

ColumnLayout {
    id: launcher
    required property var apps
    required property var theme
    signal launched()

    readonly property var results: {
        const words = search.text.trim().toLowerCase().split(/\s+/).filter(Boolean)
        return apps.entries.filter(entry => {
            if (entry.noDisplay)
                return false
            const haystack = [entry.name, entry.genericName, entry.id, ...entry.keywords].join(" ").toLowerCase()
            return words.every(word => haystack.includes(word))
        }).sort((a, b) => a.name.localeCompare(b.name))
    }

    spacing: 12

    function takeFocus(): void {
        search.forceActiveFocus()
    }

    function launch(entry): void {
        if (entry) {
            apps.launch(entry)
            launched()
        }
    }

    TextField {
        id: search
        Layout.fillWidth: true
        implicitHeight: 49
        placeholderText: Texts.tr("Search applications")
        placeholderTextColor: launcher.theme.muted
        color: launcher.theme.text
        font.family: launcher.theme.font
        font.pixelSize: 18
        focus: true

        background: Rectangle {
            color: launcher.theme.raised
            border.color: launcher.theme.outline
            radius: 17
        }

        onTextChanged: Qt.callLater(() => resultsView.currentIndex = launcher.results.length ? 0 : -1)
        onAccepted: launcher.launch(launcher.results[resultsView.currentIndex])
        Keys.onUpPressed: resultsView.decrementCurrentIndex()
        Keys.onDownPressed: resultsView.incrementCurrentIndex()
    }

    Label {
        Layout.fillWidth: true
        visible: launcher.results.length === 0
        text: Texts.tr("No matching applications")
        color: launcher.theme.muted
    }

    ListView {
        id: resultsView
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: launcher.results
        currentIndex: 0
        ScrollBar.vertical: ScrollBar {}

        delegate: ItemDelegate {
            id: row
            required property var modelData
            width: ListView.view.width
            height: 42
            text: modelData.name
            highlighted: ListView.isCurrentItem
            onClicked: launcher.launch(modelData)

            background: Rectangle {
                color: row.highlighted || row.hovered ? launcher.theme.raised : "transparent"
                radius: 12
            }

            contentItem: RowLayout {
                spacing: 9
                IconImage {
                    Layout.preferredWidth: 25
                    Layout.preferredHeight: 25
                    source: launcher.apps.icon(row.modelData)
                }
                Label {
                    Layout.fillWidth: true
                    text: row.text
                    color: launcher.theme.text
                    font.family: launcher.theme.font
                    font.pixelSize: 14
                    elide: Text.ElideRight
                }
            }
        }
    }
}
