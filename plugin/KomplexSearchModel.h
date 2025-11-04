#ifndef KomplexSearchModel_H
#define KomplexSearchModel_H

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
#include <QThread>
#include <QFile>

#include "ShaderToyMetadata.h"
#include "Komplex_global.h"

class KOMPLEX_EXPORT KomplexSearchModel : public QAbstractItemModel
{
    Q_OBJECT
public:

    enum DataRoles
    {
        Date = Qt::UserRole + 1,
        Description,
        EmbedUrl,
        Flags,
        HasLiked,
        Id,
        Likes,
        Name,
        Published,
        State,
        Tags,
        Thumbnail,
        UsePreview,
        Username,
        Version,
        Views
    };
    Q_ENUM(DataRoles)

    enum Status
    {
        Idle,
        Loading,
        Searching,
        Compiling,
        Compiled,
        Finalizing,
        Error
    };
    Q_ENUM(Status)

    KomplexSearchModel(QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;

    QModelIndex index(int row, int column, const QModelIndex &parent = QModelIndex()) const override;
    int columnCount(const QModelIndex &parent = QModelIndex()) const override;
    QModelIndex parent(const QModelIndex &index) const override;

    virtual bool setData(const QModelIndex &index, const QVariant &value, int role = Qt::EditRole) override;

    QString lastSavedFile() const;
    void setLastSavedFile(const QString &lastSavedFile);

    Status status() const;
    void setStatus(const Status &status, const QString &message = QString());

    QString query() const;
    void setQuery(const QString &query);

    quint64 resultsPerPage() const;
    void setResultsPerPage(quint64 resultsPerPage);

    quint64 totalResults() const;
    void setTotalResults(quint64 totalResults);

    quint64 currentPage() const;
    void setCurrentPage(quint64 currentPage);

    quint64 totalPages() const;
    void setTotalPages(quint64 totalPages);

    Q_INVOKABLE void next();
    Q_INVOKABLE void previous();
    Q_INVOKABLE void convert(qsizetype index);
    Q_INVOKABLE ShaderToyEntry entry(qsizetype index);
    Q_INVOKABLE void finalize(qsizetype index);
    Q_INVOKABLE void replaceSource(qsizetype index, QString uuid, QString source);

    QString compilerOutput() const;
    void setCompilerOutput(const QString &compilerOutput);

    QString compilerErrorOutput() const;
    void setCompilerErrorOutput(const QString &compilerErrorOutput);

    quint64 totalDownloads() const;
    void setTotalDownloads(quint64 totalDownloads);

    quint64 completedDownloads() const;
    void setCompletedDownloads(quint64 completedDownloads);

    QString downloadText() const;
    void setDownloadText(const QString &downloadText);

    QString statusMessage() const;
    void setStatusMessage(const QString &statusMessage);

    QStringList videoSelections() const;
    void setVideoSelections(const QStringList &videoSelections);
    Q_INVOKABLE void download(quint64 index);

Q_SIGNALS:
    void shaderInstalled();
    void lastSavedFileChanged();
    void statusChanged();
    void queryChanged();
    void resultsPerPageChanged();
    void totalResultsChanged();
    void currentPageChanged();
    void totalPagesChanged();
    void compilerOutputChanged();
    void compilerErrorOutputChanged();
    void totalDownloadsChanged();
    void completedDownloadsChanged();
    void downloadTextChanged();
    void statusMessageChanged();
    void videoSelectionsChanged();

protected:
    QHash<int, QByteArray> roleNames() const override;

private:
    void downloadMedia(QString fileLocation, QString fileUrl);
    void compile(quint64 index);
    void save(quint64 index);
    void install(quint64 index);
    void resetModel();
    void getSearchResults(QString url);

    quint64 getFileSize(QUrl url);
    QString sizeText(quint64 size);

    QNetworkAccessManager m_networkManager;
    QString m_query;

    QList<ShaderToyEntry> m_data;
    QString m_lastSavedFile;
    qreal m_downloadProgress = 0;
    Status m_status = Status::Idle;

    quint64 m_resultsPerPage = 12;
    quint64 m_totalResults = 0;
    quint64 m_currentPage = 0;
    quint64 m_totalPages = 0;

    QString m_compilerOutput;
    QString m_compilerErrorOutput;
    quint64 m_completedDownloads = 0;
    quint64 m_totalDownloads = 0;
    QString m_downloadText;
    QString m_statusMessage;

    QStringList m_videoSelections;

    QNetworkAccessManager m_manager;

    // multiple possible connections to replaceSource
    QMutex m_selectionMutex;

    static inline const QHash<int, QByteArray> m_dataRoles =
    {
        {
            static_cast<int>(Date),
            QByteArray("date")
        },
        {
            static_cast<int>(Description),
            QByteArray("description")
        },
        {
            static_cast<int>(EmbedUrl),
            QByteArray("embedUrl")
        },
        {
            static_cast<int>(Flags),
            QByteArray("flags")
        },
        {
            static_cast<int>(HasLiked),
            QByteArray("hasLiked")
        },
        {
            static_cast<int>(Id),
            QByteArray("id")
        },
        {
            static_cast<int>(Likes),
            QByteArray("likes")
        },
        {
            static_cast<int>(Name),
            QByteArray("name")
        },
        {
            static_cast<int>(Published),
            QByteArray("published")
        },
        {
            static_cast<int>(State),
            QByteArray("state")
        },
        {
            static_cast<int>(Tags),
            QByteArray("tags")
        },
        {
            static_cast<int>(Thumbnail),
            QByteArray("thumbnail")
        },
        {
            static_cast<int>(UsePreview),
            QByteArray("usePreview")
        },
        {
            static_cast<int>(Username),
            QByteArray("username")
        },
        {
            static_cast<int>(Version),
            QByteArray("version")
        },
        {
            static_cast<int>(Views),
            QByteArray("views")
        }
    };

    const static inline QStringList m_supportedChannelTypes =
    {
        QStringLiteral("buffer"),
        QStringLiteral("image"),
        QStringLiteral("video"),
        QStringLiteral("audio"),
        QStringLiteral("texture")
    };

    Q_PROPERTY(QString lastSavedFile READ lastSavedFile WRITE setLastSavedFile NOTIFY lastSavedFileChanged FINAL)
    Q_PROPERTY(Status status READ status WRITE setStatus NOTIFY statusChanged FINAL)
    Q_PROPERTY(QString query READ query WRITE setQuery NOTIFY queryChanged FINAL)
    Q_PROPERTY(quint64 resultsPerPage READ resultsPerPage WRITE setResultsPerPage NOTIFY resultsPerPageChanged FINAL)
    Q_PROPERTY(quint64 totalResults READ totalResults WRITE setTotalResults NOTIFY totalResultsChanged FINAL)
    Q_PROPERTY(quint64 currentPage READ currentPage WRITE setCurrentPage NOTIFY currentPageChanged FINAL)
    Q_PROPERTY(quint64 totalPages READ totalPages WRITE setTotalPages NOTIFY totalPagesChanged FINAL)
    Q_PROPERTY(QString compilerOutput READ compilerOutput WRITE setCompilerOutput NOTIFY compilerOutputChanged FINAL)
    Q_PROPERTY(QString compilerErrorOutput READ compilerErrorOutput WRITE setCompilerErrorOutput NOTIFY compilerErrorOutputChanged FINAL)
    Q_PROPERTY(quint64 totalDownloads READ totalDownloads WRITE setTotalDownloads NOTIFY totalDownloadsChanged FINAL)
    Q_PROPERTY(quint64 completedDownloads READ completedDownloads WRITE setCompletedDownloads NOTIFY completedDownloadsChanged FINAL)
    Q_PROPERTY(QString downloadText READ downloadText WRITE setDownloadText NOTIFY downloadTextChanged FINAL)
    Q_PROPERTY(QString statusMessage READ statusMessage WRITE setStatusMessage NOTIFY statusMessageChanged FINAL)
    Q_PROPERTY(QStringList videoSelections READ videoSelections WRITE setVideoSelections NOTIFY videoSelectionsChanged FINAL)
};
Q_DECLARE_METATYPE(KomplexSearchModel)
#endif // KomplexSearchModel_H
 