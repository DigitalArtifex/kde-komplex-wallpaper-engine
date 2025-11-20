#include "PexelsVideoSearch.h"
#include <qeventloop.h>

PexelsVideoSearchModel::PexelsVideoSearchModel(QObject *parent) : QAbstractItemModel { parent }
{
    // m_cache.setMaxCost(1024);
    m_videoModel = new PexelsVideoEntryModel(this);

    QObject::connect(m_videoModel, &PexelsVideoEntryModel::lastSavedFileChanged, this, &PexelsVideoSearchModel::lastSavedFileChanged);
}

PexelsVideoSearchModel::~PexelsVideoSearchModel()
{
    if(m_videoModel)
        m_videoModel->deleteLater();
}

int PexelsVideoSearchModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_data.size();
}

QVariant PexelsVideoSearchModel::data(const QModelIndex &index, int role) const
{
    if(index.row() < 0 || index.row() >= m_data.count())
        return QVariant();

    QVariant data;

    switch (static_cast<DataRoles>(role)) {
    case Tags:
        data = QVariant::fromValue(m_data[index.row()].tags);
        break;
    case Height:
        data = QVariant::fromValue(m_data[index.row()].height);
        break;
    case Id:
        data = QVariant::fromValue(m_data[index.row()].id);
        break;
    case User:
        data = QVariant::fromValue(m_data[index.row()].author.name);
        break;
    case UserId:
        data = QVariant::fromValue(m_data[index.row()].author.id);
        break;
    case UserUrl:
        data = QVariant::fromValue(m_data[index.row()].author.url);
        break;
    case Thumbnail:
        if(m_data[index.row()].thumbnails.count() > 0)
            data = QVariant::fromValue(m_data[index.row()].thumbnails[0].image);
        break;
    case Url:
        data = QVariant::fromValue(m_data[index.row()].url);
        break;
    case Width:
        data = QVariant::fromValue(m_data[index.row()].width);
        break;
    }

    return data;
}

QHash<int, QByteArray> PexelsVideoSearchModel::roleNames() const
{
    return m_dataRoles;
}

void PexelsVideoSearchModel::getSearchResults(QString url)
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

                if(rootObject.contains(QStringLiteral("videos")) && rootObject[QStringLiteral("videos")].isArray())
                {
                    QJsonArray videoArray = rootObject[QStringLiteral("videos")].toArray();

                    beginInsertRows(QModelIndex(), 0, videoArray.count() - 1);

                    for(const QJsonValue &videoRef : std::as_const(videoArray))
                    {
                        if(!videoRef.isObject())
                            continue;

                        QJsonObject videoObject = videoRef.toObject();
                        PexelsVideoEntry video;

                        video.id = videoObject[QStringLiteral("id")].toInt();
                        video.url = videoObject[QStringLiteral("url")].toString();
                        video.image = videoObject[QStringLiteral("image")].toString();
                        video.width = videoObject[QStringLiteral("width")].toInt();
                        video.height = videoObject[QStringLiteral("height")].toInt();
                        video.url = videoObject[QStringLiteral("url")].toString();
                        video.duration = videoObject[QStringLiteral("tags")].toInt();

                        if(videoObject.contains(QStringLiteral("tags")) && videoObject[QStringLiteral("tags")].isArray())
                        {
                            QJsonArray tagsArray = videoObject[QStringLiteral("tags")].toArray();

                            for(const QJsonValue &tagRef : std::as_const(tagsArray))
                                video.tags.append(tagRef.toString());
                        }

                        if(videoObject.contains(QStringLiteral("user")) && videoObject[QStringLiteral("user")].isObject())
                        {
                            QJsonObject userObject = videoObject[QStringLiteral("user")].toObject();
                            video.author.name = userObject[QStringLiteral("name")].toString();
                            video.author.id = userObject[QStringLiteral("id")].toInt();
                            video.author.url = userObject[QStringLiteral("url")].toString();
                        }

                        if(videoObject.contains(QStringLiteral("video_files")) && videoObject[QStringLiteral("video_files")].isArray())
                        {
                            QJsonArray sourceObject = videoObject[QStringLiteral("video_files")].toArray();

                            for(const QJsonValue &sourceObject : std::as_const(sourceObject))
                            {
                                QJsonObject metaObject = sourceObject.toObject();

                                PexelsVideoMetadata metadata;
                                metadata.fps = metaObject[QStringLiteral("fps")].toDouble();
                                metadata.height = metaObject[QStringLiteral("height")].toInt();
                                metadata.id = metaObject[QStringLiteral("id")].toInt();
                                metadata.link = metaObject[QStringLiteral("link")].toString();
                                metadata.quality = metaObject[QStringLiteral("quality")].toString();
                                metadata.type = metaObject[QStringLiteral("file_type")].toString();
                                metadata.width = metaObject[QStringLiteral("width")].toInt();

                                video.videos.append(metadata);
                            }
                        }

                        if(videoObject.contains(QStringLiteral("video_pictures")) && videoObject[QStringLiteral("video_pictures")].isArray())
                        {
                            QJsonArray sourceObject = videoObject[QStringLiteral("video_pictures")].toArray();

                            for(const QJsonValue &sourceObject : std::as_const(sourceObject))
                            {
                                QJsonObject metaObject = sourceObject.toObject();

                                struct PexelsVideoThumbnail metadata;
                                metadata.image = metaObject[QStringLiteral("picture")].toString();
                                metadata.nr = metaObject[QStringLiteral("nr")].toInt();
                                metadata.id = metaObject[QStringLiteral("id")].toInt();
                                video.thumbnails.append(metadata);
                            }
                        }

                        m_data.append(video);
                    }

                    endInsertRows();
                    setCurrentIndex(0);
                    setStatus(Idle);
                }
            }
        );
}

