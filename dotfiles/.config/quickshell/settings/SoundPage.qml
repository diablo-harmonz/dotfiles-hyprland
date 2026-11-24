// Sound: output and input volume (with mute), which device to use, the input level, and
// the volume of each app that is playing to the output (PipeWire through Quickshell).
import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Page {
    id: p
    title: "Sound"

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var nodes: Pipewire.nodes.values
    readonly property var sinks: nodes.filter(n => n.audio && n.isSink && !n.isStream)
    readonly property var sources: nodes.filter(n => n.audio && !n.isSink && !n.isStream
                                                 && (n.name || "").indexOf(".monitor") < 0)
    readonly property var apps: links.linkGroups.map(g => g.source).filter(n => n && n.audio && n.isStream)

    function label(n) {
        if (!n) return ""
        const pr = n.properties || {}
        return n.isStream ? (pr["application.name"] || n.description || n.name)
                          : (n.description || n.nickname || n.name)
    }
    function pct(n) { return n && n.audio ? Math.round(n.audio.volume * 100) + " %" : "" }

    // Audio properties are only live for tracked nodes
    PwObjectTracker { objects: [p.sink, p.source].concat(p.sinks, p.sources, p.apps) }
    PwNodeLinkTracker { id: links; node: p.sink }
    PwNodePeakMonitor { id: mic; node: p.source; enabled: p.source !== null }
    // A mute change (the Mute button here, or anything else) also sets the mic LED and the
    // headset jack's capture switch (bin/osd mic sync)
    Connections {
        target: p.source && p.source.audio ? p.source.audio : null
        function onMutedChanged() {
            Quickshell.execDetached(["sh", "-c", "exec \"$HOME/.local/bin/osd\" mic sync"])
        }
    }

    component VolumeRow: SRow {
        id: vr
        property var node: null
        property string glyph: ""
        icon: node && node.audio && node.audio.muted ? "" : glyph
        iconColor: node && node.audio && node.audio.muted ? Pal.urgent : Pal.muted
        Sld {
            anchors.verticalCenter: parent.verticalCenter
            width: 220 * Pal.ui
            value: vr.node && vr.node.audio ? vr.node.audio.volume : 0
            dim: vr.node && vr.node.audio ? vr.node.audio.muted : false
            onMoved: v => { if (vr.node && vr.node.audio) { vr.node.audio.volume = v; vr.node.audio.muted = false } }
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            width: 40 * Pal.ui
            horizontalAlignment: Text.AlignRight
            text: p.pct(vr.node)
            color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fsSmall
        }
        Btn {
            text: vr.node && vr.node.audio && vr.node.audio.muted ? "Unmute" : "Mute"
            onClicked: if (vr.node && vr.node.audio) vr.node.audio.muted = !vr.node.audio.muted
        }
    }

    Group {
        title: "Output"
        VolumeRow { node: p.sink; title: "Volume"; subtitle: p.label(p.sink) }
        Repeater {
            model: p.sinks
            SRow {
                required property var modelData
                readonly property bool active: p.sink !== null && modelData.id === p.sink.id
                clickable: !active
                icon: active ? "" : ""
                iconColor: Pal.primary
                title: p.label(modelData)
                onClicked: Pipewire.preferredDefaultAudioSink = modelData
                Text {
                    visible: parent.parent.active
                    text: "In use"; color: Pal.muted; font.family: Pal.font; font.pixelSize: Pal.fsSmall
                }
            }
        }
    }

    Group {
        title: "Input"
        VolumeRow { node: p.source; glyph: ""; title: "Microphone"; subtitle: p.label(p.source) }
        SRow {
            title: "Input level"
            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: 220 * Pal.ui; height: 6 * Pal.ui; radius: height / 2
                color: Qt.rgba(Pal.text.r, Pal.text.g, Pal.text.b, 0.15)
                Rectangle {
                    height: parent.height; radius: parent.radius
                    width: parent.width * Math.min(1, mic.peak)
                    color: Pal.good
                    Behavior on width { NumberAnimation { duration: 80 } }
                }
            }
            Item { width: 40 * Pal.ui + 8 * Pal.ui + 60 * Pal.ui; height: 1 }
        }
        Repeater {
            model: p.sources
            SRow {
                required property var modelData
                readonly property bool active: p.source !== null && modelData.id === p.source.id
                clickable: !active
                icon: active ? "" : ""
                iconColor: Pal.primary
                title: p.label(modelData)
                onClicked: Pipewire.preferredDefaultAudioSource = modelData
            }
        }
    }

    Group {
        title: "Apps"
        footer: "Apps playing to the output right now."
        SRow {
            visible: p.apps.length === 0
            title: "Nothing is playing"
        }
        Repeater {
            model: p.apps
            VolumeRow {
                required property var modelData
                node: modelData
                glyph: ""
                title: p.label(modelData)
                subtitle: modelData.properties["media.name"] || ""
            }
        }
    }
}
