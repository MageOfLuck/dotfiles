import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import Quickshell.Services.Mpris
import Quickshell.Services.Pipewire

PanelWindow {
    id: panel
    readonly property bool barHovered: barHover.hovered
    property string displayedMenu: ""
    property bool retracting: false
    property bool revealed: false
    readonly property bool menuOpen: ControlState.menu !== "" && ControlState.monitor === screen.name
    readonly property bool showBar: ControlState.reserveSpace || revealed || menuOpen || retracting
    readonly property real barBottom: bar.y + bar.height
    readonly property real buttonCenter: {
        const buttons = { dashboard: dashboardButton, media: mediaButton, bluetooth: bluetoothButton, audio: audioButton, network: networkButton, notifications: notificationsButton, clock: clockButton }
        const button = buttons[displayedMenu]
        return button ? button.parent.x + button.x + button.width / 2 : width / 2
    }
    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: Settings.barHeight
    mask: Region {
        width: panel.width
        height: Math.max(Settings.edgeHeight, bar.y + bar.height)
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "edge-control"
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
    // Geometry never changes when a menu opens. Only the input mask follows
    // the animated strip; the taller activation zone remains reachable.
    Connections {
        target: ControlState
        function onReserveSpaceChanged() {
            if (!ControlState.reserveSpace)
                panel.revealed = false;
        }
    }
    Timer {
        interval: Settings.revealDelay
        running: edgeHover.hovered && !panel.revealed && !panel.menuOpen
        onTriggered: panel.revealed = true
    }
    Timer {
        interval: Settings.hideDelay
        running: panel.revealed && !panel.menuOpen && !barHover.hovered && !edgeHover.hovered
        onTriggered: {
            if (panel.menuOpen)
                ControlState.close();
            panel.revealed = false;
        }
    }
    Item {
        width: parent.width
        height: Settings.edgeHeight
        HoverHandler {
            id: edgeHover
        }
    }
    Rectangle {
        id: bar
        width: parent.width
        height: Settings.barHeight
        y: panel.showBar ? 0 : -height
        Behavior on y {
            NumberAnimation {
                duration: Settings.animationDuration
                easing.type: Easing.OutCubic
            }
        }
        color: Qt.rgba(Settings.surface.r, Settings.surface.g, Settings.surface.b, 0.98)
        HoverHandler {
            id: barHover
        }
        RowLayout {
            id: leftGroup
            anchors {
                left: parent.left
                leftMargin: 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 6
            MenuButton {
                id: dashboardButton
                iconButton: true
                text: String.fromCodePoint(0xF0493) // nf-md-cog (monochrome System icon)
                hint: "System"
                selected: panel.menuOpen && ControlState.menu === "dashboard"
                hoverMenu: "dashboard"
                menuScreen: panel.screen.name
                onClicked: ControlState.open(hoverMenu, menuScreen)
            }
            RowLayout {
                spacing: 4
                Repeater {
                    model: Hyprland.workspaces
                    delegate: MenuButton {
                        required property var modelData
                        visible: modelData.id > 0 && !!modelData.monitor && modelData.monitor.name === panel.screen.name
                        workspaceButton: true
                        text: modelData.name
                        selected: modelData.active
                        // Activate through Quickshell's Hyprland IPC rather than
                        // launching a separate shell and hyprctl process.
                        onClicked: modelData.activate()
                        hint: "Switch to workspace " + modelData.name
                    }
                }
            }
            MenuButton {
                id: mediaButton
                iconButton: true
                selected: panel.menuOpen && ControlState.menu === "media"
                text: String.fromCodePoint(0xF0387) // nf-md-music_note
                hint: Mpris.players.values.length ? (Mpris.players.values[0].trackTitle || "Media") : "Media"
                hoverMenu: "media"
                menuScreen: panel.screen.name
                onClicked: ControlState.open(hoverMenu, menuScreen)
            }
        }
        Text {
            font.family: Settings.fontFamily
            anchors.centerIn: parent
            width: Math.max(0, parent.width - 2 * Math.max(leftGroup.width + 24, rightGroup.width + 24))
            text: Hyprland.activeToplevel ? Hyprland.activeToplevel.title : "Desktop"
            color: Settings.foreground
            font.pixelSize: 13
            font.bold: true
            elide: Text.ElideRight
            horizontalAlignment: Text.AlignHCenter
        }
        RowLayout {
            id: rightGroup
            anchors {
                right: parent.right
                rightMargin: 10
                verticalCenter: parent.verticalCenter
            }
            spacing: 6
            MenuButton {
                id: bluetoothButton
                iconButton: true
                text: String.fromCodePoint(0xF00AF) // nf-md-bluetooth
                hint: "Bluetooth"
                selected: panel.menuOpen && ControlState.menu === "bluetooth"
                hoverMenu: "bluetooth"
                menuScreen: panel.screen.name
                onClicked: ControlState.open(hoverMenu, menuScreen)
            }
            MenuButton {
                id: audioButton
                iconButton: true
                audioAccent: true
                selected: panel.menuOpen && ControlState.menu === "audio"
                // Keep the speaker glyph separate from the normal-font volume
                // percentage, so the number is not rendered in a Nerd Font.
                text: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && Pipewire.defaultAudioSink.audio.muted
                      ? String.fromCodePoint(0xF0581) // nf-md-volume_off
                      : String.fromCodePoint(0xF057E) // nf-md-volume_high
                valueText: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio && !Pipewire.defaultAudioSink.audio.muted
                           ? Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%" : ""
                hint: Pipewire.defaultAudioSink && Pipewire.defaultAudioSink.audio
                      ? (Pipewire.defaultAudioSink.audio.muted ? "Audio muted" : "Audio · " + Math.round(Pipewire.defaultAudioSink.audio.volume * 100) + "%")
                      : "Audio"
                hoverMenu: "audio"
                menuScreen: panel.screen.name
                onClicked: ControlState.open(hoverMenu, menuScreen)
            }
            MenuButton {
                id: networkButton
                iconButton: true
                text: String.fromCodePoint(0xF05A9) // nf-md-wifi
                hint: "Network"
                selected: panel.menuOpen && ControlState.menu === "network"
                hoverMenu: "network"
                menuScreen: panel.screen.name
                onClicked: ControlState.open(hoverMenu, menuScreen)
            }
            Rectangle {
                width: 1
                height: 20
                color: Settings.muted
                opacity: 0.5
            }
            MenuButton {
                id: notificationsButton
                iconButton: true
                text: ControlState.dnd ? String.fromCodePoint(0xF009B) : String.fromCodePoint(0xF009C) // nf-md-bell_off / nf-md-bell_outline
                hint: ControlState.dnd ? "Notifications · Do Not Disturb" : "Notifications"
                selected: panel.menuOpen && ControlState.menu === "notifications"
                hoverMenu: "notifications"
                menuScreen: panel.screen.name
                onClicked: ControlState.open(hoverMenu, menuScreen)
            }
            MenuButton {
                id: clockButton
                text: Qt.formatDateTime(clock.date, "dddd h:mm AP")
                selected: panel.menuOpen && ControlState.menu === "clock"
                hoverMenu: "clock"
                menuScreen: panel.screen.name
                onClicked: ControlState.open(hoverMenu, menuScreen)
            }
        }
        SystemClock {
            id: clock
            precision: SystemClock.Minutes
        }
    }
}
