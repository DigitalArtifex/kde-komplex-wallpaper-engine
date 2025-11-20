#include "PexelsImageSearch.h"

PexelsImageSearchModel::PexelsImageSearchModel(QObject *parent) : QAbstractItemModel { parent }
{
    m_networkManager.setAutoDeleteReplies(true);
}

PexelsImageSearchModel::~PexelsImageSearchModel()
{

}

int PexelsImageSearchModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_data.size();
}

QVariant PexelsImageSearchModel::data(const QModelIndex &index, int role) const
{
    if(index.row() < 0 || index.row() >= m_data.count())
        return QVariant();

    QVariant data;

    switch (static_cast<DataRoles>(role)) {
    case Alt:
        data = QVariant::fromValue<QString>(m_data[index.row()].alt);
        break;
    case AverageColor:
        data = QVariant::fromValue<QString>(m_data[index.row()].averageColorCode);
        break;
    case Height:
        data = QVariant::fromValue<quint64>(m_data[index.row()].height);
        break;
    case Id:
        data = QVariant::fromValue<quint64>(m_data[index.row()].id);
        break;
    case Liked:
        data = QVariant::fromValue<bool>(m_data[index.row()].liked);
        break;
    case Photographer:
        data = QVariant::fromValue<QString>(m_data[index.row()].photographer);
        break;
    case PhotographerUrl:
        data = QVariant::fromValue<QUrl>(m_data[index.row()].photographerUrl);
        break;
    case PhotographerId:
        data = QVariant::fromValue<quint64>(m_data[index.row()].photographerId);
        break;
    case Thumbnail:
        data = QVariant::fromValue<QUrl>(m_data[index.row()].thumbnail);
        break;
    case Url:
        data = QVariant::fromValue<QUrl>(m_data[index.row()].url);
        break;
    case Width:
        data = QVariant::fromValue<quint64>(m_data[index.row()].width);
        break;
    case Original:
    case Large2x:
    case Large:
    case Medium:
    case Small:
    case Portrait:
    case Landscape:
        if(m_data[index.row()].sources.contains(QString::fromUtf8(m_dataRoles[role])))
            data = QVariant::fromValue<QUrl>(m_data[index.row()].sources[QString::fromUtf8(m_dataRoles[role])]);
        break;
    }

    return data;
}

QHash<int, QByteArray> PexelsImageSearchModel::roleNames() const
{
    return m_dataRoles;
}

void PexelsImageSearchModel::getSearchResults(QString url)
{
    setStatus(Searching);

    QNetworkRequest request;
    //request.setRawHeader(QStringLiteral("Authorization").toLatin1(), QStringLiteral(PAK).toLatin1());
    request.setUrl(QUrl(url));

    QNetworkReply *reply = m_networkManager.get(request);

    QObject::connect
    (
        reply,
        &QNetworkReply::finished,
        this,
        [this, reply]()
        {
            if(reply->error())
                qWarning() << reply->errorString();

            QByteArray data = reply->readAll();
            QJsonParseError jsonError;

            QJsonDocument document = QJsonDocument::fromJson(data, &jsonError);

            if(jsonError.error != QJsonParseError::NoError)
            {
                qWarning() << jsonError.errorString();
                return;
            }

            QJsonObject rootObject = document.object();

            if(rootObject.contains(QStringLiteral("prev_page")) && rootObject[QStringLiteral("prev_page")].isString())
                setPreviousPage(rootObject[QStringLiteral("prev_page")].toString());
            else
                setPreviousPage(QString());

            if(rootObject.contains(QStringLiteral("next_page")) && rootObject[QStringLiteral("next_page")].isString())
                setNextPage(rootObject[QStringLiteral("next_page")].toString());
            else
                setNextPage(QString());

            if(rootObject.contains(QStringLiteral("page")))
                setCurrentPage(rootObject[QStringLiteral("page")].toInt());
            else
                setCurrentPage(0);

            if(rootObject.contains(QStringLiteral("total_results")))
                setTotalResults(rootObject[QStringLiteral("total_results")].toInt());
            else
                setTotalResults(0);

            beginResetModel();
            m_data.clear();
            endResetModel();

            if(rootObject.contains(QStringLiteral("photos")) && rootObject[QStringLiteral("photos")].isArray())
            {
                QJsonArray photoArray = rootObject[QStringLiteral("photos")].toArray();

                beginInsertRows(QModelIndex(), 0, photoArray.count() - 1);

                for(const QJsonValue &photoRef : std::as_const(photoArray))
                {
                    if(!photoRef.isObject())
                        continue;

                    QJsonObject photoObject = photoRef.toObject();
                    PexelsImageMetadata photo;

                    photo.id = photoObject[QStringLiteral("id")].toInt();
                    photo.photographer = photoObject[QStringLiteral("photographer")].toString();
                    photo.photographerId = photoObject[QStringLiteral("photographer_id")].toInt();
                    photo.photographerUrl = QUrl(photoObject[QStringLiteral("photographer_url")].toString());
                    photo.averageColorCode = photoObject[QStringLiteral("avg_color")].toString();
                    photo.alt = photoObject[QStringLiteral("alt")].toString();
                    photo.width = photoObject[QStringLiteral("width")].toInt();
                    photo.height = photoObject[QStringLiteral("height")].toInt();
                    photo.url = QUrl(photoObject[QStringLiteral("url")].toString());
                    photo.liked = photoObject[QStringLiteral("liked")].toBool();

                    if(photoObject.contains(QStringLiteral("src")) && photoObject[QStringLiteral("src")].isObject())
                    {
                        QJsonObject sourceObject = photoObject[QStringLiteral("src")].toObject();
                        QStringList keys = sourceObject.keys();

                        for(const QString &key : std::as_const(keys))
                        {
                            if(key == QStringLiteral("tiny"))
                                photo.thumbnail = QUrl(sourceObject[key].toString());

                            photo.sources.insert(key, QUrl(sourceObject[key].toString()));
                        }
                    }

                    m_data.append(photo);
                }

                endInsertRows();
                setStatus(Idle);
            }
        }
    );
}

