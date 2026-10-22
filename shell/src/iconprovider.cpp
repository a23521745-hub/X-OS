#include "iconprovider.h"

#include <QIcon>
#include <QPainter>

QImage IconProvider::requestImage(const QString &id, QSize *size, const QSize &requestedSize)
{
    const int w = requestedSize.width() > 0 ? requestedSize.width() : 64;
    const int h = requestedSize.height() > 0 ? requestedSize.height() : w;

    QIcon icon = QIcon::fromTheme(id);
    QImage img(w, h, QImage::Format_ARGB32_Premultiplied);
    img.fill(Qt::transparent);

    if (icon.isNull()) {
        // Fallback: monogram tile with the accent colour.
        QPainter p(&img);
        p.setRenderHint(QPainter::Antialiasing);
        p.setPen(Qt::NoPen);
        p.setBrush(QColor(0x7C, 0x5C, 0xFF, 0x33));
        p.drawRoundedRect(0, 0, w, h, w / 5.0, h / 5.0);
        p.setPen(QColor(0x7C, 0x5C, 0xFF));
        QFont f = p.font();
        f.setPixelSize(qMax(10, h / 2));
        f.setBold(true);
        p.setFont(f);
        p.drawText(QRect(0, 0, w, h), Qt::AlignCenter,
                   id.isEmpty() ? QStringLiteral("?") : id.left(1).toUpper());
    } else {
        img = icon.pixmap(w, h).toImage();
        if (img.width() != w || img.height() != h)
            img = img.scaled(w, h, Qt::KeepAspectRatio, Qt::SmoothTransformation);
    }

    if (size)
        *size = QSize(img.width(), img.height());
    return img;
}
