import QtQuick
import Quickshell
import qs.Common
import qs.Services

QtObject {
    id: root

    property var pluginService: null
    property string pluginId: "dankGifSearch"
    property string trigger: "gif"
    property string lastSentQuery: "\x00"
    property string pendingQuery: "\x00"

    signal itemsChanged

    property Timer searchDebounce: Timer {
        interval: 300
        repeat: false
        onTriggered: {
            if (root.pendingQuery !== root.lastSentQuery) {
                root.lastSentQuery = root.pendingQuery;
                if (!root.pendingQuery) {
                    GifSearchService.trending();
                } else {
                    GifSearchService.search(root.pendingQuery);
                }
            }
        }
    }

    property Connections gifConn: Connections {
        target: GifSearchService

        function onResultsReady() {
            if (!pluginService || !pluginId)
                return;
            if (typeof pluginService.requestLauncherUpdate === "function") {
                pluginService.requestLauncherUpdate(pluginId);
            }
        }
    }

    Component.onCompleted: {
        if (!pluginService)
            return;
        trigger = pluginService.loadPluginData("dankGifSearch", "trigger", "gif");
    }

    onTriggerChanged: {
        if (!pluginService)
            return;
        pluginService.savePluginData("dankGifSearch", "trigger", trigger);
    }

    function getItems(query) {
        const q = (query || "").trim();

        if (q !== pendingQuery) {
            pendingQuery = q;
            searchDebounce.restart();
        }

        if (GifSearchService.loading || q !== lastSentQuery) {
            return [
                {
                    name: I18n.tr("Searching..."),
                    icon: "material:hourglass_empty",
                    comment: q || I18n.tr("Trending GIFs"),
                    action: "none",
                    categories: ["GIF Search"]
                }
            ];
        }

        const results = GifSearchService.results;
        if (!results || results.length === 0) {
            return [
                {
                    name: q ? I18n.tr("No results found") : I18n.tr("Loading trending..."),
                    icon: "material:gif_box",
                    comment: I18n.tr("Try a different search"),
                    action: "none",
                    categories: ["GIF Search"]
                }
            ];
        }

        const pluginDir = pluginService?.getPluginPath?.("dankGifSearch") || "";
        const attributionSvg = pluginDir ? pluginDir + "/klippy.svg" : "";

        const items = [];
        for (let i = 0; i < results.length; i++) {
            const gif = results[i];
            const urls = {
                webp: gif.webpUrl || "",
                gif: gif.gifUrl || "",
                mp4: gif.mp4Url || ""
            };
            items.push({
                name: gif.title || "GIF",
                icon: "material:gif",
                comment: I18n.tr("Shift+Enter to paste"),
                action: "copy:" + JSON.stringify(urls),
                categories: ["GIF Search"],
                imageUrl: gif.previewUrl,
                animated: true,
                attribution: attributionSvg
            });
        }
        return items;
    }

    function parseUrls(item) {
        if (!item?.action || !item.action.startsWith("copy:"))
            return null;
        try {
            return JSON.parse(item.action.substring(5));
        } catch (e) {
            return null;
        }
    }

    function getPreferredUrl(urls) {
        if (!urls)
            return "";
        return urls.webp || urls.gif || urls.mp4 || "";
    }

    function getPasteText(item) {
        const urls = parseUrls(item);
        return getPreferredUrl(urls) || null;
    }

    function executeItem(item) {
        const urls = parseUrls(item);
        const url = getPreferredUrl(urls);
        if (!url)
            return;
        Quickshell.execDetached(["dms", "cl", "copy", url]);
        ToastService.showInfo(I18n.tr("Copied to clipboard"));
    }

    function getContextMenuActions(item) {
        if (!item)
            return [];

        const urls = parseUrls(item);
        if (!urls)
            return [];

        const actions = [];
        if (urls.webp) {
            actions.push({
                icon: "image",
                text: "WebP",
                action: () => {
                    Quickshell.execDetached(["dms", "cl", "copy", urls.webp]);
                    ToastService.showInfo(I18n.tr("Copied WebP"));
                }
            });
        }
        if (urls.gif) {
            actions.push({
                icon: "gif_box",
                text: "GIF",
                action: () => {
                    Quickshell.execDetached(["dms", "cl", "copy", urls.gif]);
                    ToastService.showInfo(I18n.tr("Copied GIF"));
                }
            });
        }
        if (urls.mp4) {
            actions.push({
                icon: "movie",
                text: "MP4",
                action: () => {
                    Quickshell.execDetached(["dms", "cl", "copy", urls.mp4]);
                    ToastService.showInfo(I18n.tr("Copied MP4"));
                }
            });
        }

        const preferredUrl = getPreferredUrl(urls);
        if (preferredUrl) {
            actions.push({
                icon: "open_in_new",
                text: I18n.tr("Open in Browser"),
                action: () => {
                    Qt.openUrlExternally(preferredUrl);
                }
            });
        }
        return actions;
    }
}
