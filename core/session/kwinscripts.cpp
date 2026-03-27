/*
 * Copyright (C) 2025 NemacDE Team.
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "kwinscripts.h"

#include <QCoreApplication>
#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusMessage>
#include <QDBusReply>
#include <QElapsedTimer>
#include <QEventLoop>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QDebug>
#include <QStringLiteral>
#include <QByteArray>

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

static void waitScriptsUnloaded(QDBusInterface &scripting)
{
    QElapsedTimer t;
    t.start();
    while (t.elapsed() < 3000) {
        QCoreApplication::processEvents(QEventLoop::AllEvents, 50);
        QDBusReply<bool> til(scripting.call(QStringLiteral("isScriptLoaded"), QStringLiteral("nemactiling")));
        QDBusReply<bool> scr(scripting.call(QStringLiteral("isScriptLoaded"), QStringLiteral("nemacscrolling")));
        const bool still = (til.isValid() && til.value()) || (scr.isValid() && scr.value());
        if (!still)
            return;
    }
}

static void loadScriptWhenReady(QDBusInterface &scripting, const QString &path, const QString &pluginId)
{
    for (int attempt = 0; attempt < 12; ++attempt) {
        QDBusReply<int> rid(scripting.call(QStringLiteral("loadScript"), path, pluginId));
        if (rid.isValid() && rid.value() >= 0)
            return;
        QCoreApplication::processEvents(QEventLoop::AllEvents, 50);
    }
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
    waitScriptsUnloaded(scripting);

    if (mode == 1) {
        const QString path = resolveScriptMainJs(QStringLiteral("nemactiling"));
        if (!path.isEmpty())
            loadScriptWhenReady(scripting, path, QStringLiteral("nemactiling"));
    } else if (mode == 2) {
        const QString path = resolveScriptMainJs(QStringLiteral("nemacscrolling"));
        if (!path.isEmpty())
            loadScriptWhenReady(scripting, path, QStringLiteral("nemacscrolling"));
    }

    scripting.call(QStringLiteral("start"));

    QDBusInterface kwin(QStringLiteral("org.kde.KWin"),
                          QStringLiteral("/KWin"),
                          QStringLiteral("org.kde.KWin"),
                          QDBusConnection::sessionBus());
    if (kwin.isValid())
        kwin.call(QStringLiteral("reconfigure"));
}

static bool startDetachedKwinReplace(const QString &bin)
{
    const QStringList args = {QStringLiteral("--replace")};
    qint64 pid = 0;
    /* Наследует окружение процесса (DISPLAY и т.д.); Qt5 не даёт startDetached с явным env. */
    if (QProcess::startDetached(bin, args, QString(), &pid)) {
        qWarning() << "nemac_kwin_replace: CLI" << bin << "--replace pid" << pid;
        return true;
    }
    return false;
}

static bool tryStartKwinReplaceCli()
{
    QStringList candidates;
    if (!qgetenv("WAYLAND_DISPLAY").isEmpty()) {
        candidates << QStringLiteral("/usr/bin/kwin_wayland")
                   << QStringLiteral("/usr/bin/kwin");
    } else {
        /* Xorg: явно kwin_x11 — общий «kwin» иногда не тем путём подхватывается */
        candidates << QStringLiteral("/usr/bin/kwin_x11")
                   << QStringLiteral("/usr/bin/kwin");
    }
    for (const QString &bin : candidates) {
        const QFileInfo fi(bin);
        if (!fi.isExecutable())
            continue;
        if (startDetachedKwinReplace(bin))
            return true;
    }
    qWarning() << "nemac_kwin_replace: no kwin --replace could be started";
    return false;
}

void nemac_kwin_replace()
{
    QDBusMessage msg = QDBusMessage::createMethodCall(
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("/KWin"),
        QStringLiteral("org.kde.KWin"),
        QStringLiteral("replace"));
    QDBusMessage reply = QDBusConnection::sessionBus().call(msg, QDBus::Block, 30000);
    if (reply.type() == QDBusMessage::ReplyMessage)
        qWarning() << "nemac_kwin_replace: D-Bus replace returned OK";
    else if (reply.type() == QDBusMessage::ErrorMessage)
        qWarning() << "nemac_kwin_replace: D-Bus replace failed:" << reply.errorMessage();
    else
        qWarning() << "nemac_kwin_replace: unexpected D-Bus reply type" << reply.type();

    /* На Xorg D-Bus часто отвечает успехом, но без реальной подмены процесса — всегда делаем kwin_* --replace. */
    if (!tryStartKwinReplaceCli())
        qWarning() << "nemac_kwin_replace: CLI kwin --replace failed (check DISPLAY / session)";
}
