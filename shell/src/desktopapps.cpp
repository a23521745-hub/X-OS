#include "desktopapps.h"
#include "settingsstore.h"

#include <QDir>
#include <QFile>
#include <QFileInfo>
#include <QProcess>
#include <QRegularExpression>
#include <QSettings>
#include <QStandardPaths>
#include <QUuid>

#include <utility>

#include <algorithm>

DesktopApps::DesktopApps(QObject *parent) : QAbstractListModel(parent)
{
    refresh();
}

int DesktopApps::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_apps.size();
}

QVariant DesktopApps::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || index.row() >= m_apps.size())
        return {};
    const DesktopApp &app = m_apps.at(index.row());
    switch (role) {
    case NameRole:    return app.name;
    case CommentRole: return app.comment;
    case IconRole:    return app.icon;
    case ExecRole:    return app.exec;
    case RunningRole: return app.running;
    case CategoryRole: return app.categories;
    default:          return {};
    }
}

QHash<int, QByteArray> DesktopApps::roleNames() const
{
    return {
        { NameRole, "name" },
        { CommentRole, "comment" },
        { IconRole, "icon" },
        { ExecRole, "exec" },
        { RunningRole, "running" },
        { CategoryRole, "category" },
    };
}

void DesktopApps::parseDesktopFile(const QString &path)
{
    QSettings file(path, QSettings::IniFormat);
    file.beginGroup(QStringLiteral("Desktop Entry"));
    if (file.value(QStringLiteral("Type")).toString() != QLatin1String("Application"))
        return;
    if (file.value(QStringLiteral("NoDisplay"), false).toBool()
        || file.value(QStringLiteral("Hidden"), false).toBool())
        return;
    const QString exec = file.value(QStringLiteral("Exec")).toString();
    if (exec.isEmpty())
        return;

    DesktopApp app;
    app.id = QFileInfo(path).completeBaseName();
    app.name = file.value(QStringLiteral("Name")).toString();
    app.comment = file.value(QStringLiteral("Comment")).toString();
    app.icon = file.value(QStringLiteral("Icon")).toString();
    app.exec = exec;
    app.terminal = file.value(QStringLiteral("Terminal"), false).toBool();
    const QString cats = file.value(QStringLiteral("Categories")).toString();
    app.categories = cats.split(QLatin1Char(';'), Qt::SkipEmptyParts);
    file.endGroup();

    if (app.name.isEmpty())
        return;
    // Dedupe by id — first match wins (user overrides come first).
    for (const DesktopApp &existing : std::as_const(m_apps))
        if (existing.id == app.id)
            return;
    m_apps.push_back(app);
}

void DesktopApps::refresh()
{
    beginResetModel();
    m_apps.clear();

    const QStringList dataDirs = QStandardPaths::standardLocations(QStandardPaths::GenericDataLocation);
    QStringList roots;
    for (const QString &dir : dataDirs)
        roots << dir + QStringLiteral("/applications");

    for (const QString &root : std::as_const(roots)) {
        QDir dir(root);
        if (!dir.exists())
            continue;
        const QFileInfoList files = dir.entryInfoList({QStringLiteral("*.desktop")},
                                                       QDir::Files, QDir::Name);
        for (const QFileInfo &fi : files)
            parseDesktopFile(fi.absoluteFilePath());
        // One level of subdirectories (e.g. kde/office/).
        const auto subs = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
        for (const QString &sub : subs) {
            QDir subDir(dir.filePath(sub));
            const QFileInfoList files = subDir.entryInfoList({QStringLiteral("*.desktop")},
                                                              QDir::Files, QDir::Name);
            for (const QFileInfo &fi : files)
                parseDesktopFile(fi.absoluteFilePath());
        }
    }

    std::sort(m_apps.begin(), m_apps.end(),
              [](const DesktopApp &a, const DesktopApp &b) { return a.name < b.name; });
    endResetModel();
    emit countChanged();
}

void DesktopApps::launchIndex(int row)
{
    if (row < 0 || row >= m_apps.size())
        return;
    const DesktopApp &app = m_apps.at(row);
    // Strip field codes (%f %u …) and launch detached.
    QString exec = app.exec;
    exec.remove(QRegularExpression(QStringLiteral("%[fFuUdDnNickvm]")));
    exec = exec.trimmed();
    if (exec.startsWith(QLatin1Char('"')) && exec.endsWith(QLatin1Char('"')))
        exec = exec.mid(1, exec.size() - 2);
    QProcess::startDetached(QStringLiteral("/bin/sh"), {QStringLiteral("-c"), exec});
    m_apps[row].running = true;
    const QModelIndex idx = index(row);
    emit dataChanged(idx, idx, { RunningRole });
}

void DesktopApps::launch(const QString &desktopId)
{
    for (int i = 0; i < m_apps.size(); ++i)
        if (m_apps.at(i).id == desktopId) {
            launchIndex(i);
            return;
        }
}

void DesktopApps::addSticker(const QString &glyph, qreal x, qreal y)
{
    auto *store = SettingsStore::instance();
    if (!store)
        return;
    QVariantList list = store->stickers().toList();
    QVariantMap sticker;
    sticker.insert(QStringLiteral("id"), QUuid::createUuid().toString(QUuid::WithoutBraces));
    sticker.insert(QStringLiteral("glyph"), glyph);
    sticker.insert(QStringLiteral("x"), x);
    sticker.insert(QStringLiteral("y"), y);
    sticker.insert(QStringLiteral("rot"), 0.0);
    sticker.insert(QStringLiteral("scale"), 1.0);
    sticker.insert(QStringLiteral("color"), QStringLiteral("#7C5CFF33"));
    list.push_back(sticker);
    store->saveStickers(list);
    emit stickersChanged();
}

void DesktopApps::lockSession()  { QProcess::startDetached(QStringLiteral("loginctl"), {QStringLiteral("lock-session")}); }
void DesktopApps::logout()       { QProcess::startDetached(QStringLiteral("loginctl"), {QStringLiteral("terminate-self")}); }
void DesktopApps::suspend()      { QProcess::startDetached(QStringLiteral("systemctl"), {QStringLiteral("suspend")}); }
void DesktopApps::shutdown()     { QProcess::startDetached(QStringLiteral("systemctl"), {QStringLiteral("poweroff")}); }
