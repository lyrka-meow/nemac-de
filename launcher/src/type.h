
#ifndef TYPE_H
#define TYPE_H

#include <QObject>

class QString;

enum LauncherLocation {
    Grid = 0,
    Favorites,
    Desktop
};

struct ApplicationData {
    QString name;
    QString icon;
    QString storageId;
    QString entryPath;
    LauncherLocation location = LauncherLocation::Grid;
    bool startupNotify = true;
};

#endif // TYPE_H
