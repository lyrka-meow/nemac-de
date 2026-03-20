#include "pstyleplugin.h"
#include "basestyle.h"

#include <QApplication>
#include <QStyleFactory>
#include <QDebug>

QStringList ProxyStylePlugin::keys() const
{
    return {"nemac"};
}

QStyle *ProxyStylePlugin::create(const QString &key)
{
    if (key != QStringLiteral("nemac")) {
        return nullptr;
    }

    return new BaseStyle;
}
