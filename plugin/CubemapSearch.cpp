#include "CubemapSearch.h"

CubemapSearchModel::CubemapSearchModel(QObject *parent) : QAbstractItemModel { parent }
{
    m_networkManager.setAutoDeleteReplies(true);
}

CubemapSearchModel::~CubemapSearchModel()
{

}

int CubemapSearchModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_data.size();
}

QVariant CubemapSearchModel::data(const QModelIndex &index, int role) const
{
    if(index.row() < 0 || index.row() >= m_data.count())
        return QVariant();

    QVariant data;

    switch (static_cast<DataRoles>(role)) {
    case Description:
        data = QVariant::fromValue<QString>(m_data[index.row()].description);
        break;
    case Name:
        data = QVariant::fromValue<QString>(m_data[index.row()].name);
        break;
    case Thumbnail:
        data = QVariant::fromValue<QUrl>(m_data[index.row()].thumbnail);
        break;
    case Id:
        data = QVariant::fromValue<QString>(m_data[index.row()].id);
        break;
    }

    return data;
}

QHash<int, QByteArray> CubemapSearchModel::roleNames() const
{
    return m_dataRoles;
}

void CubemapSearchModel::getSearchResults(QString url)
{
    setStatus(Searching);

    QNetworkRequest request;
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

            if(rootObject.contains(QStringLiteral("total_results")))
                setTotalResults(rootObject[QStringLiteral("total_results")].toInt());
            else
                setTotalResults(0);

            if(currentOffset() > 0)
            {
                setPreviousPage(
                    QStringLiteral("https://api.artifex.services/v1/cubemaps/search/%1/%2/%3").arg(
                        query(),
                        std::clamp(
                            currentOffset() - resultsPerPage(), 
                            static_cast<quint64>(0), 
                            totalResults() - resultsPerPage()
                        ),
                        resultsPerPage()
                    )
                );
            }
            else
                setPreviousPage(QString());

            if((currentOffset() + resultsPerPage()) < totalResults())
            {
                setNextPage(
                    QStringLiteral("https://api.artifex.services/v1/cubemaps/search/%1/%2/%3").arg(
                        query(),
                        std::clamp(
                            currentOffset() + resultsPerPage(), 
                            static_cast<quint64>(0), 
                            totalResults() - resultsPerPage()
                        ),
                        resultsPerPage()
                    )
                );
            }
            else
                setNextPage(QString());

            beginResetModel();
            m_data.clear();
            endResetModel();

            if(rootObject.contains(QStringLiteral("results")) && rootObject[QStringLiteral("results")].isArray())
            {
                QJsonArray resultsArray = rootObject[QStringLiteral("results")].toArray();

                beginInsertRows(QModelIndex(), 0, resultsArray.count() - 1);

                for(const QJsonValue &resultRef : std::as_const(resultsArray))
                {
                    if(!resultRef.isObject())
                        continue;

                    QJsonObject resultObject = resultRef.toObject();
                    CubemapMetadata cubemap;
                    
                    cubemap.description = resultObject[QStringLiteral("description")].toString();
                    cubemap.id = resultObject[QStringLiteral("id")].toString();
                    cubemap.name = resultObject[QStringLiteral("name")].toString();
                    cubemap.thumbnail = QUrl(QStringLiteral("https://api.artifex.services/v1/cubemaps/thumbnail/%1").arg(resultObject[QStringLiteral("id")].toString()));
                    
                    m_data.append(cubemap);
                }

                endInsertRows();
            }

            setStatus(Idle);
        }
    );
}

int CubemapSearchModel::status() const
{
    return static_cast<int>(m_status);
}

void CubemapSearchModel::setStatus(const int &status, const QString &message)
{
    setStatusMessage(message);
    
    if (m_status == static_cast<Status>(status))
        return;

    m_status = static_cast<Status>(status);
    Q_EMIT statusChanged();
}

QString CubemapSearchModel::statusMessage() const
{
    return m_statusMessage;
}

void CubemapSearchModel::setStatusMessage(const QString &message)
{    
    if (m_statusMessage == message)
        return;

    m_statusMessage = message;
    Q_EMIT statusMessageChanged();
}

QString CubemapSearchModel::lastSavedFile() const
{
    return m_lastSavedFile;
}

void CubemapSearchModel::setLastSavedFile(const QString &lastSavedFile)
{
    if (m_lastSavedFile == lastSavedFile)
        return;
    m_lastSavedFile = lastSavedFile;
    Q_EMIT lastSavedFileChanged();
}

qreal CubemapSearchModel::downloadProgress() const
{
    return m_downloadProgress;
}

void CubemapSearchModel::setDownloadProgress(qreal downloadProgress)
{
    if (m_downloadProgress == downloadProgress)
        return;
    m_downloadProgress = downloadProgress;
    Q_EMIT downloadProgressChanged();
}

quint64 CubemapSearchModel::currentOffset() const
{
    return m_currentOffset;
}

void CubemapSearchModel::setCurrentOffset(quint64 currentPage)
{
    if (m_currentOffset == currentPage)
        return;
    m_currentOffset = currentPage;
    Q_EMIT currentOffsetChanged();
}

