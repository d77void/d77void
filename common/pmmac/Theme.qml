import QtQuick

QtObject {
    property bool blur: true
    property real opacity: 0.73
    property real mix: 0.5
    property var palette: null

    readonly property real barOpacity: opacity * (blur ? 0.64 : 0.94)
    readonly property color raised: "#27e2eaff"
    readonly property color outline: "#42e5edff"
    readonly property color text: "#f7f8ff"
    readonly property color muted: "#d0d6e7"
    readonly property color accent: tinted("#9fe2dd", "accent", 1)
    readonly property string font: "Inter"

    function glassTop(alpha: real): color {
        return tinted("#48586d", "surface", Math.min(1, alpha + 0.08))
    }

    function glassBase(alpha: real): color {
        return tinted("#1b283c", "surface", alpha)
    }

    function glassBottom(alpha: real): color {
        return tinted("#101825", "surface", Math.min(1, alpha + 0.07))
    }

    function tinted(base: color, role: string, alpha: real): color {
        const color = palette?.[role] ? Qt.color(palette[role]) : base
        return Qt.rgba(base.r + (color.r - base.r) * mix,
                       base.g + (color.g - base.g) * mix,
                       base.b + (color.b - base.b) * mix, alpha)
    }
}
