import QtQuick
import qs.Common
import qs.Widgets

Row {
    id: root

    signal refresh

    spacing: Theme.spacingS

    DankButton {
        text: I18n.tr("Refresh Devices", "KDE Connect refresh button")
        iconName: "refresh"
        width: parent.width
        onClicked: root.refresh()
    }
}
