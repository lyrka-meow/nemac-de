var GAP = 8;
var retiling = false;

var EXCLUDED_CLASSES = [
    "nemac-launcher", "nemac-dock", "nemac-statusbar",
    "nemac-polkit-agent", "nemac-screenshot", "plasmashell",
    "krunner"
];

function isTileable(client) {
    if (!client || !client.normalWindow) return false;
    if (client.specialWindow) return false;
    if (client.dialog) return false;
    if (client.splash) return false;
    if (client.utility) return false;
    if (client.minimized) return false;
    if (client.fullScreen) return false;
    if (client.skipTaskbar && client.skipPager) return false;

    var cls = String(client.resourceClass).toLowerCase();
    for (var i = 0; i < EXCLUDED_CLASSES.length; i++) {
        if (cls === EXCLUDED_CLASSES[i]) return false;
    }
    return true;
}

function getTileableWindows(screen, desktop) {
    var all = workspace.clientList();
    var result = [];
    for (var i = 0; i < all.length; i++) {
        var c = all[i];
        if (!isTileable(c)) continue;
        if (c.screen !== screen) continue;
        if (c.desktop !== desktop && c.desktop !== -1) continue;
        result.push(c);
    }
    return result;
}

function retile() {
    if (retiling) return;
    retiling = true;

    var numScreens = workspace.numScreens;
    var desktop = workspace.currentDesktop;

    for (var s = 0; s < numScreens; s++) {
        var area = workspace.clientArea(KWin.PlacementArea, s, desktop);
        var windows = getTileableWindows(s, desktop);

        if (windows.length === 0) {
            continue;
        }

        if (windows.length === 1) {
            windows[0].geometry = Qt.rect(
                area.x + GAP, area.y + GAP,
                area.width - 2 * GAP, area.height - 2 * GAP
            );
            continue;
        }

        var masterW = Math.floor((area.width - 3 * GAP) / 2);
        windows[0].geometry = Qt.rect(
            area.x + GAP,
            area.y + GAP,
            masterW,
            area.height - 2 * GAP
        );

        var stackCount = windows.length - 1;
        var stackX = area.x + GAP + masterW + GAP;
        var stackW = area.width - masterW - 3 * GAP;
        var totalGaps = GAP * (stackCount + 1);
        var stackH = Math.floor((area.height - totalGaps) / stackCount);

        for (var i = 1; i < windows.length; i++) {
            var idx = i - 1;
            windows[i].geometry = Qt.rect(
                stackX,
                area.y + GAP + idx * (stackH + GAP),
                stackW,
                stackH
            );
        }
    }

    retiling = false;
}

function swapWithMaster() {
    var active = workspace.activeClient;
    if (!active || !isTileable(active)) return;

    var windows = getTileableWindows(active.screen, workspace.currentDesktop);
    if (windows.length < 2) return;

    if (windows[0] === active) return;

    var idx = -1;
    for (var i = 1; i < windows.length; i++) {
        if (windows[i] === active) { idx = i; break; }
    }
    if (idx < 0) return;

    var masterGeo = windows[0].geometry;
    var activeGeo = active.geometry;
    windows[0].geometry = activeGeo;
    active.geometry = masterGeo;
}

function connectClient(client) {
    client.geometryChanged.connect(function () {
        if (!retiling && isTileable(client)) {
            retile();
        }
    });
    client.minimizedChanged.connect(retile);
    client.fullScreenChanged.connect(retile);
    client.screenChanged.connect(retile);
    client.desktopChanged.connect(retile);
}

registerShortcut(
    "NemacTilingSwapMaster",
    "Nemac Tiling: Swap with Master",
    "Meta+Return",
    swapWithMaster
);

workspace.clientAdded.connect(function (client) {
    connectClient(client);
    retile();
});

workspace.clientRemoved.connect(retile);
workspace.currentDesktopChanged.connect(retile);
workspace.numberScreensChanged.connect(retile);

var clients = workspace.clientList();
for (var i = 0; i < clients.length; i++) {
    connectClient(clients[i]);
}
retile();
