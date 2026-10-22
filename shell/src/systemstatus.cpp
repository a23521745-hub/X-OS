#include "systemstatus.h"

#include <QDir>
#include <QFile>
#include <QProcess>
#include <QTimer>

SystemStatus::SystemStatus(QObject *parent) : QObject(parent)
{
    m_timer = new QTimer(this);
    m_timer->setInterval(2000);
    connect(m_timer, &QTimer::timeout, this, &SystemStatus::refresh);
    m_timer->start();
    refresh();
    refreshNetwork();
    refreshBattery();

    auto *netTimer = new QTimer(this);
    netTimer->setInterval(5000);
    connect(netTimer, &QTimer::timeout, this, &SystemStatus::refreshNetwork);
    netTimer->start();

    auto *batTimer = new QTimer(this);
    batTimer->setInterval(15000);
    connect(batTimer, &QTimer::timeout, this, &SystemStatus::refreshBattery);
    batTimer->start();
}

static bool readProc(const QString &path, QList<qint64> *out)
{
    QFile f(path);
    if (!f.open(QIODevice::ReadOnly | QIODevice::Text))
        return false;
    const QByteArray line = f.readLine();
    const QList<QByteArray> parts = line.split(' ');
    for (const QByteArray &p : parts)
        if (!p.isEmpty())
            out->push_back(p.toLongLong());
    return true;
}

void SystemStatus::refresh()
{
    // CPU: delta of aggregate jiffies.
    QList<qint64> stats;
    if (readProc(QStringLiteral("/proc/stat"), &stats) && stats.size() >= 5) {
        qint64 idle = stats[3] + (stats.size() > 4 ? stats[4] : 0);
        qint64 total = 0;
        for (qint64 v : stats) total += v;
        if (m_lastTotal >= 0) {
            const qint64 dTotal = total - m_lastTotal;
            const qint64 dIdle = idle - m_lastIdle;
            if (dTotal > 0) {
                const qreal pct = 100.0 * double(dTotal - dIdle) / double(dTotal);
                if (!qFuzzyCompare(m_cpu, pct)) { m_cpu = pct; }
            }
        }
        m_lastTotal = total;
        m_lastIdle = idle;
    }

    // Memory: MemAvailable / MemTotal.
    QFile f(QStringLiteral("/proc/meminfo"));
    if (f.open(QIODevice::ReadOnly | QIODevice::Text)) {
        qint64 total = 0, avail = -1;
        while (!f.atEnd()) {
            // QByteArray::section yok — QString'e çevirip ayır.
            const QString line = QString::fromUtf8(f.readLine());
            if (line.startsWith(QLatin1String("MemTotal:")))
                total = line.section(QLatin1Char(' '), 1, 1).trimmed().toLongLong();
            else if (line.startsWith(QLatin1String("MemAvailable:")))
                avail = line.section(QLatin1Char(' '), 1, 1).trimmed().toLongLong();
        }
        if (total > 0 && avail >= 0) {
            const qreal pct = 100.0 * double(total - avail) / double(total);
            if (!qFuzzyCompare(m_memory, pct)) m_memory = pct;
        }
    }
    emit statsChanged();
}

void SystemStatus::refreshNetwork()
{
    QString label;
    // Prefer the first interface that has an address.
    QDir net(QStringLiteral("/sys/class/net"));
    const auto ifs = net.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    for (const QString &iface : ifs) {
        if (iface == QLatin1String("lo"))
            continue;
        QFile oper(QStringLiteral("/sys/class/net/%1/operstate").arg(iface));
        if (!oper.open(QIODevice::ReadOnly))
            continue;
        if (oper.readAll().trimmed() == "up") {
            label = iface.startsWith(QLatin1String("wl")) ? QStringLiteral("Wi-Fi")
                                                          : iface;
            break;
        }
    }
    if (label.isEmpty())
        label = QStringLiteral("çevrimdışı");
    if (label != m_networkLabel) {
        m_networkLabel = label;
        emit networkChanged();
    }
}

void SystemStatus::refreshBattery()
{
    QDir power(QStringLiteral("/sys/class/power_supply"));
    const auto entries = power.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    int percent = -1;
    bool onBattery = false;
    QString time;
    for (const QString &e : entries) {
        const QString base = QStringLiteral("/sys/class/power_supply/%1/").arg(e);
        QFile cap(base + QStringLiteral("capacity"));
        if (cap.open(QIODevice::ReadOnly))
            percent = QString::fromUtf8(cap.readAll()).trimmed().toInt();
        QFile status(base + QStringLiteral("status"));
        if (status.open(QIODevice::ReadOnly)) {
            const QByteArray s = status.readAll().trimmed();
            onBattery = (s == "Discharging");
            if (s == "Charging")
                time = QStringLiteral("şarj oluyor");
        }
    }
    if (percent != m_batteryPercent || onBattery != m_onBattery || time != m_batteryTime) {
        m_batteryPercent = percent;
        m_onBattery = onBattery;
        m_batteryTime = time;
        emit batteryChanged();
    }
}

void SystemStatus::setBrightness(int percent)
{
    percent = qBound(1, percent, 100);
    QProcess::startDetached(QStringLiteral("brightnessctl"),
                            {QStringLiteral("set"), QStringLiteral("%1%").arg(percent)});
    if (m_brightness != percent) {
        m_brightness = percent;
        emit brightnessChanged();
    }
}

void SystemStatus::setVolume(int percent)
{
    percent = qBound(0, percent, 100);
    QProcess::startDetached(QStringLiteral("wpctl"),
                            {QStringLiteral("set-volume"),
                             QStringLiteral("@DEFAULT_AUDIO_SINK@"),
                             QStringLiteral("%1%").arg(percent)});
    if (m_volume != percent) {
        m_volume = percent;
        emit volumeChanged();
    }
}
