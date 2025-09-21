#ifndef PexelsVideoEntryModel_H
#define PexelsVideoEntryModel_H

#include <QObject>
#include <QFile>
#include <QStandardPaths>
#include <QQuickImageProvider>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QAbstractItemModel>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonValue>
#include <QThread>

#include "PexelsVideoMetadata.h"
#include "Komplex_global.h"


class KOMPLEX_EXPORT PexelsVideoEntryModel : public QAbstractItemModel
{
    Q_OBJECT
public:

    enum DataRoles
    {
        Type = Qt::UserRole + 1,
        Height,
        Id,
        Quality,
        Url,
        Width,
        Fps,
        Size,
        Text
    };
    Q_ENUM(DataRoles)

    enum Status
    {
        Idle,
        Loading
    };
    Q_ENUM(Status)

    PexelsVideoEntryModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex &index) const override;

    virtual bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;
    void setMetadata(const QList<PexelsVideoMetadata> &data);

    QString lastSavedFile() const;
    void setLastSavedFile(const QString &lastSavedFile);

    qreal downloadProgress() const;
    void setDownloadProgress(qreal downloadProgress);
    Q_INVOKABLE void download(quint64 index);
    Q_INVOKABLE void update();

    Status status() const;
    void setStatus(const Status &status);

Q_SIGNALS:
    void downloadProgressChanged();
    void downloadFinished();
    void lastSavedFileChanged();
    void statusChanged();

protected:
    QHash<int, QByteArray> roleNames() const override;

private:
    quint64 getFileSize(QUrl url);
    QString sizeText(quint64 size);

    QNetworkAccessManager m_networkManager;
    QString m_query;

    QList<PexelsVideoMetadata> m_data;
    QString m_lastSavedFile;
    qreal m_downloadProgress = 0;
    Status m_status = Status::Idle;

    static inline const QHash<int, QByteArray> m_dataRoles =
    {
        {
            static_cast<int>(Height),
            QByteArray("videoHeight")
        },
        {
            static_cast<int>(Id),
            QByteArray("id")
        },
        {
            static_cast<int>(Quality),
            QByteArray("quality")
        },
        {
            static_cast<int>(Url),
            QByteArray("url")
        },
        {
            static_cast<int>(Width),
            QByteArray("videoWidth")
        },
        {
            static_cast<int>(Fps),
            QByteArray("fps")
        },
        {
            static_cast<int>(Type),
            QByteArray("videoType")
        },
        {
            static_cast<int>(Text),
            QByteArray("text")
        },
        {
            static_cast<int>(Size),
            QByteArray("size")
        }
    };

    static inline const QStringList m_sizeSuffix =
    {
        QStringLiteral("B"),
        QStringLiteral("KB"),
        QStringLiteral("MB"),
        QStringLiteral("GB"),
        QStringLiteral("TB")
    };

    Q_PROPERTY(QString lastSavedFile READ lastSavedFile WRITE setLastSavedFile NOTIFY lastSavedFileChanged FINAL)
    Q_PROPERTY(qreal downloadProgress READ downloadProgress WRITE setDownloadProgress NOTIFY downloadProgressChanged FINAL)
    Q_PROPERTY(Status status READ status WRITE setStatus NOTIFY statusChanged FINAL)
};

Q_DECLARE_METATYPE(PexelsVideoEntryModel)

#endif // PexelsVideoEntryModel_H
