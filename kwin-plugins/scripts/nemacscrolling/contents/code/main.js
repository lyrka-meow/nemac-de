// ── KWin 5 / 6 compatibility ──────────────────────────────────────
var kwin6 = (typeof workspace.windowList === "function");

function allWindows()    { return kwin6 ? workspace.windowList() : workspace.clientList(); }
function activeWindow()  { return kwin6 ? workspace.activeWindow  : workspace.activeClient; }
function setActive(w)    { if (kwin6) workspace.activeWindow = w; else workspace.activeClient = w; }
function setGeo(w, r)    { if (kwin6) w.frameGeometry = r; else w.geometry = r; }
function screenOf(w)     { return kwin6 ? w.output : w.screen; }

function screenCount() {
    if (kwin6 && workspace.screens) return workspace.screens.length;
    if (workspace.numScreens) return workspace.numScreens;
    return 1;
}
function screenAt(i) {
    return (kwin6 && workspace.screens) ? workspace.screens[i] : i;
}
function placementArea(scr) {
    return workspace.clientArea(KWin.PlacementArea, scr, workspace.currentDesktop);
}
function isOnCurrentDesktop(w) {
    if (kwin6) {
        if (!w.desktops || w.desktops.length === 0) return true;
        var cur = workspace.currentDesktop;
        for (var i = 0; i < w.desktops.length; i++) {
            if (w.desktops[i] === cur) return true;
        }
        return false;
    }
    return w.desktop === workspace.currentDesktop || w.desktop === -1;
}

// ── Scrolling logic ──────────────────────────────────────────────
var GAP = 8;
var COL_RATIO = 0.70;
var relayouting = false;

var EXCLUDED = [
    "nemac-launcher", "nemac-dock", "nemac-statusbar",
    "nemac-polkit-agent", "nemac-screenshot", "plasmashell", "krunner"
];

// Per-screen ordered window lists: columns[screenKey] = [window, ...]
var columns = {};

function screenKey(scr) {
    if (kwin6 && scr && scr.name) return scr.name;
    return String(scr);
}

function isTileable(c) {
    if (!c) return false;
    if (c.specialWindow) return false;
    if (c.dialog) return false;
    if (c.splash) return false;
    if (c.utility) return false;
    if (c.minimized) return false;
    if (c.fullScreen) return false;
    if (c.skipTaskbar && c.skipPager) return false;

    var cls = String(c.resourceClass).toLowerCase();
    for (var i = 0; i < EXCLUDED.length; i++) {
        if (cls === EXCLUDED[i]) return false;
    }
    return true;
}

function getCol(scr) {
    var key = screenKey(scr);
    if (!columns[key]) columns[key] = [];
    return columns[key];
}

function pruneCol(scr) {
    var key = screenKey(scr);
    var col = getCol(scr);
    var pruned = [];
    for (var i = 0; i < col.length; i++) {
        if (isTileable(col[i]) && isOnCurrentDesktop(col[i])) {
            pruned.push(col[i]);
        }
    }
    columns[key] = pruned;
    return pruned;
}

function indexOf(scr, w) {
    var col = getCol(scr);
    for (var i = 0; i < col.length; i++) {
        if (col[i] === w) return i;
    }
    return -1;
}

function addToCol(w) {
    if (!isTileable(w)) return;
    var scr = screenOf(w);
    if (indexOf(scr, w) >= 0) return;

    var col = getCol(scr);
    var act = activeWindow();
    var insertIdx = col.length;
    if (act && act !== w) {
        var ai = indexOf(scr, act);
        if (ai >= 0) insertIdx = ai + 1;
    }
    col.splice(insertIdx, 0, w);
}

function removeFromCols(w) {
    for (var key in columns) {
        var col = columns[key];
        for (var i = 0; i < col.length; i++) {
            if (col[i] === w) { col.splice(i, 1); return; }
        }
    }
}

