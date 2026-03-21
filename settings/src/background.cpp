#include "background.h"
#include <QtConcurrent>
#include <QFileDialog>
#include <QStandardPaths>
#include <QFile>
#include <QFileInfo>
#include <QDateTime>

static QString userWallpaperDir()
{
    return QStandardPaths::writableLocation(QStandardPaths::GenericDataLocation)
           + "/nemacde/wallpapers";
}

static QVariantList getBackgroundPaths()
{
    QVariantList list;

    QStringList dirs;
    dirs << "/usr/share/backgrounds/nemacde" << userWallpaperDir();

    for (const QString &dirPath : dirs) {
        QDirIterator it(dirPath, QStringList() << "*.jpg" << "*.png" << "*.jpeg" << "*.webp",
                        QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            list.append(QVariant(it.next()));
        }
    }

    std::sort(list.begin(), list.end());
    return list;
}

Background::Background(QObject *parent)
    : QObject(parent)
    , m_interface("com.nemac.Settings",
                  "/Theme",
                  "com.nemac.Theme",
                  QDBusConnection::sessionBus(), this)
{
    if (m_interface.isValid()) {
        m_currentPath = m_interface.property("wallpaper").toString();

        QDBusConnection::sessionBus().connect(m_interface.service(),
                                              m_interface.path(),
                                              m_interface.interface(),
                                              "backgroundTypeChanged", this, SIGNAL(backgroundTypeChanged()));
        QDBusConnection::sessionBus().connect(m_interface.service(),
                                              m_interface.path(),
                                              m_interface.interface(),
                                              "backgroundColorChanged", this, SIGNAL(backgroundColorChanged()));
    }
}

QVariantList Background::backgrounds()
{
    QFuture<QVariantList> future = QtConcurrent::run(&getBackgroundPaths);
    QVariantList list = future.result();
    return list;
}

QString Background::currentBackgroundPath()
{
    return m_currentPath;
}

void Background::setBackground(QString path)
{
    if (m_currentPath != path && !path.isEmpty()) {
        m_currentPath = path;

        if (m_interface.isValid()) {
            m_interface.call("setWallpaper", path);
            emit backgroundChanged();
        }
    }
}

int Background::backgroundType()
{
    return m_interface.property("backgroundType").toInt();
}

void Background::setBackgroundType(int type)
{
    m_interface.call("setBackgroundType", QVariant::fromValue(type));
}

QString Background::backgroundColor()
{
    return m_interface.property("backgroundColor").toString();
}

void Background::setBackgroundColor(const QString &color)
{
    m_interface.call("setBackgroundColor", QVariant::fromValue(color));
}

QString Background::customWallpaperDir() const
{
    return userWallpaperDir();
}

void Background::addWallpaper()
{
    QStringList files = QFileDialog::getOpenFileNames(
        nullptr,
        tr("Select Wallpapers"),
        QStandardPaths::writableLocation(QStandardPaths::PicturesLocation),
        tr("Images (*.jpg *.jpeg *.png *.webp)"));

    if (files.isEmpty())
        return;

    QString destDir = customWallpaperDir();
    QDir().mkpath(destDir);

    QString lastCopied;
    for (const QString &file : files) {
        QFileInfo info(file);
        QString dest = destDir + "/" + info.fileName();

        if (QFile::exists(dest))
            dest = destDir + "/" + QString::number(QDateTime::currentMSecsSinceEpoch())
                   + "_" + info.fileName();

        QFile::copy(file, dest);
        lastCopied = dest;
    }

    emit backgroundsListChanged();

    if (!lastCopied.isEmpty())
        setBackground(lastCopied);
}
