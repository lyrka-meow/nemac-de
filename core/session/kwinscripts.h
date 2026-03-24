/*
 * Apply Nemac KWin/Script packages via org.kde.kwin.Scripting (KWin 5/6).
 * kwinrc [Plugins] alone is not sufficient on KWin 6 — loadScript + start is required.
 */

#ifndef NEMAC_KWINSCRIPTS_H
#define NEMAC_KWINSCRIPTS_H

/** mode: 0 floating, 1 tiling, 2 scrolling */
void nemac_apply_kwin_window_mode(int mode);

#endif
