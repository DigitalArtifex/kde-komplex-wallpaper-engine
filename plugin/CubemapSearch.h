#ifndef CUBEMAPSEARCH_H
#define CUBEMAPSEARCH_H

#include <QObject>
#include <QCache>
#include <QFile>
#include <QProcess>
#include <QEventLoop>
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

#include "CubemapMetadata.h"
#include "Komplex_global.h"

class KOMPLEX_EXPORT CubemapSearchModel : public QAbstractItemModel
{
    Q_OBJECT
public:

    enum DataRoles
    {
        Description = Qt::UserRole + 1,
        Id,
        Name,
        Thumbnail
    };
    Q_ENUM(DataRoles)

    enum Status
    {
        Idle,
        Searching,
        Error,
        Downloading
    };
    Q_ENUM(Status)

    CubemapSearchModel(QObject *parent = nullptr);
    ~CubemapSearchModel();

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

    quint64 currentOffset() const;
    void setCurrentOffset(quint64 currentOffset);

    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex &index) const override;

    Q_INVOKABLE void next();
    Q_INVOKABLE void back();
    Q_INVOKABLE void download(QString id);

    qreal downloadProgress() const;
    void setDownloadProgress(qreal downloadProgress);

    QString lastSavedFile() const;
    void setLastSavedFile(const QString &lastSavedFile);
    
    int status() const;
    void setStatus(const int &status, const QString &message = QString());
    QString statusMessage() const;
    void setStatusMessage(const QString &message);

Q_SIGNALS:
    void queryChanged();
    void resultsPerPageChanged();
    void totalResultsChanged();
    void nextPageChanged();
    void previousPageChanged();
    void currentOffsetChanged();
    void downloadProgressChanged();
    void downloadFinished();
    void lastSavedFileChanged();
    void statusChanged();
    void statusMessageChanged();

protected:
    QHash<int, QByteArray> roleNames() const override;

private:
    void getSearchResults(QString url);

    QNetworkAccessManager m_networkManager;
    QString m_query;

    quint16 m_resultsPerPage = 9;
    quint64 m_totalResults = 0;
    quint64 m_currentOffset = 0;
    qreal m_downloadProgress = 0;
    QString m_nextPage;
    QString m_previousPage;
    QString m_lastSavedFile;
    QString m_statusMessage;

    QList<CubemapMetadata> m_data;
    Status m_status = Status::Idle;

    static inline const QHash<int, QByteArray> m_dataRoles =
    {
        {
            static_cast<int>(Description),
            QByteArray("description")
        },
        {
            static_cast<int>(Id),
            QByteArray("id")
        },
        {
            static_cast<int>(Name),
            QByteArray("name")
        },
        {
            static_cast<int>(Thumbnail),
            QByteArray("thumbnail")
        }
    };

    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged FINAL)
    Q_PROPERTY(quint16 resultsPerPage READ resultsPerPage WRITE setResultsPerPage NOTIFY resultsPerPageChanged FINAL)
    Q_PROPERTY(quint64 totalResults READ totalResults WRITE setTotalResults NOTIFY totalResultsChanged FINAL)
    Q_PROPERTY(QString nextPage READ nextPage WRITE setNextPage NOTIFY nextPageChanged FINAL)
    Q_PROPERTY(QString previousPage READ previousPage WRITE setPreviousPage NOTIFY previousPageChanged FINAL)
    Q_PROPERTY(quint64 currentOffset READ currentOffset WRITE setCurrentOffset NOTIFY currentOffsetChanged FINAL)
    Q_PROPERTY(qreal downloadProgress READ downloadProgress WRITE setDownloadProgress NOTIFY downloadProgressChanged FINAL)
    Q_PROPERTY(QString lastSavedFile READ lastSavedFile WRITE setLastSavedFile NOTIFY lastSavedFileChanged FINAL)
    Q_PROPERTY(int status READ status WRITE setStatus NOTIFY statusChanged FINAL)
    Q_PROPERTY(QString statusMessage READ statusMessage WRITE setStatusMessage NOTIFY statusMessageChanged FINAL)
};
Q_DECLARE_METATYPE(CubemapSearchModel)
#endif // CUBEMAPSEARCH_H
