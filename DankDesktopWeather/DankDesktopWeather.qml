import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins

DesktopPluginComponent {
    id: root

    minWidth: {
        switch (viewMode) {
        case "compact":
            return 80;
        case "standard":
            return 140;
        case "detailed":
            return 200;
        case "forecast":
            return 280;
        default:
            return 160;
        }
    }
    minHeight: {
        switch (viewMode) {
        case "compact":
            return 80;
        case "standard":
            return 100;
        case "detailed":
            return 200;
        case "forecast":
            return 320;
        default:
            return 140;
        }
    }

    property string viewMode: pluginData.viewMode ?? "standard"
    property real backgroundOpacity: (pluginData.backgroundOpacity ?? 80) / 100
    property string colorMode: pluginData.colorMode ?? "primary"
    property color customColor: pluginData.customColor ?? "#ffffff"
    property bool showLocation: pluginData.showLocation ?? true
    property bool showCondition: pluginData.showCondition ?? true
    property bool showFeelsLike: pluginData.showFeelsLike ?? true
    property bool showHumidity: pluginData.showHumidity ?? true
    property bool showWind: pluginData.showWind ?? true
    property bool showPressure: pluginData.showPressure ?? false
    property bool showPrecipitation: pluginData.showPrecipitation ?? true
    property bool showSunTimes: pluginData.showSunTimes ?? true
    property bool showForecast: pluginData.showForecast ?? true
    property int forecastDays: pluginData.forecastDays ?? 5
    property bool showHourlyForecast: pluginData.showHourlyForecast ?? false
    property int hourlyCount: pluginData.hourlyCount ?? 6

    readonly property color accentColor: {
        switch (colorMode) {
        case "secondary":
            return Theme.secondary;
        case "custom":
            return customColor;
        default:
            return Theme.primary;
        }
    }

    readonly property color bgColor: Theme.withAlpha(Theme.surface, backgroundOpacity)
    readonly property color tileBg: Theme.withAlpha(Theme.surfaceContainerHigh, backgroundOpacity)
    readonly property color textColor: Theme.surfaceText
    readonly property color dimColor: Theme.surfaceVariantText

    readonly property bool available: WeatherService.weather.available
    readonly property var weather: WeatherService.weather

    Ref {
        service: WeatherService
    }

    Rectangle {
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: root.bgColor
        border.width: 0

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.spacingS
            spacing: Theme.spacingS

            Loader {
                id: headerLoader
                Layout.fillWidth: true
                Layout.fillHeight: {
                    switch (root.viewMode) {
                    case "compact":
                    case "standard":
                        return true;
                    case "detailed":
                        return !root.showForecast;
                    case "forecast":
                        return false;
                    default:
                        return true;
                    }
                }
                Layout.preferredHeight: {
                    if (root.viewMode === "forecast")
                        return 50;
                    if (root.viewMode === "detailed" && root.showForecast)
                        return 140;
                    return -1;
                }
                sourceComponent: {
                    switch (root.viewMode) {
                    case "compact":
                        return compactView;
                    case "standard":
                        return standardView;
                    case "detailed":
                        return detailedView;
                    case "forecast":
                        return forecastHeaderView;
                    default:
                        return standardView;
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                Layout.fillHeight: true
                visible: root.viewMode === "forecast" || (root.viewMode === "detailed" && root.showForecast)
                active: visible
                sourceComponent: forecastSection
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: Theme.spacingS
            visible: !root.available

            DankIcon {
                name: "cloud_off"
                size: Theme.iconSize * 1.5
                color: root.dimColor
                anchors.horizontalCenter: parent.horizontalCenter
            }

            StyledText {
                text: I18n.tr("No Weather Data")
                font.pixelSize: Theme.fontSizeSmall
                color: root.dimColor
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }
    }

    Component {
        id: compactView

        Item {
            id: compactRoot
            visible: root.available

            readonly property real baseSize: Math.min(width, height)
            readonly property real iconSize: baseSize * 0.5
            readonly property real tempFontSize: baseSize * 0.18

            ColumnLayout {
                anchors.centerIn: parent
                spacing: compactRoot.baseSize * 0.04

                DankIcon {
                    name: WeatherService.getWeatherIcon(root.weather.wCode)
                    size: compactRoot.iconSize
                    color: root.accentColor
                    Layout.alignment: Qt.AlignHCenter

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 2
                        shadowBlur: 0.6
                        shadowColor: Theme.shadowMedium
                        shadowOpacity: 0.2
                    }
                }

                StyledText {
                    text: WeatherService.formatTemp(root.weather.temp, true, false)
                    font.pixelSize: compactRoot.tempFontSize
                    font.weight: Font.Light
                    color: root.textColor
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    Component {
        id: standardView

        Item {
            id: standardRoot
            visible: root.available

            readonly property real baseSize: Math.min(width, height)
            readonly property real iconSize: baseSize * 0.5
            readonly property real tempFontSize: baseSize * 0.22
            readonly property real labelFontSize: Math.max(Theme.fontSizeSmall, baseSize * 0.1)

            RowLayout {
                anchors.fill: parent
                anchors.margins: standardRoot.baseSize * 0.06
                spacing: standardRoot.baseSize * 0.08

                DankIcon {
                    name: WeatherService.getWeatherIcon(root.weather.wCode)
                    size: standardRoot.iconSize
                    color: root.accentColor
                    Layout.alignment: Qt.AlignVCenter

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 3
                        shadowBlur: 0.7
                        shadowColor: Theme.shadowMedium
                        shadowOpacity: 0.2
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 1

                    StyledText {
                        text: WeatherService.formatTemp(root.weather.temp, true, false)
                        font.pixelSize: standardRoot.tempFontSize
                        font.weight: Font.Light
                        color: root.textColor
                    }

                    StyledText {
                        visible: root.showCondition
                        text: WeatherService.getWeatherCondition(root.weather.wCode)
                        font.pixelSize: standardRoot.labelFontSize
                        color: root.dimColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }

                    StyledText {
                        visible: root.showLocation && root.weather.city
                        text: root.weather.city
                        font.pixelSize: standardRoot.labelFontSize
                        color: root.dimColor
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    Component {
        id: detailedView

        Item {
            id: detailedRoot
            visible: root.available

            readonly property real baseWidth: width
            readonly property real iconSize: Math.max(32, Math.min(width * 0.2, 56))
            readonly property real tempFontSize: Math.max(Theme.fontSizeLarge, width * 0.1)
            readonly property real labelFontSize: Math.max(Theme.fontSizeSmall, width * 0.05)
            readonly property real smallIconSize: Math.max(12, width * 0.06)

            ColumnLayout {
                anchors.fill: parent
                spacing: Theme.spacingS

                RowLayout {
                    Layout.fillWidth: true
                    spacing: Theme.spacingM

                    DankIcon {
                        name: WeatherService.getWeatherIcon(root.weather.wCode)
                        size: detailedRoot.iconSize
                        color: root.accentColor

                        layer.enabled: true
                        layer.effect: MultiEffect {
                            shadowEnabled: true
                            shadowHorizontalOffset: 0
                            shadowVerticalOffset: 3
                            shadowBlur: 0.7
                            shadowColor: Theme.shadowMedium
                            shadowOpacity: 0.2
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 0

                        StyledText {
                            text: WeatherService.formatTemp(root.weather.temp, true, false)
                            font.pixelSize: detailedRoot.tempFontSize
                            font.weight: Font.Light
                            color: root.textColor
                        }

                        StyledText {
                            visible: root.showCondition
                            text: WeatherService.getWeatherCondition(root.weather.wCode)
                            font.pixelSize: detailedRoot.labelFontSize
                            color: root.dimColor
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    ColumnLayout {
                        visible: root.showSunTimes
                        spacing: 1
                        Layout.alignment: Qt.AlignRight

                        RowLayout {
                            spacing: Theme.spacingXS
                            DankIcon {
                                name: "wb_twilight"
                                size: detailedRoot.smallIconSize
                                color: root.dimColor
                            }
                            StyledText {
                                text: root.weather.sunrise || "--"
                                font.pixelSize: detailedRoot.labelFontSize
                                color: root.dimColor
                            }
                        }

                        RowLayout {
                            spacing: Theme.spacingXS
                            DankIcon {
                                name: "bedtime"
                                size: detailedRoot.smallIconSize
                                color: root.dimColor
                            }
                            StyledText {
                                text: root.weather.sunset || "--"
                                font.pixelSize: detailedRoot.labelFontSize
                                color: root.dimColor
                            }
                        }
                    }
                }

                StyledText {
                    visible: root.showLocation && root.weather.city
                    text: root.weather.city
                    font.pixelSize: Theme.fontSizeSmall
                    color: root.dimColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: Theme.withAlpha(Theme.outline, 0.15)
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: Theme.spacingS

                    WeatherMetric {
                        visible: root.showFeelsLike
                        icon: "device_thermostat"
                        label: I18n.tr("Feels")
                        value: WeatherService.formatTemp(root.weather.feelsLike, true, true)
                        accentColor: root.accentColor
                        textColor: root.textColor
                        dimColor: root.dimColor
                    }

                    WeatherMetric {
                        visible: root.showHumidity
                        icon: "humidity_percentage"
                        label: I18n.tr("Humidity")
                        value: WeatherService.formatPercent(root.weather.humidity)
                        accentColor: root.accentColor
                        textColor: root.textColor
                        dimColor: root.dimColor
                    }

                    WeatherMetric {
                        visible: root.showWind
                        icon: "air"
                        label: I18n.tr("Wind")
                        value: root.weather.wind || "--"
                        accentColor: root.accentColor
                        textColor: root.textColor
                        dimColor: root.dimColor
                    }

                    WeatherMetric {
                        visible: root.showPrecipitation
                        icon: "rainy"
                        label: I18n.tr("Precip")
                        value: WeatherService.formatPercent(root.weather.precipitationProbability)
                        accentColor: root.accentColor
                        textColor: root.textColor
                        dimColor: root.dimColor
                    }

                    WeatherMetric {
                        visible: root.showPressure
                        icon: "speed"
                        label: I18n.tr("Pressure")
                        value: WeatherService.formatPressure(root.weather.pressure)
                        accentColor: root.accentColor
                        textColor: root.textColor
                        dimColor: root.dimColor
                    }
                }

                Item {
                    Layout.fillHeight: true
                    visible: !root.showForecast
                }
            }
        }
    }

    Component {
        id: forecastHeaderView

        Item {
            id: forecastHeaderRoot
            visible: root.available

            readonly property real baseHeight: height
            readonly property real iconSize: Math.max(28, baseHeight * 0.7)
            readonly property real tempFontSize: Math.max(Theme.fontSizeMedium, baseHeight * 0.4)
            readonly property real labelFontSize: Math.max(Theme.fontSizeSmall, baseHeight * 0.22)

            RowLayout {
                anchors.fill: parent
                spacing: Theme.spacingM

                DankIcon {
                    name: WeatherService.getWeatherIcon(root.weather.wCode)
                    size: forecastHeaderRoot.iconSize
                    color: root.accentColor

                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowHorizontalOffset: 0
                        shadowVerticalOffset: 2
                        shadowBlur: 0.6
                        shadowColor: Theme.shadowMedium
                        shadowOpacity: 0.2
                    }
                }

                ColumnLayout {
                    spacing: 0

                    StyledText {
                        text: WeatherService.formatTemp(root.weather.temp, true, false)
                        font.pixelSize: forecastHeaderRoot.tempFontSize
                        font.weight: Font.Light
                        color: root.textColor
                    }

                    StyledText {
                        visible: root.showLocation && root.weather.city
                        text: root.weather.city
                        font.pixelSize: forecastHeaderRoot.labelFontSize
                        color: root.dimColor
                    }
                }

                Item {
                    Layout.fillWidth: true
                }

                GridLayout {
                    columns: 2
                    rowSpacing: 1
                    columnSpacing: Theme.spacingS
                    visible: root.width > 300

                    WeatherMetric {
                        visible: root.showHumidity
                        icon: "humidity_percentage"
                        value: WeatherService.formatPercent(root.weather.humidity)
                        accentColor: root.accentColor
                        textColor: root.textColor
                        dimColor: root.dimColor
                        compact: true
                    }

                    WeatherMetric {
                        visible: root.showWind
                        icon: "air"
                        value: root.weather.wind || "--"
                        accentColor: root.accentColor
                        textColor: root.textColor
                        dimColor: root.dimColor
                        compact: true
                    }
                }
            }
        }
    }

    Component {
        id: forecastSection

        ColumnLayout {
            spacing: Theme.spacingXS
            visible: root.available && root.showForecast

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.withAlpha(Theme.outline, 0.15)
                visible: root.viewMode === "forecast"
            }

            DankListView {
                id: hourlyList
                Layout.fillWidth: true
                Layout.preferredHeight: root.showHourlyForecast ? 60 : 0
                visible: root.showHourlyForecast && root.weather.hourlyForecast?.length > 0
                orientation: ListView.Horizontal
                flickableDirection: Flickable.HorizontalFlick
                spacing: Theme.spacingXS
                clip: true

                model: Math.min(root.hourlyCount, root.weather.hourlyForecast?.length ?? 0)

                delegate: Rectangle {
                    required property int index
                    width: Theme.iconSizeLarge + Theme.spacingL
                    height: hourlyList.height
                    radius: Theme.cornerRadius - 2
                    color: root.tileBg

                    property var forecast: root.weather.hourlyForecast?.[index] ?? {}

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: Theme.spacingXS
                        spacing: 1

                        StyledText {
                            text: forecast.time || "--"
                            font.pixelSize: Theme.fontSizeSmall - 2
                            color: root.dimColor
                            Layout.alignment: Qt.AlignHCenter
                        }

                        DankIcon {
                            name: WeatherService.getWeatherIcon(forecast.wCode, forecast.isDay)
                            size: Theme.iconSizeSmall
                            color: root.accentColor
                            Layout.alignment: Qt.AlignHCenter
                        }

                        StyledText {
                            text: WeatherService.formatTemp(forecast.temp, false)
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: root.textColor
                            Layout.alignment: Qt.AlignHCenter
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.withAlpha(Theme.outline, 0.1)
                visible: root.showHourlyForecast && root.weather.hourlyForecast?.length > 0
            }

            DankListView {
                id: dailyList
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: Theme.spacingXS
                clip: true

                model: Math.min(root.forecastDays, root.weather.forecast?.length ?? 0)

                delegate: Rectangle {
                    required property int index
                    width: dailyList.width
                    height: Theme.fontSizeMedium * 2 + Theme.spacingS
                    radius: Theme.cornerRadius - 2
                    color: index === 0 ? Theme.withAlpha(root.accentColor, 0.1) : root.tileBg

                    property var forecast: root.weather.forecast?.[index] ?? {}

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: Theme.spacingS
                        anchors.rightMargin: Theme.spacingS
                        spacing: Theme.spacingS

                        StyledText {
                            text: forecast.day || "--"
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: index === 0 ? Font.Medium : Font.Normal
                            color: root.textColor
                            Layout.preferredWidth: Theme.fontSizeSmall * 5
                        }

                        DankIcon {
                            name: WeatherService.getWeatherIcon(forecast.wCode, true)
                            size: Theme.iconSizeSmall + 2
                            color: root.accentColor
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        RowLayout {
                            spacing: 1
                            visible: forecast.precipitationProbability > 0

                            DankIcon {
                                name: "water_drop"
                                size: Theme.iconSizeSmall - 4
                                color: Theme.primary
                            }

                            StyledText {
                                text: forecast.precipitationProbability + "%"
                                font.pixelSize: Theme.fontSizeSmall - 2
                                color: Theme.primary
                            }
                        }

                        StyledText {
                            text: WeatherService.formatTemp(forecast.tempMax, false)
                            font.pixelSize: Theme.fontSizeSmall
                            font.weight: Font.Medium
                            color: root.textColor
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: Theme.fontSizeSmall * 2.5
                        }

                        StyledText {
                            text: WeatherService.formatTemp(forecast.tempMin, false)
                            font.pixelSize: Theme.fontSizeSmall
                            color: root.dimColor
                            horizontalAlignment: Text.AlignRight
                            Layout.preferredWidth: Theme.fontSizeSmall * 2.5
                        }
                    }
                }
            }
        }
    }

    component WeatherMetric: RowLayout {
        property string icon: ""
        property string label: ""
        property string value: ""
        property color accentColor: Theme.primary
        property color textColor: Theme.surfaceText
        property color dimColor: Theme.surfaceVariantText
        property bool compact: false

        spacing: Theme.spacingXS

        DankIcon {
            name: parent.icon
            size: compact ? Theme.iconSizeSmall - 2 : Theme.iconSizeSmall
            color: parent.accentColor
        }

        ColumnLayout {
            spacing: 0
            visible: !compact

            StyledText {
                visible: parent.parent.label.length > 0
                text: parent.parent.label
                font.pixelSize: Theme.fontSizeSmall - 2
                color: parent.parent.dimColor
            }

            StyledText {
                text: parent.parent.value
                font.pixelSize: Theme.fontSizeSmall
                color: parent.parent.textColor
            }
        }

        StyledText {
            visible: compact
            text: parent.value
            font.pixelSize: Theme.fontSizeSmall
            color: parent.textColor
        }
    }
}
