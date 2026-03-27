/*
    SPDX-FileCopyrightText: 2009 Marco Martin <notmart@gmail.com>
    SPDX-FileCopyrightText: 2009 Matthieu Gallien <matthieu_gallien@yahoo.fr>
    Modified for NemacDE: 2021-2024

    SPDX-License-Identifier: GPL-2.0-or-later
*/

#include "statusnotifieritemhost.h"
#include "statusnotifieritemsource.h"
#include <QStringList>
#include <QDebug>
#include <QTimer>
#include <QCoreApplication>

#include "dbusproperties.h"

#include <iostream>

class StatusNotifierItemHostSingleton
{
public:
    StatusNotifierItemHost self;
};

Q_GLOBAL_STATIC(StatusNotifierItemHostSingleton, privateStatusNotifierItemHostSelf)

static const QString s_watcherServiceName(QStringLiteral("org.kde.StatusNotifierWatcher"));

StatusNotifierItemHost::StatusNotifierItemHost()
    : QObject()
    , m_statusNotifierWatcher(nullptr)
{
    // Завет 3: Стабильность. Выносим инициализацию из конструктора в отдельный метод.
    init();
}

StatusNotifierItemHost::~StatusNotifierItemHost()
{
    if (QDBusConnection::sessionBus().isConnected()) {
        QDBusConnection::sessionBus().unregisterService(m_serviceName);
    }
}

StatusNotifierItemHost *StatusNotifierItemHost::self()
{
    return &privateStatusNotifierItemHostSelf()->self;
}

const QList<QString> StatusNotifierItemHost::services() const
{
    return m_sniServices.keys();
}

StatusNotifierItemSource *StatusNotifierItemHost::itemForService(const QString service)
{
    return m_sniServices.value(service);
}

void StatusNotifierItemHost::init()
{
    if (QDBusConnection::sessionBus().isConnected()) {
        m_serviceName = "org.kde.StatusNotifierHost-" + QString::number(QCoreApplication::applicationPid());

        // Завет 3: Предотвращение гонки условий (Race Condition).
        // Даем системе 500мс на запуск всех фоновых процессов перед тем, 
        // как статусбар объявит себя хостом системного трея.
        QTimer::singleShot(500, this, [this]() {
            if (!QDBusConnection::sessionBus().registerService(m_serviceName)) {
                qWarning() << "Failed to register DBus service:" << m_serviceName;
            }

            QDBusServiceWatcher *watcher =
                new QDBusServiceWatcher(s_watcherServiceName, QDBusConnection::sessionBus(), QDBusServiceWatcher::WatchForOwnerChange, this);
            
            connect(watcher, &QDBusServiceWatcher::serviceOwnerChanged, this, &StatusNotifierItemHost::serviceChange);

            // Начинаем регистрацию в Watcher
            registerWatcher(s_watcherServiceName);
        });
    }
}

void StatusNotifierItemHost::serviceChange(const QString &name, const QString &oldOwner, const QString &newOwner)
{
    if (newOwner.isEmpty()) {
        // Сервис Watcher пропал из системы
        unregisterWatcher(name);
    } else if (oldOwner.isEmpty()) {
        // Сервис Watcher появился (например, после рестарта рабочего стола)
        registerWatcher(name);
    }
}

void StatusNotifierItemHost::registerWatcher(const QString &service)
{
    if (service == s_watcherServiceName) {
        if (m_statusNotifierWatcher) {
            delete m_statusNotifierWatcher;
        }

        m_statusNotifierWatcher =
            new org::kde::StatusNotifierWatcher(s_watcherServiceName, QStringLiteral("/StatusNotifierWatcher"), QDBusConnection::sessionBus());
        
        if (m_statusNotifierWatcher->isValid()) {
            // Сообщаем системе, что мы — новый Хост для иконок
            m_statusNotifierWatcher->call(QDBus::NoBlock, QStringLiteral("RegisterStatusNotifierHost"), m_serviceName);

            OrgFreedesktopDBusPropertiesInterface propetriesIface(m_statusNotifierWatcher->service(),
                                                                  m_statusNotifierWatcher->path(),
                                                                  m_statusNotifierWatcher->connection());

            connect(m_statusNotifierWatcher,
                    &OrgKdeStatusNotifierWatcherInterface::StatusNotifierItemRegistered,
                    this,
                    &StatusNotifierItemHost::serviceRegistered);
            connect(m_statusNotifierWatcher,
                    &OrgKdeStatusNotifierWatcherInterface::StatusNotifierItemUnregistered,
                    this,
                    &StatusNotifierItemHost::serviceUnregistered);

            // Запрашиваем список уже запущенных приложений с иконками
            QDBusPendingReply<QDBusVariant> pendingItems = propetriesIface.Get(m_statusNotifierWatcher->interface(), "RegisteredStatusNotifierItems");

            QDBusPendingCallWatcher *watcher = new QDBusPendingCallWatcher(pendingItems, this);
            connect(watcher, &QDBusPendingCallWatcher::finished, this, [=]() {
                watcher->deleteLater();
                QDBusReply<QDBusVariant> reply = *watcher;
                if (reply.isValid()) {
                    QStringList registeredItems = reply.value().variant().toStringList();
                    for (const QString &itemService : registeredItems) {
                        if (!m_sniServices.contains(itemService)) {
                            addSNIService(itemService);
                        }
                    }
                }
            });
        } else {
            delete m_statusNotifierWatcher;
            m_statusNotifierWatcher = nullptr;
            qDebug() << "System tray watcher not reachable. Retrying in 2 seconds...";
            // Если watcher еще не готов, попробуем еще раз через 2 секунды
            QTimer::singleShot(2000, this, [this]() { registerWatcher(s_watcherServiceName); });
        }
    }
}

void StatusNotifierItemHost::unregisterWatcher(const QString &service)
{
    if (service == s_watcherServiceName && m_statusNotifierWatcher) {
        qDebug() << "StatusNotifierWatcher disappeared";

        m_statusNotifierWatcher->disconnect();
        removeAllSNIServices();

        delete m_statusNotifierWatcher;
        m_statusNotifierWatcher = nullptr;
    }
}

void StatusNotifierItemHost::serviceRegistered(const QString &service)
{
    if (!m_sniServices.contains(service)) {
        addSNIService(service);
    }
}

void StatusNotifierItemHost::serviceUnregistered(const QString &service)
{
    removeSNIService(service);
}

void StatusNotifierItemHost::removeAllSNIServices()
{
    QHashIterator<QString, StatusNotifierItemSource *> it(m_sniServices);
    while (it.hasNext()) {
        it.next();
        StatusNotifierItemSource *item = it.value();
        item->disconnect();
        item->deleteLater();
        Q_EMIT itemRemoved(it.key());
    }
    m_sniServices.clear();
}

void StatusNotifierItemHost::addSNIService(const QString &service)
{
    // Завет 1: Чистота. Создаем источник данных для каждой иконки.
    StatusNotifierItemSource *item = new StatusNotifierItemSource(service, this);
    m_sniServices.insert(service, item);
    Q_EMIT itemAdded(service);
}

void StatusNotifierItemHost::removeSNIService(const QString &service)
{
    if (m_sniServices.contains(service)) {
        auto item = m_sniServices.value(service);
        item->disconnect();
        item->deleteLater();
        m_sniServices.remove(service);
        Q_EMIT itemRemoved(service);
    }
}
