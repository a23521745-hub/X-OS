// PlasmaX shell — entry point.
//
// Modes:
//   plasmex                 normal Wayland/X11 session shell
//   plasmex --demo          synthetic app list + unlocked flow (dev/preview)
//   plasmex --preview WxH   fixed-size window (design review, screenshots)
#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>
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

    QObject::connect(&engine, &QQmlApplicationEngine::objectCreationFailed,
                     &app, []() { QCoreApplication::exit(1); },
                     Qt::QueuedConnection);
    engine.load(QUrl(QStringLiteral("qrc:/plasmx/Main.qml")));

    if (previewSize.isValid()) {
        if (auto *w = qobject_cast<QQuickWindow *>(engine.rootObjects().value(0))) {
            w->setWidth(previewSize.width());
            w->setHeight(previewSize.height());
        }
    }

    return app.exec();
}
