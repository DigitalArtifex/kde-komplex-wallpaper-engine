#ifndef PexelsImageSearch_H
#define PexelsImageSearch_H

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

#include "PexelsImageMetadata.h"
#include "Komplex_global.h"

class KOMPLEX_EXPORT PexelsImageSearchModel : public QAbstractItemModel
{
    Q_OBJECT
public:

    enum DataRoles
    {
        Alt = Qt::UserRole + 1,
        AverageColor,
        Height,
        Id,
        Liked,
        Photographer,
        PhotographerId,
        PhotographerUrl,
        Thumbnail,
        Url,
        Width,
        Original,
        Large2x,
        Large,
        Medium,
        Small,
        Portrait,
        Landscape
    };
    Q_ENUM(DataRoles)

    enum Status
    {
        Idle,
        Searching
    };
    Q_ENUM(Status)

    PexelsImageSearchModel(QObject *parent = nullptr);
    ~PexelsImageSearchModel();

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
    Q_INVOKABLE void download(QUrl url, quint64 id);

    qreal downloadProgress() const;
    void setDownloadProgress(qreal downloadProgress);

    QString lastSavedFile() const;
    void setLastSavedFile(const QString &lastSavedFile);

    int status() const;
    void setStatus(const int &status);

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

protected:
    QHash<int, QByteArray> roleNames() const override;

private:
    void getSearchResults(QString url);

    QNetworkAccessManager m_networkManager;
    QString m_query;

    quint16 m_resultsPerPage = 9;
    quint64 m_totalResults = 0;
    quint64 m_currentPage = 0;
    qreal m_downloadProgress = 0;
    QString m_nextPage;
    QString m_previousPage;
    QString m_lastSavedFile;

    QList<PexelsImageMetadata> m_data;
    Status m_status = Status::Idle;

    static inline const QHash<int, QByteArray> m_dataRoles =
    {
        {
            static_cast<int>(Alt),
            QByteArray("alt")
        },
        {
            static_cast<int>(AverageColor),
            QByteArray("averageColor")
        },
        {
            static_cast<int>(Height),
            QByteArray("imageHeight")
        },
        {
            static_cast<int>(Id),
            QByteArray("id")
        },
        {
            static_cast<int>(Liked),
            QByteArray("liked")
        },
        {
            static_cast<int>(Photographer),
            QByteArray("photographer")
        },
        {
            static_cast<int>(PhotographerId),
            QByteArray("photographerId")
        },
        {
            static_cast<int>(PhotographerUrl),
            QByteArray("photographerUrl")
        },
        {
            static_cast<int>(Thumbnail),
            QByteArray("thumbnail")
        },
        {
            static_cast<int>(Url),
            QByteArray("url")
        },
        {
            static_cast<int>(Width),
            QByteArray("imageWidth")
        },
        {
            static_cast<int>(Original),
            QByteArray("original")
        },
        {
            static_cast<int>(Large2x),
            QByteArray("large2x")
        },
        {
            static_cast<int>(Large),
            QByteArray("large")
        },
        {
            static_cast<int>(Medium),
            QByteArray("medium")
        },
        {
            static_cast<int>(Small),
            QByteArray("small")
        },
        {
            static_cast<int>(Portrait),
            QByteArray("portrait")
        },
        {
            static_cast<int>(Landscape),
            QByteArray("landscape")
        }
    };

    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged FINAL)
    Q_PROPERTY(quint16 resultsPerPage READ resultsPerPage WRITE setResultsPerPage NOTIFY resultsPerPageChanged FINAL)
    Q_PROPERTY(quint64 totalResults READ totalResults WRITE setTotalResults NOTIFY totalResultsChanged FINAL)
    Q_PROPERTY(QString nextPage READ nextPage WRITE setNextPage NOTIFY nextPageChanged FINAL)
    Q_PROPERTY(QString previousPage READ previousPage WRITE setPreviousPage NOTIFY previousPageChanged FINAL)
    Q_PROPERTY(quint64 currentPage READ currentPage WRITE setCurrentPage NOTIFY currentPageChanged FINAL)
    Q_PROPERTY(qreal downloadProgress READ downloadProgress WRITE setDownloadProgress NOTIFY downloadProgressChanged FINAL)
    Q_PROPERTY(QString lastSavedFile READ lastSavedFile WRITE setLastSavedFile NOTIFY lastSavedFileChanged FINAL)
    Q_PROPERTY(int status READ status WRITE setStatus NOTIFY statusChanged FINAL)
};
Q_DECLARE_METATYPE(PexelsImageSearchModel)
#endif // PexelsImageSearch_H
