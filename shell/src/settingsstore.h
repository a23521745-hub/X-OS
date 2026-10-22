#pragma once

#include <QObject>
#include <QVariantList>

// xos.settings — thin QSettings bridge (stickers, wallpaper, shell prefs).
class SettingsStore : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList stickers READ stickers NOTIFY stickersChanged)
    Q_PROPERTY(QString wallpaperId READ wallpaperId WRITE setWallpaperId NOTIFY wallpaperIdChanged)
    Q_PROPERTY(qreal uiScale READ uiScale WRITE setUiScale NOTIFY uiScaleChanged)

public:
    static SettingsStore *instance();

    explicit SettingsStore(QObject *parent = nullptr);

    QVariantList stickers() const;
    Q_INVOKABLE void saveStickers(const QVariantList &stickers);

    QString wallpaperId() const;
    void setWallpaperId(const QString &id);

    qreal uiScale() const;
    void setUiScale(qreal scale);

signals:
    void stickersChanged();
    void wallpaperIdChanged();
    void uiScaleChanged();

private:
    static SettingsStore *s_instance;
};
