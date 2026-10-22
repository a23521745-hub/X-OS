#pragma once

#include <QQuickImageProvider>

// image://icon/<name> — theme icon provider so .desktop icons render in the
// Launcher/Dock through the standard icon search path (hicolor/Adwaita/…).
class IconProvider : public QQuickImageProvider {
public:
    IconProvider()
        : QQuickImageProvider(QQuickImageProvider::Image) {}

    QImage requestImage(const QString &id, QSize *size, const QSize &requestedSize) override;
};
