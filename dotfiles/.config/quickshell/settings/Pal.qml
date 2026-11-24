// Pal: the palette and sizes of the Settings panel. Colors come from Matugen through
// ~/.config/rofi/colors.rasi (rofi writes #rrggbbaa, Qt wants #aarrggbb), reloaded when the
// wallpaper or bin/colors changes them.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: pal

    // Pages ask shell.qml to close the panel (e.g. after starting another app), so it can
    // play the close animation first
    signal closeRequested()
    // Pages ask shell.qml to switch to another section (e.g. the General page's rows)
    signal navigate(string key)
    // True while the panel is on screen (set by shell.qml); pages poll and scan only then
    property bool open: false

    // Defaults until the file is read
    property color bg: "#e00f131c"
    property color surface: "#ff262a33"
    property color primary: "#ffadc7ff"
    property color primaryFg: "#ff002e68"
    property color text: "#ffdfe2ef"
    property color muted: "#ffc3c6d3"
    property color urgent: "#ffffb4ab"

    // Derived
    readonly property color window: Qt.rgba(bg.r, bg.g, bg.b, 0.96)
    readonly property color sidebar: Qt.rgba(surface.r, surface.g, surface.b, 0.35)
    readonly property color card: Qt.rgba(surface.r, surface.g, surface.b, 0.75)
    readonly property color line: Qt.rgba(text.r, text.g, text.b, 0.08)
    readonly property color hover: Qt.rgba(text.r, text.g, text.b, 0.06)
    readonly property color good: "#30d158"

    // Type and size (ui = scale of the focused screen, set by shell.qml)
    property real ui: 1
    readonly property string font: "Noto Sans"
    readonly property string icons: "FiraCode Nerd Font"
    readonly property real fs: 13 * ui           // body text
    readonly property real fsSmall: 11 * ui
    readonly property real fsTitle: 20 * ui
    readonly property real rowH: 42 * ui
    readonly property real radius: 10 * ui
    readonly property real pad: 14 * ui

    function rofiColor(s) {   // "#rrggbbaa" -> "#aarrggbb"
        return s.length === 9 ? "#" + s.substr(7, 2) + s.substr(1, 6) : s
    }

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/rofi/colors.rasi"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            const map = {}
            const re = /^\s*([a-z-]+):\s*(#[0-9a-fA-F]{6,8});/gm   // no matchAll in Qt's JS
            const src = file.text()
            let m
            while ((m = re.exec(src)) !== null) map[m[1]] = pal.rofiColor(m[2])
            if (map["bg"]) pal.bg = map["bg"]
            if (map["surface"]) pal.surface = map["surface"]
            if (map["primary"]) pal.primary = map["primary"]
            if (map["on-primary"]) pal.primaryFg = map["on-primary"]
            if (map["text"]) pal.text = map["text"]
            if (map["text-muted"]) pal.muted = map["text-muted"]
            if (map["urgent"]) pal.urgent = map["urgent"]
        }
    }
}
