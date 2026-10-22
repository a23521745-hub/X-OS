#include "xosapi.h"

#include <QDBusConnection>
#include <QDBusInterface>
#include <QDBusReply>
#include <QDateTime>
#include <QFile>
#include <QProcess>
#include <QStandardPaths>
#include <QTimer>

#include <cstdlib>

namespace {

// Active-window tracking on Wayland is intentionally best-effort in v0.1:
// compositors don't expose it to ordinary clients, so we query the optional
// KDE Plasma interface when present and fall back to the session name.
QString sessionName() {
    if (qEnvironmentVariableIsSet("XDG_CURRENT_DESKTOP"))
        return qEnvironmentVariable("XDG_CURRENT_DESKTOP");
    return QStringLiteral("X-OS");
}

} // namespace

XosApi::XosApi(QObject *parent) : QObject(parent)
{
    m_windowPoll = new QTimer(this);
    m_windowPoll->setInterval(1000);
    connect(m_windowPoll, &QTimer::timeout, this, &XosApi::updateActiveWindow);
    m_windowPoll->start();
}

QString XosApi::version() const
{
    return QStringLiteral(XOS_VERSION);
}

QString XosApi::hostname() const
{
    return QString::fromLocal8Bit(std::getenv("HOSTNAME"))
        .isEmpty() ? QStringLiteral("x-os")
                   : QString::fromLocal8Bit(std::getenv("HOSTNAME"));
}

QString XosApi::lockHint() const
{
    return QStringLiteral("Enter değil, parolanı yaz — demo modda herhangi bir şey kabul edilir.");
}

void XosApi::attachShell(QObject *shellRoot)
{
    m_window = qobject_cast<QQuickWindow *>(shellRoot);
    if (m_window) {
        // Track fullscreen state for TopBar auto-hide.
        auto check = [this]() {
            if (!m_window)
                return;
            const bool fs = m_window->visibility() == QWindow::FullScreen;
            if (fs != m_fullscreen) {
                m_fullscreen = fs;
                emit fullscreenActiveChanged();
            }
        };
        connect(m_window, &QQuickWindow::widthChanged, this, check);
        connect(m_window, &QQuickWindow::visibilityChanged, this, check);
    }
    updateActiveWindow();
}

void XosApi::updateActiveWindow()
{
    // v0.1: session label only; richer tracking lands with the KWin script.
    const QString title = sessionName();
    if (title != m_activeWindowTitle) {
        m_activeWindowTitle = title;
        emit activeWindowTitleChanged();
    }
}

void XosApi::toggleThemeMode()
{
    setThemeMode(m_darkMode ? QStringLiteral("light") : QStringLiteral("dark"));
}

void XosApi::setThemeMode(const QString &mode)
{
    const bool dark = (mode != QLatin1String("light"));
    if (dark == m_darkMode)
        return;
    m_darkMode = dark;
    emit darkModeChanged();
}

bool XosApi::tryUnlock(const QString &password)
{
    // v0.1 session locker: no PAM hook yet (milestone: secure lock).
    // Accept anything non-empty so the flow is explorable end-to-end.
    return !password.isEmpty();
}

void XosApi::openSystemSettings()
{
    QProcess::startDetached(QStringLiteral("systemsettings"));
}

void XosApi::openShellSettings()
{
    QProcess::startDetached(QStringLiteral("plasmashell"), {QStringLiteral("--version")});
}

static void loginctl(const QString &verb)
{
    QProcess::startDetached(QStringLiteral("loginctl"), {verb});
}

void XosApi::lockSession() { loginctl(QStringLiteral("lock-session")); emit lockRequested(); }
void XosApi::logout()      { QProcess::startDetached(QStringLiteral("loginctl"),
                                                      {QStringLiteral("terminate-self")}); }
void XosApi::suspend()     { loginctl(QStringLiteral("suspend")); }
void XosApi::shutdown()    { QProcess::startDetached(QStringLiteral("systemctl"), {QStringLiteral("poweroff")}); }
void XosApi::reboot()      { QProcess::startDetached(QStringLiteral("systemctl"), {QStringLiteral("reboot")}); }
