/*
 * Copyright (C) 2021 NemacDE Team.
 *
 * Author:     Reion Wong <reionwong@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#include "about.h"

#include <QFile>
#include <QStorageInfo>
#include <QRegularExpression>
#include <QSettings>
#include <QProcess>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QTemporaryFile>
#include <QDir>
#include <QVersionNumber>
#include <QUrl>

#ifdef Q_OS_LINUX
#include <sys/sysinfo.h>
#elif defined(Q_OS_FREEBSD)
#include <sys/types.h>
#include <sys/sysctl.h>
#endif

static QString formatByteSize(double size, int precision)
{
    int unit = 0;
    double multiplier = 1024.0;

    while (qAbs(size) >= multiplier && unit < int(8)) {
        size /= multiplier;
        ++unit;
    }

    if (unit == 0) {
        precision = 0;
    }

    QString numString = QString::number(size, 'f', precision);

    switch (unit) {
    case 0:
        return QString("%1 B").arg(numString);
    case 1:
        return QString("%1 KB").arg(numString);
    case 2:
        return QString("%1 MB").arg(numString);
    case 3:
        return QString("%1 GB").arg(numString);
    case 4:
        return QString("%1 TB").arg(numString);
    case 5:
        return QString("%1 PB").arg(numString);
    case 6:
        return QString("%1 EB").arg(numString);
    case 7:
        return QString("%1 ZB").arg(numString);
    case 8:
        return QString("%1 YB").arg(numString);
    default:
        return QString();
    }

    return QString();
}

About::About(QObject *parent)
    : QObject(parent)
    , m_nam(new QNetworkAccessManager(this))
{
}

About::~About()
{
    cancelDeUpdate();
}

bool About::isNemacDE()
{
    if (!QFile::exists("/etc/nemacde"))
        return false;

    QSettings settings("/etc/nemacde", QSettings::IniFormat);
    return settings.value("NemacDE", false).toBool();
}

QString About::version()
{
    if (this->isNemacDE()) {
        QSettings settings("/etc/nemac", QSettings::IniFormat);
        return settings.value("Version").toString();
    }
    return this->prettyProductName();
}

QString About::osName()
{
    return QSysInfo::prettyProductName();
}

QString About::architecture()
{
    return QSysInfo::currentCpuArchitecture();
}

QString About::kernelType()
{
    return QSysInfo::kernelType();
}

QString About::kernelVersion()
{
    return QSysInfo::kernelVersion();
}

QString About::hostname()
{
    return QSysInfo::machineHostName();
}

QString About::userName()
{
    QByteArray userName = qgetenv("USER");

    if (userName.isEmpty())
        userName = qgetenv("USERNAME");

    return QString::fromUtf8(userName);
}

QString About::memorySize()
{
    QString ram;
    const qlonglong totalRam = calculateTotalRam();

    if (totalRam > 0) {
        ram = formatByteSize(totalRam, 0);
    }
    return ram;
}

QString About::prettyProductName()
{
    return QSysInfo::prettyProductName();
}

QString About::internalStorage()
{
    QStorageInfo storage = QStorageInfo::root();
    return QString("%1 / %2")
            .arg(formatByteSize(storage.bytesTotal() - storage.bytesAvailable(), 0))
            .arg(formatByteSize(storage.bytesTotal(), 0));
}

QString About::cpuInfo()
{
    QFile file("/proc/cpuinfo");

    if (file.open(QIODevice::ReadOnly)) {
        QString buffer = file.readAll();
        QStringList modelLine = buffer.split('\n').filter(QRegularExpression("^model name"));
        QStringList lines = buffer.split('\n');

        if (modelLine.isEmpty())
            return "Unknown";

        int count = lines.filter(QRegularExpression("^processor")).count();

        QString result;
        result.append(modelLine.first().split(':').at(1));

        if (count > 0)
            result.append(QString(" x %1").arg(count));

        return result;
    }

    return QString();
}

void About::setDeUpdateState(bool busy, const QString &phase, const QString &status,
                             double progress, bool canCancel)
{
    bool changed = false;
    if (m_deUpdateBusy != busy) {
        m_deUpdateBusy = busy;
        changed = true;
    }
    if (m_deUpdatePhase != phase) {
        m_deUpdatePhase = phase;
        changed = true;
    }
    if (m_deUpdateStatus != status) {
        m_deUpdateStatus = status;
        changed = true;
    }
    if (!qFuzzyCompare(1.0 + m_deUpdateProgress, 1.0 + progress)) {
        m_deUpdateProgress = progress;
        changed = true;
    }
    if (m_deUpdateCanCancel != canCancel) {
        m_deUpdateCanCancel = canCancel;
        changed = true;
    }
    if (changed)
        emit deUpdateStateChanged();
}

QString About::installedVersionString() const
{
    QSettings settings("/etc/nemac", QSettings::IniFormat);
    return settings.value(QStringLiteral("Version")).toString().trimmed();
}

QString About::normalizeTag(const QString &tag)
{
    QString t = tag.trimmed();
    if (t.startsWith(QLatin1Char('v'), Qt::CaseInsensitive) && t.size() > 1)
        t = t.mid(1);
    return t;
}

void About::startDeUpdate()
{
    if (m_deUpdateBusy)
        return;
    if (!isNemacDE())
        return;

    setDeUpdateState(true, QStringLiteral("checking"),
                     QStringLiteral("Проверка обновлений…"), 0.0, true);

    const QUrl releasesUrl(QStringLiteral("https://api.github.com/repos/lyrka-meow/nemac-de/releases/latest"));
    QNetworkRequest req(releasesUrl);
    req.setRawHeader("Accept", "application/vnd.github+json");
    req.setRawHeader("User-Agent", "Nemac-Settings");

    m_reply = m_nam->get(req);
    connect(m_reply, &QNetworkReply::finished, this, &About::onReleasesFinished);
}

void About::cancelDeUpdate()
{
    if (m_reply && m_deUpdateCanCancel) {
        m_reply->abort();
        return;
    }
    if (m_reply) {
        // checking phase — still allow abort
        m_reply->abort();
    }
}

void About::openUpdator()
{
    startDeUpdate();
}

void About::onReleasesFinished()
{
    QPointer<QNetworkReply> reply = m_reply;
    m_reply.clear();

    if (!reply)
        return;

    reply->deleteLater();

    if (m_deUpdatePhase != QLatin1String("checking"))
        return;

    if (reply->error() == QNetworkReply::OperationCanceledError) {
        setDeUpdateState(false, QStringLiteral("idle"),
                         QStringLiteral("Проверка отменена."), 0.0, false);
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        setDeUpdateState(false, QStringLiteral("error"),
                         QStringLiteral("Не удалось связаться с GitHub: %1").arg(reply->errorString()),
                         0.0, false);
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(reply->readAll());
    if (!doc.isObject()) {
        setDeUpdateState(false, QStringLiteral("error"),
                         QStringLiteral("Некорректный ответ сервера."), 0.0, false);
        return;
    }

    const QJsonObject root = doc.object();
    const QString tagName = root.value(QStringLiteral("tag_name")).toString();
    const QString remoteVer = normalizeTag(tagName);

    QString downloadUrl;
    const QJsonArray assets = root.value(QStringLiteral("assets")).toArray();
    for (const QJsonValue &v : assets) {
        const QJsonObject a = v.toObject();
        const QString name = a.value(QStringLiteral("name")).toString();
        if (name.endsWith(QLatin1String(".tar.gz"))) {
            downloadUrl = a.value(QStringLiteral("browser_download_url")).toString();
            break;
        }
    }

    if (downloadUrl.isEmpty()) {
        setDeUpdateState(false, QStringLiteral("error"),
                         QStringLiteral("В релизе нет .tar.gz (соберите пакет: nemac-dev package)."),
                         0.0, false);
        return;
    }

    const QUrl url(downloadUrl);
    const QString host = url.host();
    const bool trustedHost =
            host == QLatin1String("github.com")
            || host.endsWith(QLatin1String(".github.com"))
            || host.endsWith(QLatin1String("githubusercontent.com"));
    if (!trustedHost) {
        setDeUpdateState(false, QStringLiteral("error"),
                         QStringLiteral("Небезопасный URL загрузки."), 0.0, false);
        return;
    }

    const QString localVer = installedVersionString();
    const QVersionNumber loc = QVersionNumber::fromString(localVer.isEmpty() ? QStringLiteral("0") : localVer);
    const QVersionNumber rem = QVersionNumber::fromString(remoteVer);

    if (!rem.isNull() && !loc.isNull() && rem <= loc) {
        setDeUpdateState(false, QStringLiteral("done"),
                         QStringLiteral("У вас последняя версия (%1). Обновление не требуется.").arg(localVer),
                         0.0, false);
        return;
    }

    setDeUpdateState(true, QStringLiteral("downloading"),
                     QStringLiteral("Скачивание %1…").arg(remoteVer.isEmpty() ? tagName : remoteVer),
                     0.0, true);

    startDownload(url);
}

void About::startDownload(const QUrl &url)
{
    QNetworkRequest req(url);
    req.setRawHeader("User-Agent", "Nemac-Settings");

    delete m_tempFile;
    m_tempFile = new QTemporaryFile(QDir::tempPath() + QStringLiteral("/nemac-update-XXXXXX.tar.gz"));
    m_tempFile->setAutoRemove(true);
    if (!m_tempFile->open()) {
        setDeUpdateState(false, QStringLiteral("error"),
                         QStringLiteral("Не удалось создать временный файл."), 0.0, false);
        delete m_tempFile;
        m_tempFile = nullptr;
        return;
    }

    m_reply = m_nam->get(req);
    connect(m_reply, &QNetworkReply::downloadProgress, this, &About::onDownloadProgress);
    connect(m_reply, &QNetworkReply::finished, this, &About::onDownloadFinished);
}

void About::onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    if (bytesTotal > 0)
        setDeUpdateState(true, QStringLiteral("downloading"), m_deUpdateStatus,
                         double(bytesReceived) / double(bytesTotal), true);
}

void About::onDownloadFinished()
{
    QPointer<QNetworkReply> reply = m_reply;
    m_reply.clear();

    if (!reply)
        return;

    reply->deleteLater();

    if (m_deUpdatePhase != QLatin1String("downloading")) {
        return;
    }

    if (reply->error() == QNetworkReply::OperationCanceledError) {
        if (m_tempFile) {
            m_tempFile->close();
            delete m_tempFile;
            m_tempFile = nullptr;
        }
        setDeUpdateState(false, QStringLiteral("idle"),
                         QStringLiteral("Загрузка отменена."), 0.0, false);
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        if (m_tempFile) {
            delete m_tempFile;
            m_tempFile = nullptr;
        }
        setDeUpdateState(false, QStringLiteral("error"),
                         QStringLiteral("Ошибка загрузки: %1").arg(reply->errorString()),
                         0.0, false);
        return;
    }

    const QByteArray data = reply->readAll();
    if (data.isEmpty() || !m_tempFile) {
        setDeUpdateState(false, QStringLiteral("error"),
                         QStringLiteral("Пустой ответ при загрузке."), 0.0, false);
        delete m_tempFile;
        m_tempFile = nullptr;
        return;
    }

    if (m_tempFile->write(data) != data.size()) {
        setDeUpdateState(false, QStringLiteral("error"),
                         QStringLiteral("Не удалось записать архив."), 0.0, false);
        delete m_tempFile;
        m_tempFile = nullptr;
        return;
    }
    m_tempFile->flush();
    m_installTarballPath = m_tempFile->fileName();
    m_tempFile->setAutoRemove(false);
    m_tempFile->close();
    delete m_tempFile;
    m_tempFile = nullptr;

    setDeUpdateState(true, QStringLiteral("installing"),
                     QStringLiteral("Установка (может запросить пароль администратора)…"),
                     1.0, false);

    startInstall(m_installTarballPath);
}

void About::startInstall(const QString &tarballPath)
{
    const QString script = QStringLiteral("tar xzf '%1' -C / && rm -f '%1'")
            .arg(QString(tarballPath).replace(QLatin1Char('\''), QLatin1String("'\\''")));

    m_pkexec = new QProcess(this);
    connect(m_pkexec, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
            this, &About::onPkexecFinished);
    connect(m_pkexec, &QProcess::errorOccurred, this, [this](QProcess::ProcessError error) {
        if (error != QProcess::FailedToStart)
            return;
        const QString path = m_installTarballPath;
        m_installTarballPath.clear();
        QFile::remove(path);
        setDeUpdateState(false, QStringLiteral("error"),
                         QStringLiteral("Не удалось запустить pkexec."), 0.0, false);
        if (m_pkexec) {
            m_pkexec->disconnect();
            m_pkexec->deleteLater();
            m_pkexec.clear();
        }
    });
    m_pkexec->start(QStringLiteral("pkexec"), QStringList{QStringLiteral("bash"), QStringLiteral("-c"), script});
}

void About::onPkexecFinished(int exitCode, QProcess::ExitStatus status)
{
    const QString path = m_installTarballPath;
    m_installTarballPath.clear();

    if (m_pkexec) {
        m_pkexec->deleteLater();
        m_pkexec.clear();
    }

    if (exitCode == 0 && status == QProcess::NormalExit) {
        setDeUpdateState(false, QStringLiteral("done"),
                         QStringLiteral("Обновление установлено. Перезайдите в сессию."),
                         0.0, false);
    } else {
        QFile::remove(path);
        setDeUpdateState(false, QStringLiteral("error"),
                         QStringLiteral("Установка не выполнена (отмена или ошибка)."),
                         0.0, false);
    }
}

qlonglong About::calculateTotalRam() const
{
    qlonglong ret = -1;
#ifdef Q_OS_LINUX
    struct sysinfo info;
    if (sysinfo(&info) == 0)
        ret = qlonglong(info.totalram) * info.mem_unit;
#elif defined(Q_OS_FREEBSD)
    size_t len;
    unsigned long memory;
    len = sizeof(memory);
    sysctlbyname("hw.physmem", &memory, &len, NULL, 0);
    ret = memory;
#endif
    return ret;
}
