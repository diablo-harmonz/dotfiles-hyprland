// Tokens: the design tokens (bin/tokens -> ~/.config/theme-tokens/tokens.json) for every
// Quickshell panel: corner radii, border width, font families, backdrop. Reloads when a
// theme pack changes them. Use: import "../shared"  then  Tokens.radiusLg, Tokens.fontUi...
// Values are in logical pixels / points; panels scale them with their own ui factor.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: t
    // Defaults until the file is read (same as themes/default/tokens.conf)
    property int radiusLg: 8
    property int radiusMd: 6
    property int radiusSm: 4
    property int border: 1
    property string fontUi: "Noto Sans"
    property int fontUiSize: 11
    property string fontMono: "FiraCode Nerd Font"
    property int fontMonoSize: 11
    property real dim: 0.30
    property real panelAlpha: 0.82

    FileView {
        id: file
        path: Quickshell.env("HOME") + "/.config/theme-tokens/tokens.json"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const j = JSON.parse(file.text())
                for (const k of ["radiusLg", "radiusMd", "radiusSm", "border", "fontUi", "fontUiSize",
                                 "fontMono", "fontMonoSize", "dim", "panelAlpha"])
                    if (j[k] !== undefined) t[k] = j[k]
            } catch (e) { console.warn("Tokens: cannot read tokens.json:", e) }
        }
    }
}
