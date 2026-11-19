import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: panel
    // Use the immutable name supplied by shell.qml. Looking up the window's
    // screen while its visibility changes may cause a binding loop on Wayland.
    property string assignedScreenName: ""
    readonly property bool isShown: ControlState.menu !== "" && ControlState.monitor === assignedScreenName
    required property real barBottom
    required property real buttonCenter
    readonly property color menuSurface: Qt.rgba(Settings.surface.r, Settings.surface.g, Settings.surface.b, 0.98)
    visible: panel.isShown
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.namespace: "edge-control-menu"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: panel.isShown ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    // Leave the strip's input region available for switching menus.
    mask: Region {
        x: 0
        y: panel.barBottom
        width: panel.width
        height: panel.height - panel.barBottom
    }
    MouseArea {
        anchors.fill: parent
        onClicked: ControlState.close()
    }
    // The material outside each quarter circle joins the vertical menu edge
    // tangentially to the horizontal underside of the bar.
    component Shoulder: Canvas {
        id: shoulder
        required property bool leftSide
        width: 24
        height: width
        required property color fill
        onFillChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            if (!leftSide) {
                ctx.translate(width, 0)
                ctx.scale(-1, 1)
            }
            ctx.beginPath()
            ctx.moveTo(0, 0)
            ctx.lineTo(width, 0)
            ctx.lineTo(width, height)
            ctx.arc(0, height, width, 0, -Math.PI / 2, true)
            ctx.closePath()
            ctx.fillStyle = fill
            ctx.fill()
        }
    }
    Item {
        x: reveal.x - leftShoulder.width
        y: reveal.y
        width: reveal.width + leftShoulder.width + rightShoulder.width
        height: Math.min(leftShoulder.height, reveal.height)
        clip: true
        Shoulder { id: leftShoulder; leftSide: true; fill: panel.menuSurface }
        Shoulder { id: rightShoulder; leftSide: false; fill: panel.menuSurface; anchors.right: parent.right }
    }
    Item {
        id: reveal
        width: Math.min(Settings.menuWidth, panel.width - 24)
        readonly property var menuHeights: ({
                audio: 610,
                bluetooth: 490,
                network: 620,
                notifications: 620,
                clock: 530,
                dashboard: 530,
                media: 550
            })
        // Extend menus downward, but always stop above the monitor's bottom edge.
        readonly property real fullHeight: Math.max(0, Math.min(panel.height - y - 12, menuHeights[ControlState.menu] || 520))
        x: Math.max(0, Math.min(panel.width - width, panel.buttonCenter - width / 2))
        y: panel.barBottom
        height: fullHeight * progress
        clip: true
        property real progress: 1
        NumberAnimation {
            id: expand
            target: reveal
            property: "progress"
            from: 0
            to: 1
            duration: Settings.animationDuration
            easing.type: Easing.OutCubic
        }
        readonly property string activeMenu: panel.isShown ? ControlState.menu : ""
        onActiveMenuChanged: if (activeMenu) expand.restart()
        Rectangle {
            width: parent.width
            height: reveal.fullHeight
            bottomLeftRadius: 16
            bottomRightRadius: 16
            color: panel.menuSurface
            MouseArea {
                anchors.fill: parent
                onClicked: {}
            }
            ColumnLayout {
                anchors {
                    fill: parent
                    margins: 16
                }
                spacing: 12
                focus: panel.isShown
                Keys.onEscapePressed: ControlState.close()
                RowLayout {
                    Layout.fillWidth: true
                    Label {
                        font.family: Settings.fontFamily
                        text: ControlState.menu === "dashboard" ? "System" : ControlState.menu.charAt(0).toUpperCase() + ControlState.menu.slice(1)
                        color: Settings.foreground
                        font.pixelSize: 19
                        font.bold: true
                        Layout.fillWidth: true
                    }
                    MenuButton {
                        text: "×"
                        hint: "Close menu (Esc)"
                        compact: true
                        onClicked: ControlState.close()
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Settings.borderColor
                }
                Loader {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    active: panel.isShown
                    source: ControlState.menu === "audio" ? "AudioMenu.qml" : ControlState.menu === "bluetooth" ? "BluetoothMenu.qml" : ControlState.menu === "network" ? "NetworkMenu.qml" : ControlState.menu === "notifications" ? "NotificationMenu.qml" : "ExtrasMenu.qml"
                }
            }
        }
    }
}
