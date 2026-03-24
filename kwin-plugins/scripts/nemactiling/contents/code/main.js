// ── KWin 5 / 6 compatibility ──────────────────────────────────────
var kwin6 = (typeof workspace.windowList === "function");

function allWindows()    { return kwin6 ? workspace.windowList() : workspace.clientList(); }
function activeWindow()  { return kwin6 ? workspace.activeWindow  : workspace.activeClient; }
function setActive(w)    { if (kwin6) workspace.activeWindow = w; else workspace.activeClient = w; }
function geo(w)          { return kwin6 ? w.frameGeometry : w.geometry; }
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
function connectGeoChanged(w, cb) {
    if (kwin6 && w.frameGeometryChanged) w.frameGeometryChanged.connect(cb);
    else if (w.geometryChanged) w.geometryChanged.connect(cb);
}

// ── Tiling logic ─────────────────────────────────────────────────
var GAP = 8;
var retiling = false;

var EXCLUDED = [
    "nemac-launcher", "nemac-dock", "nemac-statusbar",
    "nemac-polkit-agent", "nemac-screenshot", "plasmashell", "krunner"
];

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

function tileableOnScreen(scr) {
    var all = allWindows();
    var result = [];
    for (var i = 0; i < all.length; i++) {
        var w = all[i];
        if (!isTileable(w)) continue;
        if (!isOnCurrentDesktop(w)) continue;
        var ws = screenOf(w);
        if (kwin6) { if (ws !== scr) continue; }
        else       { if (ws !== scr) continue; }
        result.push(w);
    }
    return result;
}

function retile() {
    if (retiling) return;
    retiling = true;

    var ns = screenCount();
    for (var s = 0; s < ns; s++) {
        var scr = screenAt(s);
        var area = placementArea(scr);
        var wins = tileableOnScreen(scr);

        if (wins.length === 0) continue;

        if (wins.length === 1) {
            setGeo(wins[0], Qt.rect(
                area.x + GAP, area.y + GAP,
                area.width - 2 * GAP, area.height - 2 * GAP
            ));
            continue;
        }

        var masterW = Math.floor((area.width - 3 * GAP) / 2);
        setGeo(wins[0], Qt.rect(
            area.x + GAP, area.y + GAP,
            masterW, area.height - 2 * GAP
        ));

        var stackN = wins.length - 1;
        var stackX = area.x + GAP + masterW + GAP;
        var stackW = area.width - masterW - 3 * GAP;
        var stackH = Math.floor((area.height - GAP * (stackN + 1)) / stackN);

        for (var i = 1; i < wins.length; i++) {
            setGeo(wins[i], Qt.rect(
                stackX,
                area.y + GAP + (i - 1) * (stackH + GAP),
                stackW, stackH
            ));
        }
    }

    retiling = false;
}

function swapWithMaster() {
    var act = activeWindow();
    if (!act || !isTileable(act)) return;
    var wins = tileableOnScreen(screenOf(act));
    if (wins.length < 2 || wins[0] === act) return;

    var masterGeo = geo(wins[0]);
    var actGeo = geo(act);
    setGeo(wins[0], actGeo);
    setGeo(act, masterGeo);
}

function connectClient(w) {
    connectGeoChanged(w, function () {
        if (!retiling && isTileable(w)) retile();
    });
    if (w.minimizedChanged)  w.minimizedChanged.connect(retile);
    if (w.fullScreenChanged) w.fullScreenChanged.connect(retile);
}

registerShortcut(
    "NemacTilingSwapMaster",
    "Nemac Tiling: Swap with Master",
    "Meta+Return",
    swapWithMaster
);

// ── Signals ──────────────────────────────────────────────────────
if (kwin6) {
    workspace.windowAdded.connect(function (w) { connectClient(w); retile(); });
    workspace.windowRemoved.connect(retile);
} else {
    workspace.clientAdded.connect(function (w) { connectClient(w); retile(); });
    workspace.clientRemoved.connect(retile);
}

workspace.currentDesktopChanged.connect(retile);

if (kwin6 && workspace.screensChanged)
    workspace.screensChanged.connect(retile);
else if (workspace.numberScreensChanged)
    workspace.numberScreensChanged.connect(retile);

// ── Init ─────────────────────────────────────────────────────────
var init = allWindows();
for (var j = 0; j < init.length; j++) connectClient(init[j]);
retile();
