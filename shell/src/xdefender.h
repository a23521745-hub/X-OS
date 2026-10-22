#pragma once

#include <QObject>

class QTimer;

// xos.defender — optional D-Bus bridge to the X-Defender security app.
//
// The app ships in a separate repository today; the shell is written so its
// absence is invisible (statusLabel → "Bağlı değil", card hides).  Contract:
//   service   : io.xos.XDefender
//   object    : /io/xos/XDefender
//   interface : io.xos.XDefender
//   methods   : QuickScan() → (u threats), Status() → (s label, u threats)
//   signal    : ThreatsChanged(u threats)
// See integrations/x-defender/README.md for the full contract.
class XDefenderClient : public QObject {
    Q_OBJECT
    Q_PROPERTY(bool available READ available NOTIFY availableChanged)
    Q_PROPERTY(QString statusLabel READ statusLabel NOTIFY statusChanged)
    Q_PROPERTY(int threats READ threats NOTIFY statusChanged)

public:
    explicit XDefenderClient(QObject *parent = nullptr);

    bool available() const { return m_available; }
    QString statusLabel() const { return m_label; }
    int threats() const { return m_threats; }

    Q_INVOKABLE void quickScan();

public slots:
    void refresh();

signals:
    void availableChanged();
    void statusChanged();

private:
    void connectIfPossible();

    bool m_available = false;
    QString m_label = QStringLiteral("Bağlı değil");
    int m_threats = 0;
    bool m_dbusChecked = false;
    QTimer *m_retry = nullptr;
};
