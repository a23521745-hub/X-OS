#pragma once

#include <QObject>

class QTimer;

// xos.system — CPU/RAM, brightness, volume, battery and network labels.
// All reads are cheap /proc + /sys probes on a 2 s timer; setters go through
// the usual system tools (brightnessctl / wpctl / pactl) when available.
class SystemStatus : public QObject {
    Q_OBJECT
    Q_PROPERTY(qreal cpuPercent READ cpuPercent NOTIFY statsChanged)
    Q_PROPERTY(qreal memoryPercent READ memoryPercent NOTIFY statsChanged)
    Q_PROPERTY(QString networkLabel READ networkLabel NOTIFY networkChanged)
    Q_PROPERTY(int batteryPercent READ batteryPercent NOTIFY batteryChanged)
    Q_PROPERTY(bool onBattery READ onBattery NOTIFY batteryChanged)
    Q_PROPERTY(QString batteryTimeLabel READ batteryTimeLabel NOTIFY batteryChanged)
    Q_PROPERTY(int brightness READ brightness NOTIFY brightnessChanged)
    Q_PROPERTY(int volume READ volume NOTIFY volumeChanged)

public:
    explicit SystemStatus(QObject *parent = nullptr);

    qreal cpuPercent() const { return m_cpu; }
    qreal memoryPercent() const { return m_memory; }
    QString networkLabel() const { return m_networkLabel; }
    int batteryPercent() const { return m_batteryPercent; }
    bool onBattery() const { return m_onBattery; }
    QString batteryTimeLabel() const { return m_batteryTime; }
    int brightness() const { return m_brightness; }
    int volume() const { return m_volume; }

    Q_INVOKABLE void setBrightness(int percent);
    Q_INVOKABLE void setVolume(int percent);

signals:
    void statsChanged();
    void networkChanged();
    void batteryChanged();
    void brightnessChanged();
    void volumeChanged();

private:
    void refresh();
    void refreshNetwork();
    void refreshBattery();

    QTimer *m_timer = nullptr;
    qreal m_cpu = 0.0;
    qreal m_memory = 0.0;
    qint64 m_lastIdle = -1;
    qint64 m_lastTotal = -1;
    QString m_networkLabel;
    int m_batteryPercent = -1;
    bool m_onBattery = false;
    QString m_batteryTime;
    int m_brightness = 80;
    int m_volume = 50;
};
