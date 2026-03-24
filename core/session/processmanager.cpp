/*
 * Copyright (C) 2021 NemacDE Team.
 *
 * Author:     revenmartin <revenmartin@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "processmanager.h"
#include "application.h"
#include "kwinscripts.h"

#include <QCoreApplication>
#include <QStandardPaths>
#include <QFileInfoList>
#include <QFileInfo>
#include <QSettings>
#include <QDebug>
#include <QTimer>
#include <QThread>
#include <QDir>
#include <QFile>

#include <QDBusInterface>
#include <QDBusPendingCall>

#include <QX11Info>
#include <KWindowSystem>
#include <KWindowSystem/NETWM>

ProcessManager::ProcessManager(Application *app, QObject *parent)
    : QObject(parent)
    , m_app(app)
    , m_wmStarted(false)
    , m_waitLoop(nullptr)
{
    qApp->installNativeEventFilter(this);
}

ProcessManager::~ProcessManager()
{
    qApp->removeNativeEventFilter(this);

    QMapIterator<QString, QProcess *> i(m_systemProcess);
    while (i.hasNext()) {
        i.next();
        QProcess *p = i.value();
        delete p;
        m_systemProcess[i.key()] = nullptr;
    }
}

void ProcessManager::start()
{
    startWindowManager();
    startDaemonProcess();

    // KWin 6: KWin/Script must be loaded via org.kde.kwin.Scripting (loadScript + start);
    // kwinrc [Plugins] + reconfigure alone does not start packaged scripts reliably.
    QTimer::singleShot(800, this, []() {
        QSettings s(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/kwinrc"),
                      QSettings::IniFormat);
        s.beginGroup(QStringLiteral("Plugins"));
        const bool tiling = s.value(QStringLiteral("nemactilingEnabled"), false).toBool();
        const bool scrolling = s.value(QStringLiteral("nemacscrollingEnabled"), false).toBool();
        s.endGroup();
        const int mode = scrolling ? 2 : (tiling ? 1 : 0);
        nemac_apply_kwin_window_mode(mode);
    });
}

void ProcessManager::logout()
{
    QDBusInterface kwinIface("org.kde.KWin",
                             "/Session",
                             "org.kde.KWin.Session",
                             QDBusConnection::sessionBus());

    if (kwinIface.isValid()) {
        kwinIface.call("aboutToSaveSession", "nemac");
        kwinIface.call("setState", uint(2)); // Quit
    }

    QProcess s;
    s.start("killall", QStringList() << "kglobalaccel5");
    s.waitForFinished(-1);

    QDBusInterface iface("org.freedesktop.login1",
                        "/org/freedesktop/login1/session/self",
                        "org.freedesktop.login1.Session",
                        QDBusConnection::systemBus());
    if (iface.isValid())
        iface.call("Terminate");

    QCoreApplication::exit(0);
}

void ProcessManager::startWindowManager()
{
    QProcess *wmProcess = new QProcess;
    wmProcess->start("kwin_x11", QStringList());

    QEventLoop waitLoop;
    m_waitLoop = &waitLoop;
    QTimer::singleShot(30 * 1000, &waitLoop, SLOT(quit()));
    waitLoop.exec();
    m_waitLoop = nullptr;
}

QList<QPair<QString, QStringList>> ProcessManager::desktopProcessEntries() const
{
    QList<QPair<QString, QStringList>> list;
    list << qMakePair(QStringLiteral("nemac-notificationd"), QStringList());
    list << qMakePair(QStringLiteral("nemac-statusbar"), QStringList());
    list << qMakePair(QStringLiteral("nemac-dock"), QStringList());
    list << qMakePair(QStringLiteral("nemac-filemanager"), QStringList({QStringLiteral("--desktop")}));
    list << qMakePair(QStringLiteral("nemac-launcher"), QStringList());
    list << qMakePair(QStringLiteral("nemac-powerman"), QStringList());
    list << qMakePair(QStringLiteral("nemac-clipboard"), QStringList());

    if (QFile(QStringLiteral("/usr/bin/nemac-welcome")).exists()
        && !QFile(QStringLiteral("/run/live/medium/live/filesystem.squashfs")).exists()) {
        QSettings settings(QStringLiteral("nemacde"), QStringLiteral("login"));
        if (!settings.value(QStringLiteral("Finished"), false).toBool()) {
            list << qMakePair(QStringLiteral("/usr/bin/nemac-welcome"), QStringList());
        } else {
            list << qMakePair(QStringLiteral("/usr/bin/nemac-welcome"), QStringList({QStringLiteral("-d")}));
        }
    }
    return list;
}

void ProcessManager::startDesktopProcessEntries(const QList<QPair<QString, QStringList>> &list)
{
    for (const QPair<QString, QStringList> &pair : list) {
        QProcess *process = new QProcess;
        process->setProcessChannelMode(QProcess::ForwardedChannels);
        process->setProgram(pair.first);
        process->setArguments(pair.second);
        process->start();
        process->waitForStarted();

        qDebug() << "Load DE components: " << pair.first << pair.second;

        if (process->exitCode() == 0) {
            m_autoStartProcess.insert(pair.first, process);
        } else {
            process->deleteLater();
        }
    }
}

void ProcessManager::startDesktopProcess()
{
    // When the nemac-settings-daemon theme module is loaded, start the desktop.
    // In the way, there will be no problem that desktop and launcher can't get wallpaper.

    startDesktopProcessEntries(desktopProcessEntries());

    // Auto start
    QTimer::singleShot(100, this, &ProcessManager::loadAutoStartProcess);
}

void ProcessManager::restartDesktopShell()
{
    QMapIterator<QString, QProcess *> it(m_autoStartProcess);
    while (it.hasNext()) {
        it.next();
        QProcess *p = it.value();
        if (!p)
            continue;
        if (p->state() != QProcess::NotRunning) {
            p->terminate();
            if (!p->waitForFinished(4000))
                p->kill();
            p->waitForFinished(2000);
        }
        delete p;
    }
    m_autoStartProcess.clear();

    static const QStringList killNames = {
        QStringLiteral("nemac-notificationd"),
        QStringLiteral("nemac-statusbar"),
        QStringLiteral("nemac-dock"),
        QStringLiteral("nemac-filemanager"),
        QStringLiteral("nemac-launcher"),
        QStringLiteral("nemac-powerman"),
        QStringLiteral("nemac-clipboard"),
        QStringLiteral("nemac-settings-daemon"),
        QStringLiteral("nemac-xembedsniproxy"),
        QStringLiteral("nemac-gmenuproxy"),
        QStringLiteral("chotkeys"),
        QStringLiteral("nemac-welcome"),
    };
    for (const QString &name : killNames) {
        QProcess::execute(QStringLiteral("killall"), QStringList({QStringLiteral("-q"), name}));
    }
    QThread::msleep(800);

    nemac_kwin_replace();

    startDaemonProcess();
    startDesktopProcessEntries(desktopProcessEntries());

    QTimer::singleShot(1000, this, []() {
        QSettings s(QStandardPaths::writableLocation(QStandardPaths::ConfigLocation) + QStringLiteral("/kwinrc"),
                      QSettings::IniFormat);
        s.beginGroup(QStringLiteral("Plugins"));
        const bool tiling = s.value(QStringLiteral("nemactilingEnabled"), false).toBool();
        const bool scrolling = s.value(QStringLiteral("nemacscrollingEnabled"), false).toBool();
        s.endGroup();
        const int mode = scrolling ? 2 : (tiling ? 1 : 0);
        nemac_apply_kwin_window_mode(mode);
    });
}

void ProcessManager::startDaemonProcess()
{
    QList<QPair<QString, QStringList>> list;
    list << qMakePair(QString("nemac-settings-daemon"), QStringList());
    list << qMakePair(QString("nemac-xembedsniproxy"), QStringList());
    list << qMakePair(QString("nemac-gmenuproxy"), QStringList());
    list << qMakePair(QString("chotkeys"), QStringList());

    for (QPair<QString, QStringList> pair : list) {
        QProcess *process = new QProcess;
        process->setProcessChannelMode(QProcess::ForwardedChannels);
        process->setProgram(pair.first);
        process->setArguments(pair.second);
        process->start();
        process->waitForStarted();

        // Add to map
        if (process->exitCode() == 0) {
            m_autoStartProcess.insert(pair.first, process);
        } else {
            process->deleteLater();
        }
    }
}

void ProcessManager::loadAutoStartProcess()
{
    QStringList execList;
    const QStringList dirs = QStandardPaths::locateAll(QStandardPaths::GenericConfigLocation,
                                                       QStringLiteral("autostart"),
                                                       QStandardPaths::LocateDirectory);
    for (const QString &dir : dirs) {
        const QDir d(dir);
        const QStringList fileNames = d.entryList(QStringList() << QStringLiteral("*.desktop"));
        for (const QString &file : fileNames) {
            QSettings desktop(d.absoluteFilePath(file), QSettings::IniFormat);
            desktop.setIniCodec("UTF-8");
            desktop.beginGroup("Desktop Entry");

            if (desktop.contains("OnlyShowIn"))
                continue;

            const QString execValue = desktop.value("Exec").toString();

            // 避免冲突
            if (execValue.contains("gmenudbusmenuproxy"))
                continue;

            if (!execValue.isEmpty()) {
                execList << execValue;
            }
        }
    }

    for (const QString &exec : execList) {
        QProcess *process = new QProcess;
        process->setProgram(exec);
        process->start();
        process->waitForStarted();

        if (process->exitCode() == 0) {
            m_autoStartProcess.insert(exec, process);
        } else {
            process->deleteLater();
        }
    }
}

bool ProcessManager::nativeEventFilter(const QByteArray &eventType, void *message, long *result)
{
    if (eventType != "xcb_generic_event_t") // We only want to handle XCB events
        return false;

    // ref: lxqt session
    if (!m_wmStarted && m_waitLoop) {
        // all window managers must set their name according to the spec
        if (!QString::fromUtf8(NETRootInfo(QX11Info::connection(), NET::SupportingWMCheck).wmName()).isEmpty()) {
            qDebug() << "Window manager started";
            m_wmStarted = true;
            if (m_waitLoop && m_waitLoop->isRunning())
                m_waitLoop->exit();

            qApp->removeNativeEventFilter(this);
        }
    }

    return false;
}
