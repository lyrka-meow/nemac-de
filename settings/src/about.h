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

#ifndef ABOUT_H
#define ABOUT_H

#include <QObject>
#include <QString>
#include <QSysInfo>
#include <QProcess>
#include <qqml.h>
#include <QPointer>

class QNetworkAccessManager;
class QNetworkReply;
class QTemporaryFile;

class About : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isNemacDE READ isNemacDE CONSTANT)
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString osName READ osName CONSTANT)
    Q_PROPERTY(QString architecture READ architecture CONSTANT)
    Q_PROPERTY(QString kernelVersion READ kernelVersion CONSTANT)
    Q_PROPERTY(QString hostname READ hostname CONSTANT)
    Q_PROPERTY(QString userName READ userName CONSTANT)
    Q_PROPERTY(QString memorySize READ memorySize CONSTANT)
    Q_PROPERTY(QString prettyProductName READ prettyProductName CONSTANT)
    Q_PROPERTY(QString internalStorage READ internalStorage CONSTANT)
    Q_PROPERTY(QString cpuInfo READ cpuInfo CONSTANT)

    Q_PROPERTY(bool deUpdateBusy READ deUpdateBusy NOTIFY deUpdateStateChanged)
    Q_PROPERTY(double deUpdateProgress READ deUpdateProgress NOTIFY deUpdateStateChanged)
    Q_PROPERTY(QString deUpdateStatus READ deUpdateStatus NOTIFY deUpdateStateChanged)
    Q_PROPERTY(bool deUpdateCanCancel READ deUpdateCanCancel NOTIFY deUpdateStateChanged)
    Q_PROPERTY(QString deUpdatePhase READ deUpdatePhase NOTIFY deUpdateStateChanged)

signals:
    void deUpdateStateChanged();

public:
    explicit About(QObject *parent = nullptr);
    ~About() override;

    bool isNemacDE();

    QString version();

    QString osName();
    QString architecture();
    QString kernelType();
    QString kernelVersion();
    QString hostname();
    QString userName();
    QString settingsVersion();
    QString memorySize();
    QString prettyProductName();
    QString internalStorage();
    QString cpuInfo();

    bool deUpdateBusy() const { return m_deUpdateBusy; }
    double deUpdateProgress() const { return m_deUpdateProgress; }
    QString deUpdateStatus() const { return m_deUpdateStatus; }
    bool deUpdateCanCancel() const { return m_deUpdateCanCancel; }
    QString deUpdatePhase() const { return m_deUpdatePhase; }

    Q_INVOKABLE void startDeUpdate();
    Q_INVOKABLE void cancelDeUpdate();
    /** @deprecated use startDeUpdate() — kept for compatibility */
    Q_INVOKABLE void openUpdator();

private slots:
    void onReleasesFinished();
    void onDownloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void onDownloadFinished();
    void onPkexecFinished(int exitCode, QProcess::ExitStatus status);

private:
    qlonglong calculateTotalRam() const;
    void setDeUpdateState(bool busy, const QString &phase, const QString &status,
                          double progress, bool canCancel);
    void startDownload(const QUrl &url);
    void startInstall(const QString &tarballPath);
    QString installedVersionString() const;
    static QString normalizeTag(const QString &tag);

    QNetworkAccessManager *m_nam = nullptr;
    QPointer<QNetworkReply> m_reply;
    QPointer<QProcess> m_pkexec;
    QTemporaryFile *m_tempFile = nullptr;
    QString m_installTarballPath;

    bool m_deUpdateBusy = false;
    double m_deUpdateProgress = 0.0;
    QString m_deUpdateStatus;
    bool m_deUpdateCanCancel = false;
    QString m_deUpdatePhase = QStringLiteral("idle");
};

#endif // ABOUT_H
