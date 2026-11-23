import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: artwork
    required property var notification
    function resolve(value) {
        if (!value) return "";
        if (value.startsWith("/")) return "file://" + value;
        if (/^[a-z][a-z0-9+.-]*:/i.test(value)) return value;
        return Quickshell.iconPath(value, true);
    }

    visible: picture.status === Image.Ready || icon.status === Image.Ready
    Layout.preferredWidth: 36
    Layout.preferredHeight: 36
    Image {
        id: picture
        anchors.fill: parent
        source: artwork.resolve(artwork.notification?.image || "")
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }
    Image {
        id: icon
        anchors.fill: parent
        source: picture.status === Image.Null || picture.status === Image.Error
              ? artwork.resolve(artwork.notification?.appIcon || "") : ""
        fillMode: Image.PreserveAspectFit
        asynchronous: true
    }
}
