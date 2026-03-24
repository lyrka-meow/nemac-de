/*
 * Copyright (C) 2025 NemacDE Team.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "kwinscripts.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QFile>
#include <QStringLiteral>

static QString resolveScriptMainJs(const QString &pluginId)
{
    static const QStringList roots = {
        QStringLiteral("/usr/share/kwin-wayland/scripts/"),
        QStringLiteral("/usr/share/kwin/scripts/"),
    };
    static const QStringList rels = {
        QStringLiteral("/contents/code/main.js"),
        QStringLiteral("/contents/main.js"),
    };
    for (const QString &root : roots) {
        for (const QString &rel : rels) {
            const QString p = root + pluginId + rel;
            if (QFile::exists(p))
                return p;
        }
    }
    return QString();
}

void nemac_apply_kwin_window_mode(int mode)
{
    QDBusInterface scripting(QStringLiteral("org.kde.KWin"),
                             QStringLiteral("/Scripting"),
                             QStringLiteral("org.kde.kwin.Scripting"),
                             QDBusConnection::sessionBus());
    if (!scripting.isValid())
        return;

    scripting.call(QStringLiteral("unloadScript"), QStringLiteral("nemactiling"));
    scripting.call(QStringLiteral("unloadScript"), QStringLiteral("nemacscrolling"));

    if (mode == 1) {
        const QString path = resolveScriptMainJs(QStringLiteral("nemactiling"));
        if (!path.isEmpty()) {
            scripting.call(QStringLiteral("loadScript"), path, QStringLiteral("nemactiling"));
            scripting.call(QStringLiteral("start"));
        }
    } else if (mode == 2) {
        const QString path = resolveScriptMainJs(QStringLiteral("nemacscrolling"));
        if (!path.isEmpty()) {
            scripting.call(QStringLiteral("loadScript"), path, QStringLiteral("nemacscrolling"));
            scripting.call(QStringLiteral("start"));
        }
    }

    QDBusInterface kwin(QStringLiteral("org.kde.KWin"),
                          QStringLiteral("/KWin"),
                          QStringLiteral("org.kde.KWin"),
                          QDBusConnection::sessionBus());
    if (kwin.isValid())
        kwin.call(QStringLiteral("reconfigure"));
}