function relayout(scr) {
    if (relayouting) return;
    relayouting = true;

    var area = placementArea(scr);
    var col = pruneCol(scr);

    if (col.length === 0) { relayouting = false; return; }

    var colWidth = Math.floor(area.width * COL_RATIO);
    var winH = area.height - 2 * GAP;
    var winW = colWidth - GAP;

    if (col.length === 1) {
        setGeo(col[0], Qt.rect(
            area.x + GAP, area.y + GAP,
            area.width - 2 * GAP, winH
        ));
        relayouting = false;
        return;
    }

    var focusedIdx = 0;
    var act = activeWindow();
    if (act) {
        var ai = indexOf(scr, act);
        if (ai >= 0) focusedIdx = ai;
    }

    var stripPos = focusedIdx * colWidth;
    var centerOff = Math.floor((area.width - winW) / 2);
    var scrollX = stripPos - centerOff;

    for (var i = 0; i < col.length; i++) {
        var x = area.x + (i * colWidth) - scrollX + Math.floor(GAP / 2);
        setGeo(col[i], Qt.rect(x, area.y + GAP, winW, winH));
    }

    relayouting = false;
}

function relayoutAll() {
    var ns = screenCount();
    for (var s = 0; s < ns; s++) relayout(screenAt(s));
}

function onActiveChanged() {
    var act = activeWindow();
    if (!act || !isTileable(act)) return;
    relayout(screenOf(act));
}

function focusDir(delta) {
    var act = activeWindow();
    if (!act) return;
    var scr = screenOf(act);
    var col = pruneCol(scr);
    var idx = indexOf(scr, act);
    if (idx < 0) return;

    var next = idx + delta;
    if (next < 0) next = col.length - 1;
    if (next >= col.length) next = 0;

    setActive(col[next]);
}

function moveDir(delta) {
    var act = activeWindow();
    if (!act || !isTileable(act)) return;
    var scr = screenOf(act);
    var col = getCol(scr);
    var idx = indexOf(scr, act);
    if (idx < 0) return;

    var target = idx + delta;
    if (target < 0 || target >= col.length) return;

    col.splice(idx, 1);
    col.splice(target, 0, act);
    relayout(scr);
}

function connectClient(w) {
    if (w.minimizedChanged)  w.minimizedChanged.connect(function () { relayout(screenOf(w)); });
    if (w.fullScreenChanged) w.fullScreenChanged.connect(function () { relayout(screenOf(w)); });
}

registerShortcut("NemacScrollFocusPrev", "Nemac Scrolling: Focus Previous",
                 "Meta+[", function () { focusDir(-1); });
registerShortcut("NemacScrollFocusNext", "Nemac Scrolling: Focus Next",
                 "Meta+]", function () { focusDir(1); });
registerShortcut("NemacScrollMoveLeft",  "Nemac Scrolling: Move Window Left",
                 "Meta+Shift+[", function () { moveDir(-1); });
registerShortcut("NemacScrollMoveRight", "Nemac Scrolling: Move Window Right",
                 "Meta+Shift+]", function () { moveDir(1); });

// ── Signals ──────────────────────────────────────────────────────
if (kwin6) {
    workspace.windowAdded.connect(function (w) { addToCol(w); connectClient(w); relayout(screenOf(w)); });
    workspace.windowRemoved.connect(function (w) { removeFromCols(w); relayoutAll(); });
    if (workspace.activeWindowChanged) workspace.activeWindowChanged.connect(onActiveChanged);
} else {
    workspace.clientAdded.connect(function (w) { addToCol(w); connectClient(w); relayout(screenOf(w)); });
    workspace.clientRemoved.connect(function (w) { removeFromCols(w); relayoutAll(); });
    if (workspace.clientActivated) workspace.clientActivated.connect(onActiveChanged);
}

workspace.currentDesktopChanged.connect(relayoutAll);

if (kwin6 && workspace.screensChanged)
    workspace.screensChanged.connect(function () { columns = {}; var ws = allWindows(); for (var i = 0; i < ws.length; i++) addToCol(ws[i]); relayoutAll(); });
else if (workspace.numberScreensChanged)
    workspace.numberScreensChanged.connect(function () { columns = {}; var ws = allWindows(); for (var i = 0; i < ws.length; i++) addToCol(ws[i]); relayoutAll(); });

// ── Init ─────────────────────────────────────────────────────────
var init = allWindows();
for (var j = 0; j < init.length; j++) {
    addToCol(init[j]);
    connectClient(init[j]);
}
relayoutAll();
