#pragma once

#include <QAbstractListModel>
#include <QVector>

// xos.apps — .desktop application model for the Launcher and Dock.
struct DesktopApp {
    QString id;
    QString name;
    QString comment;
    QString icon;
    QString exec;
    QStringList categories;
    bool terminal = false;
    bool running = false;
};

class DesktopApps : public QAbstractListModel {
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    enum Roles {
        NameRole = Qt::UserRole + 1,
        CommentRole,
        IconRole,
        ExecRole,
        RunningRole,
        CategoryRole,
    };

    explicit DesktopApps(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void launchIndex(int row);
    Q_INVOKABLE void launch(const QString &desktopId);
    Q_INVOKABLE void addSticker(const QString &glyph, qreal x, qreal y);
    Q_INVOKABLE void lockSession();
    Q_INVOKABLE void logout();
    Q_INVOKABLE void suspend();
    Q_INVOKABLE void shutdown();

    int count() const { return rowCount(); }

signals:
    void countChanged();
    void stickersChanged();

private:
    void parseDesktopFile(const QString &path);
    QVector<DesktopApp> m_apps;
};
