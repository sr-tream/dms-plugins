import QtQuick
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./components"

PluginComponent {
    id: root

    property string selectedDeviceId: pluginData.selectedDeviceId || ""
    property bool showShareDialog: false
    property string shareDeviceId: ""

    readonly property var selectedDevice: selectedDeviceId ? KDEConnectService.getDevice(selectedDeviceId) : null
    readonly property bool hasDevice: selectedDevice !== null

    ccWidgetIcon: {
        if (!KDEConnectService.available)
            return "phonelink_off";
        if (hasDevice && selectedDevice.isReachable)
            return "phonelink";
        return "phonelink_off";
    }
    ccWidgetPrimaryText: "KDE Connect"
    ccWidgetSecondaryText: {
        if (!KDEConnectService.available)
            return I18n.tr("Unavailable", "KDE Connect unavailable status");
        if (!hasDevice)
            return I18n.tr("No devices", "KDE Connect no devices status");
        if (selectedDevice.isReachable) {
            let text = selectedDevice.name;
            if (selectedDevice.batteryCharge >= 0)
                text += " • " + selectedDevice.batteryCharge + "%";
            return text;
        }
        return selectedDevice.name + " (" + I18n.tr("Offline", "KDE Connect offline status") + ")";
    }
    ccWidgetIsActive: hasDevice && selectedDevice?.isReachable

    ccDetailContent: Component {
        KDEConnectDetailContent {
            listHeight: 200
        }
    }

    onPluginServiceChanged: {
        if (!pluginService)
            return;
        const savedId = pluginService.loadPluginData("dankKDEConnect", "selectedDeviceId", "");
        if (savedId)
            selectedDeviceId = savedId;
    }

    Connections {
        target: KDEConnectService
        function onDevicesListChanged() {
            if (!selectedDeviceId && KDEConnectService.deviceIds.length > 0) {
                selectDevice(KDEConnectService.deviceIds[0]);
            }
        }

        function onPairingRequestReceived(deviceId, verificationKey) {
            const device = KDEConnectService.getDevice(deviceId);
            ToastService.showInfo(I18n.tr("Pairing request from", "KDE Connect pairing request notification") + " " + (device?.name || deviceId), I18n.tr("Verification", "KDE Connect pairing verification key label") + ": " + verificationKey);
        }

        function onShareReceived(deviceId, url) {
            const device = KDEConnectService.getDevice(deviceId);
            const filename = url.split("/").pop() || url;
            const filePath = url.startsWith("file://") ? url.substring(7) : url;

            Quickshell.execDetached(["dms", "notify", "--app", "KDE Connect", "--icon", "smartphone", "--file", filePath, I18n.tr("File received from", "KDE Connect file share notification") + " " + (device?.name || deviceId), filename]);
        }
    }

    function selectDevice(deviceId) {
        selectedDeviceId = deviceId;
        if (pluginService) {
            pluginService.savePluginData("dankKDEConnect", "selectedDeviceId", deviceId);
        }
    }

    function handleAction(deviceId, action) {
        const device = KDEConnectService.getDevice(deviceId);
        const deviceName = device?.name || I18n.tr("device", "Generic device name fallback");
        switch (action) {
        case "ring":
            KDEConnectService.ringDevice(deviceId, response => {
                if (response.error) {
                    ToastService.showError(I18n.tr("Failed to ring device", "KDE Connect error"), response.error);
                    return;
                }
                ToastService.showInfo(I18n.tr("Ringing", "KDE Connect ring action") + " " + deviceName + "...");
            });
            break;
        case "ping":
            KDEConnectService.sendPing(deviceId, "", response => {
                if (response.error) {
                    ToastService.showError(I18n.tr("Failed to send ping", "KDE Connect error"), response.error);
                    return;
                }
                ToastService.showInfo(I18n.tr("Ping sent to", "KDE Connect ping action") + " " + deviceName);
            });
            break;
        case "clipboard":
            KDEConnectService.sendClipboard(deviceId, response => {
                if (response.error) {
                    ToastService.showError(I18n.tr("Failed to send clipboard", "KDE Connect error"), response.error);
                    return;
                }
                ToastService.showInfo(I18n.tr("Clipboard sent", "KDE Connect clipboard action"));
            });
            break;
        case "share":
            shareDeviceId = deviceId;
            showShareDialog = true;
            break;
        case "sms":
            closePopout();
            KDEConnectService.launchSmsApp(deviceId, response => {
                if (response.error) {
                    ToastService.showError(I18n.tr("Failed to launch SMS app", "KDE Connect error"), response.error);
                    return;
                }
                ToastService.showInfo(I18n.tr("Opening SMS app", "KDE Connect SMS action") + "...");
            });
            break;
        case "browse":
            closePopout();
            KDEConnectService.startBrowsing(deviceId, response => {
                if (response.error) {
                    ToastService.showError(I18n.tr("Failed to browse device", "KDE Connect error"), response.error);
                    return;
                }
                ToastService.showInfo(I18n.tr("Opening file browser", "KDE Connect browse action") + "...");
            });
            break;
        case "pair":
            KDEConnectService.requestPairing(deviceId, response => {
                if (response.error) {
                    ToastService.showError(I18n.tr("Pairing failed", "KDE Connect error"), response.error);
                    return;
                }
                ToastService.showInfo(I18n.tr("Pairing request sent", "KDE Connect pairing action"));
            });
            break;
        case "acceptPair":
            KDEConnectService.acceptPairing(deviceId, response => {
                if (response.error) {
                    ToastService.showError(I18n.tr("Failed to accept pairing", "KDE Connect error"), response.error);
                    return;
                }
                ToastService.showInfo(I18n.tr("Device paired", "KDE Connect pairing action"));
            });
            break;
        case "rejectPair":
            KDEConnectService.cancelPairing(deviceId, response => {
                if (response.error)
                    ToastService.showError(I18n.tr("Failed to reject pairing", "KDE Connect error"), response.error);
            });
            break;
        case "unpair":
            KDEConnectService.unpair(deviceId, response => {
                if (response.error) {
                    ToastService.showError(I18n.tr("Unpair failed", "KDE Connect error"), response.error);
                    return;
                }
                ToastService.showInfo(I18n.tr("Device unpaired", "KDE Connect unpair action"));
            });
            break;
        }
    }

    horizontalBarPill: Component {
        Row {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.hasDevice && root.selectedDevice.isReachable ? "phonelink" : "phonelink_off"
                size: root.iconSize
                color: root.hasDevice && root.selectedDevice.isReachable ? Theme.primary : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: root.hasDevice && root.selectedDevice.batteryCharge >= 0
                text: root.selectedDevice?.batteryCharge + "%"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: root.selectedDevice?.batteryCharging ? Theme.success : Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }

            StyledText {
                visible: !KDEConnectService.available
                text: "N/A"
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.surfaceVariantText
                anchors.verticalCenter: parent.verticalCenter
            }
        }
    }

    verticalBarPill: Component {
        Column {
            spacing: Theme.spacingXS

            DankIcon {
                name: root.hasDevice && root.selectedDevice.isReachable ? "phonelink" : "phonelink_off"
                size: root.iconSize
                color: root.hasDevice && root.selectedDevice.isReachable ? Theme.primary : Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                visible: root.hasDevice && root.selectedDevice.batteryCharge >= 0
                text: root.selectedDevice?.batteryCharge + "%"
                font.pixelSize: Theme.fontSizeSmall
                font.weight: Font.Medium
                color: root.selectedDevice?.batteryCharging ? Theme.success : Theme.surfaceVariantText
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout

            headerText: "KDE Connect"
            detailsText: KDEConnectService.connectedCount + " connected • " + KDEConnectService.pairedCount + " paired"
            showCloseButton: true

            Column {
                width: parent.width
                spacing: Theme.spacingM

                UnavailableMessage {
                    visible: !KDEConnectService.available
                    width: parent.width
                }

                ActionButtons {
                    visible: KDEConnectService.available
                    width: parent.width
                    onRefresh: KDEConnectService.refreshDevices()
                }

                EmptyState {
                    visible: KDEConnectService.available && KDEConnectService.deviceIds.length === 0
                    width: parent.width
                }

                Repeater {
                    model: KDEConnectService.deviceIds

                    DeviceCard {
                        required property string modelData
                        width: parent.width
                        deviceId: modelData
                        device: KDEConnectService.getDevice(modelData)
                        isSelected: root.selectedDeviceId === modelData
                        onClicked: root.selectDevice(modelData)
                        onAction: action => root.handleAction(modelData, action)
                    }
                }

                ShareDialog {
                    visible: root.showShareDialog
                    width: parent.width
                    deviceId: root.shareDeviceId
                    onClose: root.showShareDialog = false
                    onShare: (content, isUrl) => {
                        if (isUrl) {
                            KDEConnectService.shareUrl(root.shareDeviceId, content, response => {
                                if (response.error) {
                                    ToastService.showError(I18n.tr("Failed to share", "KDE Connect error"), response.error);
                                    return;
                                }
                                ToastService.showInfo(I18n.tr("Shared", "KDE Connect share success"));
                            });
                        } else {
                            KDEConnectService.shareText(root.shareDeviceId, content, response => {
                                if (response.error) {
                                    ToastService.showError(I18n.tr("Failed to share", "KDE Connect error"), response.error);
                                    return;
                                }
                                ToastService.showInfo(I18n.tr("Shared", "KDE Connect share success"));
                            });
                        }
                        root.showShareDialog = false;
                    }
                }
            }
        }
    }
}
