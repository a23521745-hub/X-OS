#include "settingsstore.h"

#include <QSettings>

SettingsStore *SettingsStore::s_instance = nullptr;

SettingsStore::SettingsStore(QObject *parent)
    : QObject(parent)
{
    Q_ASSERT(!s_instance);
    s_instance = this;
    setObjectName(QStringLiteral("xos.settings"));
}

SettingsStore *SettingsStore::instance()
{
    return s_instance;
}

QVariantList SettingsStore::stickers() const
{
    QSettings s;
    return s.value(QStringLiteral("stickers/stickers")).toList();
}

void SettingsStore::saveStickers(const QVariantList &stickers)
{
    QSettings s;
    s.setValue(QStringLiteral("stickers/stickers"), stickers);
    s.sync();
    emit stickersChanged();
}

QString SettingsStore::wallpaperId() const
{
    return QSettings().value(QStringLiteral("appearance/wallpaper"), QStringLiteral("aurora")).toString();
}

void SettingsStore::setWallpaperId(const QString &id)
{
    if (wallpaperId() == id)
        return;
    QSettings().setValue(QStringLiteral("appearance/wallpaper"), id);
    emit wallpaperIdChanged();
}

qreal SettingsStore::uiScale() const
{
    return QSettings().value(QStringLiteral("appearance/uiScale"), 1.0).toDouble();
}

void SettingsStore::setUiScale(qreal scale)
{
    if (qFuzzyCompare(uiScale(), scale))
        return;
    QSettings().setValue(QStringLiteral("appearance/uiScale"), scale);
    emit uiScaleChanged();
}
