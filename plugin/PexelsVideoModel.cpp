#include "PexelsVideoModel.h"
#include <qeventloop.h>

PexelsVideoEntryModel::PexelsVideoEntryModel(QObject *parent)
    : QAbstractItemModel{parent}
{
    m_networkManager.setAutoDeleteReplies(true);
}

int PexelsVideoEntryModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_data.size();
}

QVariant PexelsVideoEntryModel::data(const QModelIndex &index, int role) const
{
    if(index.row() < 0 || index.row() >= m_data.count())
        return QVariant();

    QVariant data;

    switch (static_cast<DataRoles>(role)) 
    {
    case Fps:
        data = QVariant::fromValue(m_data[index.row()].fps);
        break;
    case Height:
        data = QVariant::fromValue(m_data[index.row()].height);
        break;
    case Id:
        data = QVariant::fromValue(m_data[index.row()].id);
        break;
    case Url:
        data = QVariant::fromValue(m_data[index.row()].link);
        break;
    case Width:
        data = QVariant::fromValue(m_data[index.row()].width);
        break;
    case Type:
        data = QVariant::fromValue(m_data[index.row()].type);
        break;
    case Quality:
        data = QVariant::fromValue(m_data[index.row()].quality);
        break;
    case Text:
        data = QVariant::fromValue(QStringLiteral("%1 %2x%3 (%4)").arg(m_data[index.row()].quality.toUpper(),QString::number(m_data[index.row()].width),QString::number(m_data[index.row()].height),m_data[index.row()].sizeText));
        break;
    case Size:
        data = QVariant::fromValue(m_data[index.row()].size);
        break;
    }

    return data;
}

QHash<int, QByteArray> PexelsVideoEntryModel::roleNames() const
{
    return m_dataRoles;
}

PexelsVideoEntryModel::Status PexelsVideoEntryModel::status() const
{
    return m_status;
}

void PexelsVideoEntryModel::setStatus(const Status &status)
{
    if (m_status == status)
        return;
    m_status = status;
    Q_EMIT statusChanged();
}

QModelIndex PexelsVideoEntryModel::index(int row, int column, const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return createIndex(row, column, &m_data.at(row));
}

int PexelsVideoEntryModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return 0;
}

QModelIndex PexelsVideoEntryModel::parent(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return QModelIndex();
}

void PexelsVideoEntryModel::setMetadata(const QList<PexelsVideoMetadata> &data)
{
    beginResetModel();
    m_data.clear();
    endResetModel();

    beginInsertRows(QModelIndex(), 0, data.count() - 1);
    m_data = data;
    endInsertRows();
}

bool PexelsVideoEntryModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if(index.row() < 0 || index.row() >= m_data.count())
        return false;

    PexelsVideoMetadata entry = m_data[index.row()];

    switch(static_cast<DataRoles>(role))
    {
    case Fps:
        entry.fps = value.toDouble();
        break;
    case Height:
        entry.height = value.toInt();
        break;
    case Id:
        entry.id = value.toInt();
        break;
    case Url:
        entry.link = value.toString();
        break;
    case Width:
        entry.width = value.toInt();
        break;
    case Type:
        entry.type = value.toString();
        break;
    case Quality:
        entry.quality = value.toString();
        break;
    case Text:
        break;
    case Size:
        entry.size = value.toInt();
        break;
    }

    beginInsertRows(index, index.row(), index.row());
    m_data.replace(index.row(), entry);
    endInsertRows();

    return true;
}

void PexelsVideoEntryModel::download(quint64 index)
{
    QNetworkRequest request(QUrl(m_data[index].link));
    QNetworkReply *reply = m_networkManager.get(request);

    QObject::connect
    (
        reply,
        &QNetworkReply::finished,
        this,
        [this, reply, index]()
        {
            if(reply->error())
                qWarning() << reply->errorString();

            QByteArray data = reply->readAll();
            QString fileLocation = QStringLiteral("%1/.local/share/komplex/videos/%2.%3").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation), QString::number(m_data[index].id), m_data[index].type.mid(m_data[index].type.lastIndexOf(QLatin1Char('/')) + 1));
            QFile file(fileLocation);

            if(!file.open(QFile::WriteOnly))
            {
                qWarning() << QStringLiteral("Could not download file");
                return;
            }

            qint64 bytesWritten = file.write(data);

            if(static_cast<qsizetype>(bytesWritten) != data.length())
                qWarning() << QStringLiteral("Could not save file. %1 of %2").arg(bytesWritten).arg(data.length());

            file.close();

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

void PexelsVideoEntryModel::update()
{
    setStatus(Loading);

    for(int i = 0; i < m_data.count(); ++i)
    {
        m_data[i].size = getFileSize(QUrl(m_data[i].link));
        m_data[i].sizeText = sizeText(m_data[i].size);
        QThread::msleep(100);
    }

    setStatus(Idle);
}

qreal PexelsVideoEntryModel::downloadProgress() const
{
    return m_downloadProgress;
}

void PexelsVideoEntryModel::setDownloadProgress(qreal downloadProgress)
{
    if (qFuzzyCompare(m_downloadProgress, downloadProgress))
        return;
    m_downloadProgress = downloadProgress;
    Q_EMIT downloadProgressChanged();
}

QString PexelsVideoEntryModel::lastSavedFile() const
{
    return m_lastSavedFile;
}

void PexelsVideoEntryModel::setLastSavedFile(const QString &lastSavedFile)
{
    if (m_lastSavedFile == lastSavedFile)
        return;

    m_lastSavedFile = lastSavedFile;
    Q_EMIT lastSavedFileChanged();
}

quint64 PexelsVideoEntryModel::getFileSize(QUrl url)
{
    quint64 size = 0;

    QEventLoop loop;

    QNetworkRequest request;
    request.setUrl(url);

    QNetworkReply *reply = m_networkManager.head(request);
    QObject::connect(
        reply,
        &QNetworkReply::finished,
        this,
        [reply, &loop, &size]()
        {
            if(reply->error())
            {
                qWarning() << QStringLiteral("Failed to download header for file size");
                return;
            }

            if(reply->hasRawHeader(QStringLiteral("Content-Length")))
            {
                QByteArray headerData = reply->rawHeader(QStringLiteral("Content-Length"));

                if(!headerData.isValidUtf8())
                {
                    qWarning() << QStringLiteral("Invalid header data format");
                    return;
                }

                QString data = QString::fromUtf8(headerData);
                size = data.toInt();
            }

            loop.quit();
        }
    );

    if(!reply->isFinished())
        loop.exec();

    return size;
}

QString PexelsVideoEntryModel::sizeText(quint64 size)
{
    int index = 0;

    for(;index < m_sizeSuffix.count() && size >= 1000; index++)
        size /= 1000;

    return QStringLiteral("%1%2").arg(QString::number(size), m_sizeSuffix[index]);
}