QString PexelsVideoSearchModel::sizeText(quint64 size)
{
    int index = 0;

    for(;index < m_sizeSuffix.count() && size >= 1000; index++)
        size /= 1000;

    return QStringLiteral("%1%2").arg(QString::number(size), m_sizeSuffix[index]);
}

quint64 PexelsVideoSearchModel::currentIndex() const
{
    return m_currentIndex;
}

void PexelsVideoSearchModel::setCurrentIndex(quint64 currentIndex)
{
    if (currentIndex < 0 || static_cast<qsizetype>(currentIndex) >= m_data.count())
    {
        m_videoModel->setMetadata(QList<PexelsVideoMetadata>());
        return;
    }

    m_videoModel->setMetadata(m_data[currentIndex].videos);

    m_currentIndex = currentIndex;
    Q_EMIT currentIndexChanged();
    Q_EMIT videoModelChanged();
}

PexelsVideoEntryModel *PexelsVideoSearchModel::videoModel() const
{
    return m_videoModel;
}

int PexelsVideoSearchModel::status() const
{
    return static_cast<int>(m_status);
}

void PexelsVideoSearchModel::setStatus(const int &status)
{
    if (m_status == static_cast<Status>(status))
        return;

    m_status = static_cast<Status>(status);
    Q_EMIT statusChanged();
}

QString PexelsVideoSearchModel::lastSavedFile() const
{
    return m_videoModel->lastSavedFile();
}

quint64 PexelsVideoSearchModel::currentPage() const
{
    return m_currentPage;
}

void PexelsVideoSearchModel::setCurrentPage(quint64 currentPage)
{
    if (m_currentPage == currentPage)
        return;
    m_currentPage = currentPage;
    Q_EMIT currentPageChanged();
}

QModelIndex PexelsVideoSearchModel::index(int row, int column, const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return createIndex(row, column, &m_data.at(row));
}

int PexelsVideoSearchModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return 0;
}

QModelIndex PexelsVideoSearchModel::parent(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return QModelIndex();
}

void PexelsVideoSearchModel::next()
{
    if(m_nextPage.isEmpty())
        return;

    getSearchResults(m_nextPage);
}

void PexelsVideoSearchModel::back()
{
    if(m_previousPage.isEmpty())
        return;

    getSearchResults(m_previousPage);
}

QString PexelsVideoSearchModel::previousPage() const
{
    return m_previousPage;
}

void PexelsVideoSearchModel::setPreviousPage(const QString &previousPage)
{
    if (m_previousPage == previousPage)
        return;
    m_previousPage = previousPage;
    Q_EMIT previousPageChanged();
}

QString PexelsVideoSearchModel::nextPage() const
{
    return m_nextPage;
}

void PexelsVideoSearchModel::setNextPage(const QString &nextPage)
{
    if (m_nextPage == nextPage)
        return;

    m_nextPage = nextPage;
    Q_EMIT nextPageChanged();
}

quint64 PexelsVideoSearchModel::totalResults() const
{
    return m_totalResults;
}

void PexelsVideoSearchModel::setTotalResults(quint64 totalResults)
{
    if (m_totalResults == totalResults)
        return;
    m_totalResults = totalResults;
    Q_EMIT totalResultsChanged();
}

quint16 PexelsVideoSearchModel::resultsPerPage() const
{
    return m_resultsPerPage;
}

void PexelsVideoSearchModel::setResultsPerPage(quint16 resultsPerPage)
{
    if (m_resultsPerPage == resultsPerPage)
        return;

    m_resultsPerPage = resultsPerPage;
    Q_EMIT resultsPerPageChanged();
}

QString PexelsVideoSearchModel::query() const
{
    return m_query;
}

void PexelsVideoSearchModel::setQuery(const QString &query)
{
    if (m_query == query)
        return;

    m_query = query;
    Q_EMIT queryChanged();
    
    getSearchResults(QStringLiteral("https://api.artifex.services/v1/videos/search/%1/0/%2").arg(m_query).arg(m_resultsPerPage));
}