QModelIndex CubemapSearchModel::index(int row, int column, const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return createIndex(row, column, &m_data.at(row));
}

int CubemapSearchModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return 0;
}

QModelIndex CubemapSearchModel::parent(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return QModelIndex();
}

void CubemapSearchModel::next()
{
    if(m_nextPage.isEmpty())
        return;

    getSearchResults(m_nextPage);
}

void CubemapSearchModel::back()
{
    if(m_previousPage.isEmpty())
        return;

    getSearchResults(m_previousPage);
}

void CubemapSearchModel::download(QString id)
{
    QNetworkRequest request(QUrl(QStringLiteral("https://api.artifex.services/v1/cubemaps/item/%1").arg(id)));
    QNetworkReply *reply = m_networkManager.get(request);
    setStatus(Downloading);

    QObject::connect
    (
        reply,
        &QNetworkReply::finished,
        this,
        [this, reply, id]()
        {
            if(reply->error())
            {
                qWarning() << reply->errorString();
                setStatus(Error, QStringLiteral("Could not download resource %1").arg(id));
                return;
            }

            QByteArray data = reply->readAll();

            QString zipFileLocation = QStringLiteral("%1/.local/share/komplex/cubemaps/%2.zip").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation), id);
            QString fileLocation = QStringLiteral("%1/.local/share/komplex/cubemaps/%2").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation), id);
            QFile zipFile(zipFileLocation);

            if(zipFile.exists())
                zipFile.remove();
            
            if(!zipFile.open(QFile::ReadWrite))
            {
                qWarning() << "Could not open cubemap file:" << zipFileLocation;
                setStatus(Error, QStringLiteral("Could not open cubemap file"));
                return;
            }

            quint64 written = zipFile.write(data);

            if(written != data.length())
            {
                zipFile.close();

                qWarning() << "Could not write cubemap file:" << zipFileLocation;
                setStatus(Error, QStringLiteral("Could not open write file"));
                return;
            }

            zipFile.close();

            QStringList params {
                zipFileLocation,
                QStringLiteral("-d"),
                fileLocation
            };
            
            QProcess process;
            process.setProcessChannelMode(QProcess::MergedChannels);

            process.start(QStringLiteral("unzip"), params);

            if(!process.waitForStarted() || !process.waitForFinished())
            {
                QString message;

                switch(process.error())
                {
                    case QProcess::Crashed:
                        message = QStringLiteral("Unzip process crashed");
                    break;
                    case QProcess::FailedToStart:
                        message = QStringLiteral("Unzip process failed to start");
                    break;
                    case QProcess::Timedout:
                        message = QStringLiteral("Unzip process timedout");
                    break;
                    case QProcess::WriteError:
                        message = QStringLiteral("Unzip process crashed due to a write error");
                    break;
                    case QProcess::ReadError:
                        message = QStringLiteral("Unzip process crashed due to a read error");
                    break;
                    case QProcess::UnknownError:
                    default:
                        message = QStringLiteral("Unzip process crashed due to an unknown error");
                    break;
                }

                setStatus(Error, message);
            }

            qWarning() << process.errorString() << process.readAllStandardOutput();// << command;

            if(status() != Error)
            {
                setLastSavedFile(fileLocation);

                Q_EMIT downloadFinished();
            }

            setStatus(Idle);
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

QString CubemapSearchModel::previousPage() const
{
    return m_previousPage;
}

void CubemapSearchModel::setPreviousPage(const QString &previousPage)
{
    if (m_previousPage == previousPage)
        return;

    m_previousPage = previousPage;
    Q_EMIT previousPageChanged();
}

QString CubemapSearchModel::nextPage() const
{
    return m_nextPage;
}

void CubemapSearchModel::setNextPage(const QString &nextPage)
{
    if (m_nextPage == nextPage)
        return;
    m_nextPage = nextPage;
    Q_EMIT nextPageChanged();
}

quint64 CubemapSearchModel::totalResults() const
{
    return m_totalResults;
}

void CubemapSearchModel::setTotalResults(quint64 totalResults)
{
    if (m_totalResults == totalResults)
        return;
    m_totalResults = totalResults;
    Q_EMIT totalResultsChanged();
}

quint16 CubemapSearchModel::resultsPerPage() const
{
    return m_resultsPerPage;
}

void CubemapSearchModel::setResultsPerPage(quint16 resultsPerPage)
{
    if (m_resultsPerPage == resultsPerPage)
        return;

    m_resultsPerPage = resultsPerPage;
    Q_EMIT resultsPerPageChanged();
}

QString CubemapSearchModel::query() const
{
    return m_query;
}

void CubemapSearchModel::setQuery(const QString &query)
{
    if (m_query == query)
        return;

    m_query = query;
    Q_EMIT queryChanged();

    getSearchResults(QStringLiteral("https://api.artifex.services/v1/cubemaps/search/%1/0/%2").arg(m_query).arg(m_resultsPerPage));
}
