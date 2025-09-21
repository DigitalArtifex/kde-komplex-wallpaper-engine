#ifndef PEXELS_VIDEO_SEARCH_MODEL_H
#define PEXELS_VIDEO_SEARCH_MODEL_H

#include <QObject>
#include <QCache>
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

#include "PexelsVideoModel.h"
#include "PexelsVideoMetadata.h"
#include "Komplex_global.h"

class KOMPLEX_EXPORT PexelsVideoSearchModel : public QAbstractItemModel
{
    Q_OBJECT
public:

    enum DataRoles
    {
        Tags = Qt::UserRole + 1,
        Height,
        Id,
        User,
        UserId,
        UserUrl,
        Thumbnail,
        Url,
        Width
    };
    Q_ENUM(DataRoles)

    enum Status
    {
        Idle,
        Searching
    };
    Q_ENUM(Status)

    PexelsVideoSearchModel(QObject *parent = nullptr);
    ~PexelsVideoSearchModel();

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    QString query() const;
    void setQuery(const QString &query);

    quint16 resultsPerPage() const;
    void setResultsPerPage(quint16 resultsPerPage);

    quint64 totalResults() const;
    void setTotalResults(quint64 totalResults);

    QString nextPage() const;
    void setNextPage(const QString &nextPage);

    QString previousPage() const;
    void setPreviousPage(const QString &previousPage);

    quint64 currentPage() const;
    void setCurrentPage(quint64 currentPage);

    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex &index) const override;

    Q_INVOKABLE void next();
    Q_INVOKABLE void back();

    qreal downloadProgress() const;
    void setDownloadProgress(qreal downloadProgress);

    QString lastSavedFile() const;
    void setLastSavedFile(const QString &lastSavedFile);

    int status() const;
    void setStatus(const int &status);

    PexelsVideoEntryModel *videoModel() const;

    quint64 currentIndex() const;
    void setCurrentIndex(quint64 currentIndex);

Q_SIGNALS:
    void queryChanged();
    void resultsPerPageChanged();
    void totalResultsChanged();
    void nextPageChanged();
    void previousPageChanged();
    void currentPageChanged();
    void downloadProgressChanged();
    void downloadFinished();
    void lastSavedFileChanged();
    void statusChanged();
    void videoModelChanged();

    void currentIndexChanged();

protected:
    QHash<int, QByteArray> roleNames() const override;

private:
    void getSearchResults(QString url);
    quint64 getFileSize(QUrl url);
    QString sizeText(quint64 size);

    QNetworkAccessManager m_networkManager;
    QString m_query;

    quint16 m_resultsPerPage = 9;
    quint64 m_totalResults = 0;
    quint64 m_currentPage = 0;
    quint64 m_currentIndex = 0;
    qreal m_downloadProgress = 0;
    QString m_nextPage;
    QString m_previousPage;
    QString m_lastSavedFile;

    PexelsVideoEntryModel *m_videoModel = nullptr;

    QList<PexelsVideoEntry> m_data;
    Status m_status = Status::Idle;

    static inline const QHash<int, QByteArray> m_dataRoles =
    {
        {
            static_cast<int>(Tags),
            QByteArray("tags")
        },
        {
            static_cast<int>(Height),
            QByteArray("videoHeight")
        },
        {
            static_cast<int>(Id),
            QByteArray("id")
        },
        {
            static_cast<int>(User),
            QByteArray("user")
        },
        {
            static_cast<int>(UserId),
            QByteArray("userId")
        },
        {
            static_cast<int>(UserUrl),
            QByteArray("userUrl")
        },
        {
            static_cast<int>(Thumbnail),
            QByteArray("thumbnail")
        },
        {
            static_cast<int>(Url),
            QByteArray("videoUrl")
        },
        {
            static_cast<int>(Width),
            QByteArray("videoWidth")
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

    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged FINAL)
    Q_PROPERTY(quint16 resultsPerPage READ resultsPerPage WRITE setResultsPerPage NOTIFY resultsPerPageChanged FINAL)
    Q_PROPERTY(quint64 totalResults READ totalResults WRITE setTotalResults NOTIFY totalResultsChanged FINAL)
    Q_PROPERTY(QString nextPage READ nextPage WRITE setNextPage NOTIFY nextPageChanged FINAL)
    Q_PROPERTY(QString previousPage READ previousPage WRITE setPreviousPage NOTIFY previousPageChanged FINAL)
    Q_PROPERTY(quint64 currentPage READ currentPage WRITE setCurrentPage NOTIFY currentPageChanged FINAL)
    Q_PROPERTY(QString lastSavedFile READ lastSavedFile NOTIFY lastSavedFileChanged FINAL)
    Q_PROPERTY(int status READ status WRITE setStatus NOTIFY statusChanged FINAL)
    Q_PROPERTY(PexelsVideoEntryModel *videoModel READ videoModel NOTIFY videoModelChanged FINAL)
    Q_PROPERTY(quint64 currentIndex READ currentIndex WRITE setCurrentIndex NOTIFY currentIndexChanged FINAL)
};

Q_DECLARE_METATYPE(PexelsVideoSearchModel)

#endif // PexelsVideoSearchModel_H
