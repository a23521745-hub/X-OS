// PlasmaX shell — entry point.
//
// Modes:
//   plasmex                 normal Wayland/X11 session shell
//   plasmex --demo          synthetic app list + unlocked flow (dev/preview)
//   plasmex --preview WxH   fixed-size window (design review, screenshots)
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlError>
#include <QQuickStyle>
#include <QQuickWindow>
#include <QSize>
#include <QStringList>
#include <QVariant>
#include <QIcon>

#include "desktopapps.h"
#include "iconprovider.h"
#include "settingsstore.h"
#include "systemstatus.h"
#include "xosapi.h"
#include "xdefender.h"

#ifdef XOS_WITH_LAYERSHELL
#include <LayerShellQt/Shell>
#endif

int main(int argc, char *argv[])
{
    // Wayland first; let Qt fall back to X11 (and offscreen for CI).
    if (qEnvironmentVariableIsEmpty("QT_QPA_PLATFORM") && qEnvironmentVariableIsSet("WAYLAND_DISPLAY"))
        qputenv("QT_QPA_PLATFORM", "wayland");

    QGuiApplication app(argc, argv);
    QGuiApplication::setApplicationName(QStringLiteral("plasmex"));
    QGuiApplication::setOrganizationName(QStringLiteral("X-OS"));
    QGuiApplication::setApplicationVersion(QStringLiteral(XOS_VERSION));
    QQuickStyle::setStyle(QStringLiteral("Basic"));

    const QStringList args = QGuiApplication::arguments();
    const bool demo = args.contains(QStringLiteral("--demo"));
    QSize previewSize;
    for (int i = 0; i < args.size(); ++i) {
        if (args.at(i) == QLatin1String("--preview") && i + 1 < args.size()) {
            const QStringList wh = args.at(i + 1).split(QLatin1Char('x'));
            if (wh.size() == 2)
                previewSize = QSize(wh[0].toInt(), wh[1].toInt());
        }
    }
    if (demo)
        qputenv("XOS_DEMO", "1");

#ifdef XOS_WITH_LAYERSHELL
    // Every QQuickWindow created after this line becomes a wl-layer-shell
    // surface (anchorable panel windows instead of plain fullscreen ones).
    LayerShellQt::Shell::useLayerShell();
#endif

    auto *api = new XosApi;
    auto *apps = new DesktopApps;
    auto *system = new SystemStatus;
    auto *store = new SettingsStore;
    auto *defender = new XDefenderClient;

    QQmlApplicationEngine engine;
    engine.addImageProvider(QStringLiteral("icon"), new IconProvider);
    engine.rootContext()->setContextProperty(QStringLiteral("xos.api"), api);
    engine.rootContext()->setContextProperty(QStringLiteral("xos.apps"), apps);
    engine.rootContext()->setContextProperty(QStringLiteral("xos.system"), system);
    engine.rootContext()->setContextProperty(QStringLiteral("xos.settings"), store);
    engine.rootContext()->setContextProperty(QStringLiteral("xos.defender"), defender);

    engine.addImportPath(QStringLiteral("qrc:/plasmx"));
    engine.addImportPath(QCoreApplication::applicationDirPath() + QStringLiteral("/qml"));

    // Required properties are satisfied through initialProperties — this is
    // the one mechanism guaranteed to work for `required` roots.
    QQmlComponent component(&engine, QUrl(QStringLiteral("qrc:/plasmx/Main.qml")));
    if (component.isError()) {
        for (const QQmlError &err : component.errors())
            qWarning() << err.toString();
        return 1;
    }
    QObject *root = component.createWithInitialProperties({
        { QStringLiteral("api"), QVariant::fromValue(static_cast<QObject *>(api)) },
        { QStringLiteral("apps"), QVariant::fromValue(static_cast<QObject *>(apps)) },
        { QStringLiteral("system"), QVariant::fromValue(static_cast<QObject *>(system)) },
        { QStringLiteral("settings"), QVariant::fromValue(static_cast<QObject *>(store)) },
        { QStringLiteral("defender"), QVariant::fromValue(static_cast<QObject *>(defender)) },
    });
    if (!root) {
        for (const QQmlError &err : component.errors())
            qWarning() << err.toString();
        return 1;
    }

    if (previewSize.isValid()) {
        if (auto *w = qobject_cast<QQuickWindow *>(root)) {
            w->setWidth(previewSize.width());
            w->setHeight(previewSize.height());
        }
    }

    return app.exec();
}
