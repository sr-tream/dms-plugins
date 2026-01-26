import QtQuick
import Quickshell
import qs.Common
import qs.Services

QtObject {
    id: root

    property var pluginService: null
    property string pluginId: "dankStickerSearch"
    property string trigger: ":s"
    property string lastSentQuery: "\x00"
    property string lastSentCategory: ""
    property string pendingQuery: "\x00"
    property string pendingCategory: ""
    property string currentCategory: ""

    signal itemsChanged
    signal categoriesChanged

    function getCategorySearchTerm(catId) {
        if (!catId)
            return "";
        const cats = StickerSearchService.categories;
        for (let i = 0; i < cats.length; i++) {
            if (cats[i].id === catId)
                return cats[i].searchTerm || "";
        }
        return "";
    }

    property Timer searchDebounce: Timer {
        interval: 300
        repeat: false
        onTriggered: {
            if (root.pendingQuery === root.lastSentQuery && root.pendingCategory === root.lastSentCategory)
                return;
            root.lastSentQuery = root.pendingQuery;
            root.lastSentCategory = root.pendingCategory;
            const catSearch = root.getCategorySearchTerm(root.pendingCategory);
            if (!root.pendingQuery && !catSearch) {
                StickerSearchService.trending("");
            } else {
                StickerSearchService.search(root.pendingQuery, catSearch);
            }
        }
    }

    property Connections stickerConn: Connections {
        target: StickerSearchService

        function onResultsReady() {
            if (!pluginService || !pluginId)
                return;
            if (typeof pluginService.requestLauncherUpdate === "function")
                pluginService.requestLauncherUpdate(pluginId);
        }

        function onCategoriesReady() {
            root.categoriesChanged();
        }
    }

    Component.onCompleted: {
        if (!pluginService)
            return;
        trigger = pluginService.loadPluginData("dankStickerSearch", "trigger", ":s");
        StickerSearchService.fetchCategories();
    }

    onTriggerChanged: {
        if (!pluginService)
            return;
        pluginService.savePluginData("dankStickerSearch", "trigger", trigger);
    }

    function getCategories() {
        if (StickerSearchService.categories.length === 0 && !StickerSearchService.loadingCategories)
            StickerSearchService.fetchCategories();

        const cats = StickerSearchService.categories;
        const result = [
            {
                id: "",
                name: I18n.tr("All"),
                searchTerm: ""
            }
        ];
        for (let i = 0; i < cats.length; i++)
            result.push(cats[i]);
        return result;
    }

    function setCategory(categoryId) {
        if (currentCategory === categoryId)
            return;
        currentCategory = categoryId;
    }

    function buildExpectedQuery(q, catId) {
        const catSearch = getCategorySearchTerm(catId);
        if (catSearch && !q)
            return catSearch;
        if (catSearch && q)
            return catSearch + " " + q;
        return q;
    }

    function getItems(query) {
        const q = (query || "").trim();
        const cat = currentCategory;
        const needsSearch = q !== pendingQuery || cat !== pendingCategory;

        if (needsSearch) {
            pendingQuery = q;
            pendingCategory = cat;
            searchDebounce.restart();
        }

        const expectedQuery = buildExpectedQuery(q, cat);
        if (StickerSearchService.loading || StickerSearchService.resultsForQuery !== expectedQuery) {
            return [
                {
                    name: I18n.tr("Searching..."),
                    icon: "material:hourglass_empty",
                    comment: q || I18n.tr("Trending Stickers"),
                    action: "none",
                    categories: ["Sticker Search"]
                }
            ];
        }

        const results = StickerSearchService.results;
        if (!results || results.length === 0) {
            return [
                {
                    name: q ? I18n.tr("No results found") : I18n.tr("Loading trending..."),
                    icon: "material:sentiment_satisfied",
                    comment: I18n.tr("Try a different search"),
                    action: "none",
                    categories: ["Sticker Search"]
                }
            ];
        }

        const pluginDir = pluginService?.getPluginPath?.("dankStickerSearch") || "";
        const attributionSvg = pluginDir ? pluginDir + "/klippy.svg" : "";

        const items = [];
        for (let i = 0; i < results.length; i++) {
            const sticker = results[i];
            const urls = {
                webp: sticker.webpUrl || "",
                gif: sticker.gifUrl || "",
                mp4: sticker.mp4Url || ""
            };
            items.push({
                name: sticker.title || "Sticker",
                icon: "material:sentiment_satisfied",
                comment: I18n.tr("Shift+Enter to paste"),
                action: "copy:" + JSON.stringify(urls),
                categories: ["Sticker Search"],
                imageUrl: sticker.previewUrl,
                animated: false,
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
