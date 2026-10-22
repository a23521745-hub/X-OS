#include "xdefender.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QTimer>

static const char *kService = "io.xos.XDefender";
static const char *kPath = "/io/xos/XDefender";
static const char *kIface = "io.xos.XDefender";

XDefenderClient::XDefenderClient(QObject *parent) : QObject(parent)
{
    m_retry = new QTimer(this);
    m_retry->setInterval(10000);
    connect(m_retry, &QTimer::timeout, this, &XDefenderClient::refresh);

    QDBusConnection bus = QDBusConnection::sessionBus();
    if (!bus.isConnected()) {
        m_label = QStringLiteral("D-Bus yok");
        emit statusChanged();
        return;
    }

    // Track the X-Defender service appearing/disappearing at runtime.
    bus.connect(QString(), QString(),
                QStringLiteral("org.freedesktop.DBus.NameOwnerChanged"),
                QStringLiteral("sss"), this,
                SLOT(refresh()));

    refresh();
    m_retry->start();
}

void XDefenderClient::refresh()
{
    QDBusConnection bus = QDBusConnection::sessionBus();
    const bool nowAvailable = bus.serviceIsRegistered(QString::fromLatin1(kService));
    if (nowAvailable != m_available) {
        m_available = nowAvailable;
        emit availableChanged();
    }

    if (!m_available) {
        if (m_label != QLatin1String("Bağlı değil")) {
            m_label = QStringLiteral("Bağlı değil");
            m_threats = 0;
            emit statusChanged();
        }
        return;
    }

    QDBusInterface iface(QString::fromLatin1(kService), QString::fromLatin1(kPath),
                         QString::fromLatin1(kIface), bus);
    if (!iface.isValid()) {
        m_available = false;
        emit availableChanged();
        return;
    }

    // Status() → s label   (threats come from ThreatsChanged / optional u out)
    QDBusReply<QString> labelReply = iface.call(QStringLiteral("Status"));
    if (labelReply.isValid())
        m_label = labelReply.value();
    else
        m_label = QStringLiteral("Çevrimiçi");
    emit statusChanged();
}

void XDefenderClient::quickScan()
{
    if (!m_available)
        return;
    QDBusInterface iface(QString::fromLatin1(kService), QString::fromLatin1(kPath),
                         QString::fromLatin1(kIface));
    iface.call(QStringLiteral("QuickScan"));
}
