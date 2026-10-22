#pragma once

#include <QObject>
#include <QPointer>
#include <QQuickWindow>

class QTimer;

// xos.api — services exposed to the shell QML.
// The shell attaches its window via attachShell(); everything else is plain
// Q_PROPERTY / Q_INVOKABLE so QML can consume it directly.
class XosApi : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString version READ version CONSTANT)
    Q_PROPERTY(QString hostname READ hostname CONSTANT)
    Q_PROPERTY(QString activeWindowTitle READ activeWindowTitle NOTIFY activeWindowTitleChanged)
    Q_PROPERTY(bool fullscreenActive READ fullscreenActive NOTIFY fullscreenActiveChanged)
    Q_PROPERTY(qreal pointerX READ pointerX NOTIFY pointerMoved)
    Q_PROPERTY(qreal pointerY READ pointerY NOTIFY pointerMoved)
    Q_PROPERTY(bool darkMode READ darkMode NOTIFY darkModeChanged)
    Q_PROPERTY(QString lockHint READ lockHint CONSTANT)

public:
    explicit XosApi(QObject *parent = nullptr);

    QString version() const;
    QString hostname() const;
    QString activeWindowTitle() const { return m_activeWindowTitle; }
    bool fullscreenActive() const { return m_fullscreen; }
    qreal pointerX() const { return m_pointerX; }
    qreal pointerY() const { return m_pointerY; }
    bool darkMode() const { return m_darkMode; }
    QString lockHint() const;

    Q_INVOKABLE void attachShell(QObject *shellRoot);
    Q_INVOKABLE void toggleThemeMode();
    Q_INVOKABLE void setThemeMode(const QString &mode);
    Q_INVOKABLE bool tryUnlock(const QString &password);
    Q_INVOKABLE void openSystemSettings();
    Q_INVOKABLE void openShellSettings();
    Q_INVOKABLE void lockSession();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void shutdown();
    Q_INVOKABLE void reboot();

signals:
    void activeWindowTitleChanged();
    void fullscreenActiveChanged();
    void pointerMoved();
    void darkModeChanged();
    void lockRequested();

private:
    void updateActiveWindow();

    QPointer<QQuickWindow> m_window;
    QString m_activeWindowTitle;
    bool m_fullscreen = false;
    qreal m_pointerX = 0.0;
    qreal m_pointerY = 0.0;
    bool m_darkMode = true;
    QTimer *m_windowPoll = nullptr;
};
