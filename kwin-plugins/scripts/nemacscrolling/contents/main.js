var GAP = 8;
var COL_RATIO = 0.70;
var relayouting = false;

var EXCLUDED_CLASSES = [
    "nemac-launcher", "nemac-dock", "nemac-statusbar",
    "nemac-polkit-agent", "nemac-screenshot", "plasmashell",
    "krunner"
];

// Per-screen ordered window lists: screenColumns[screenIndex] = [client, ...]
var screenColumns = {};

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

function getColumnList(screen) {
    if (!screenColumns[screen]) {
        screenColumns[screen] = [];
    }
    return screenColumns[screen];
}

function pruneColumn(screen) {
    var col = getColumnList(screen);
    var pruned = [];
    for (var i = 0; i < col.length; i++) {
        if (isTileable(col[i])) {
            pruned.push(col[i]);
        }
    }
    screenColumns[screen] = pruned;
    return pruned;
}

function indexInColumn(screen, client) {
    var col = getColumnList(screen);
    for (var i = 0; i < col.length; i++) {
        if (col[i] === client) return i;
    }
    return -1;
}

function addToColumn(client) {
    if (!isTileable(client)) return;
    var screen = client.screen;
    var col = getColumnList(screen);

    if (indexInColumn(screen, client) >= 0) return;

    var active = workspace.activeClient;
    var insertIdx = col.length;
    if (active && active !== client) {
        var ai = indexInColumn(screen, active);
        if (ai >= 0) {
            insertIdx = ai + 1;
        }
    }
    col.splice(insertIdx, 0, client);
}

function removeFromColumns(client) {
    for (var s in screenColumns) {
        var col = screenColumns[s];
        for (var i = 0; i < col.length; i++) {
            if (col[i] === client) {
                col.splice(i, 1);
                return;
            }
        }
    }
}

function relayout(screen) {
    if (relayouting) return;
    relayouting = true;

    var desktop = workspace.currentDesktop;
    var area = workspace.clientArea(KWin.PlacementArea, screen, desktop);
    var col = pruneColumn(screen);

    if (col.length === 0) {
        relayouting = false;
        return;
    }

    var colWidth = Math.floor(area.width * COL_RATIO);
    var winHeight = area.height - 2 * GAP;
    var winWidth = colWidth - GAP;

    var focusedIdx = 0;
    var active = workspace.activeClient;
    if (active) {
        var ai = indexInColumn(screen, active);
        if (ai >= 0) focusedIdx = ai;
    }

    // scrollOffset: pixel offset so that focusedIdx column is centered
    var stripOffset = focusedIdx * colWidth;
    var centerOffset = Math.floor((area.width - winWidth) / 2);
    var scrollX = stripOffset - centerOffset;

    for (var i = 0; i < col.length; i++) {
        var x = area.x + (i * colWidth) - scrollX + Math.floor(GAP / 2);
        col[i].geometry = Qt.rect(x, area.y + GAP, winWidth, winHeight);
    }

    relayouting = false;
}

function relayoutAll() {
    var numScreens = workspace.numScreens;
    for (var s = 0; s < numScreens; s++) {
        relayout(s);
    }
}

function onActiveChanged() {
    var active = workspace.activeClient;
    if (!active || !isTileable(active)) return;
    relayout(active.screen);
}

function focusDirection(delta) {
    var active = workspace.activeClient;
    if (!active) return;
    var screen = active.screen;
    var col = pruneColumn(screen);
    var idx = indexInColumn(screen, active);
    if (idx < 0) return;

    var next = idx + delta;
    if (next < 0) next = col.length - 1;
    if (next >= col.length) next = 0;

    workspace.activeClient = col[next];
}

function moveDirection(delta) {
    var active = workspace.activeClient;
    if (!active || !isTileable(active)) return;
    var screen = active.screen;
    var col = getColumnList(screen);
    var idx = indexInColumn(screen, active);
    if (idx < 0) return;

    var target = idx + delta;
    if (target < 0 || target >= col.length) return;

    col.splice(idx, 1);
    col.splice(target, 0, active);
    relayout(screen);
}

function connectClient(client) {
    client.minimizedChanged.connect(function () {
        relayout(client.screen);
    });
    client.fullScreenChanged.connect(function () {
        relayout(client.screen);
    });
    client.screenChanged.connect(relayoutAll);
    client.desktopChanged.connect(relayoutAll);
}

registerShortcut(
    "NemacScrollFocusPrev",
    "Nemac Scrolling: Focus Previous",
    "Meta+[",
    function () { focusDirection(-1); }
);

registerShortcut(
    "NemacScrollFocusNext",
    "Nemac Scrolling: Focus Next",
    "Meta+]",
    function () { focusDirection(1); }
);

registerShortcut(
    "NemacScrollMoveLeft",
    "Nemac Scrolling: Move Window Left",
    "Meta+Shift+[",
    function () { moveDirection(-1); }
);

registerShortcut(
    "NemacScrollMoveRight",
    "Nemac Scrolling: Move Window Right",
    "Meta+Shift+]",
    function () { moveDirection(1); }
);

workspace.clientAdded.connect(function (client) {
    addToColumn(client);
    connectClient(client);
    relayout(client.screen);
});

workspace.clientRemoved.connect(function (client) {
    removeFromColumns(client);
    relayoutAll();
});

workspace.currentDesktopChanged.connect(relayoutAll);
workspace.numberScreensChanged.connect(function () {
    screenColumns = {};
    var clients = workspace.clientList();
    for (var i = 0; i < clients.length; i++) {
        addToColumn(clients[i]);
    }
    relayoutAll();
});

workspace.activeClientChanged.connect(onActiveChanged);

// Initialize with existing windows
var clients = workspace.clientList();
for (var i = 0; i < clients.length; i++) {
    addToColumn(clients[i]);
    connectClient(clients[i]);
}
relayoutAll();