int PexelsImageSearchModel::status() const
{
    return static_cast<int>(m_status);
}

void PexelsImageSearchModel::setStatus(const int &status)
{
    if (m_status == static_cast<Status>(status))
        return;

    m_status = static_cast<Status>(status);
    Q_EMIT statusChanged();
}

QString PexelsImageSearchModel::lastSavedFile() const
{
    return m_lastSavedFile;
}

void PexelsImageSearchModel::setLastSavedFile(const QString &lastSavedFile)
{
    if (m_lastSavedFile == lastSavedFile)
        return;
    m_lastSavedFile = lastSavedFile;
    Q_EMIT lastSavedFileChanged();
}

qreal PexelsImageSearchModel::downloadProgress() const
{
    return m_downloadProgress;
}

void PexelsImageSearchModel::setDownloadProgress(qreal downloadProgress)
{
    if (m_downloadProgress == downloadProgress)
        return;
    m_downloadProgress = downloadProgress;
    Q_EMIT downloadProgressChanged();
}

quint64 PexelsImageSearchModel::currentPage() const
{
    return m_currentPage;
}

void PexelsImageSearchModel::setCurrentPage(quint64 currentPage)
{
    if (m_currentPage == currentPage)
        return;
    m_currentPage = currentPage;
    Q_EMIT currentPageChanged();
}

QModelIndex PexelsImageSearchModel::index(int row, int column, const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return createIndex(row, column, &m_data.at(row));
}

int PexelsImageSearchModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return 0;
}

QModelIndex PexelsImageSearchModel::parent(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return QModelIndex();
}

void PexelsImageSearchModel::next()
{
    if(m_nextPage.isEmpty())
        return;

    getSearchResults(m_nextPage);
}

void PexelsImageSearchModel::back()
{
    if(m_previousPage.isEmpty())
        return;

    getSearchResults(m_previousPage);
}

void PexelsImageSearchModel::download(QUrl url, quint64 id)
{
    QNetworkRequest request(url);
    QNetworkReply *reply = m_networkManager.get(request);

    QObject::connect
    (
        reply,
        &QNetworkReply::finished,
        this,
        [this, reply, id]()
        {
            if(reply->error())
                qWarning() << reply->errorString();

            QByteArray data = reply->readAll();
            QPixmap pixmap;
            pixmap.loadFromData(data);

            if(pixmap.isNull())
                return;

            QString fileLocation = QStringLiteral("%1/.local/share/komplex/images/%2.png").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation), QString::number(id));

            if(!pixmap.save(fileLocation, "PNG"))
                return;

            setLastSavedFile(fileLocation);

            Q_EMIT downloadFinished();
        }
    );

    QObject::connect
    (
        reply,
        &QNetworkReply::downloadProgress,
        this,
        [this](qint64 received, qint64 total)
        {
            setDownloadProgress(static_cast<qreal>(received) / static_cast<qreal>(total));
        }
    );
}

QString PexelsImageSearchModel::previousPage() const
{
    return m_previousPage;
}

void PexelsImageSearchModel::setPreviousPage(const QString &previousPage)
{
    if (m_previousPage == previousPage)
        return;
    m_previousPage = previousPage;
    Q_EMIT previousPageChanged();
}

QString PexelsImageSearchModel::nextPage() const
{
    return m_nextPage;
}

void PexelsImageSearchModel::setNextPage(const QString &nextPage)
{
    if (m_nextPage == nextPage)
        return;
    m_nextPage = nextPage;
    Q_EMIT nextPageChanged();
}

quint64 PexelsImageSearchModel::totalResults() const
{
    return m_totalResults;
}

void PexelsImageSearchModel::setTotalResults(quint64 totalResults)
{
    if (m_totalResults == totalResults)
        return;
    m_totalResults = totalResults;
    Q_EMIT totalResultsChanged();
}

quint16 PexelsImageSearchModel::resultsPerPage() const
{
    return m_resultsPerPage;
}

void PexelsImageSearchModel::setResultsPerPage(quint16 resultsPerPage)
{
    if (m_resultsPerPage == resultsPerPage)
        return;

    m_resultsPerPage = resultsPerPage;
    Q_EMIT resultsPerPageChanged();
}

QString PexelsImageSearchModel::query() const
{
    return m_query;
}

void PexelsImageSearchModel::setQuery(const QString &query)
{
    if (m_query == query)
        return;

    m_query = query;
    Q_EMIT queryChanged();

    getSearchResults(QStringLiteral("https://api.artifex.services/v1/images/search/%1/0/%2").arg(m_query).arg(m_resultsPerPage));
}
