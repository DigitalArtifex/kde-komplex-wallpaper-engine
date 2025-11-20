#include "KomplexSearchModel.h"
#include <qeventloop.h>

KomplexSearchModel::KomplexSearchModel(QObject *parent)
    : QAbstractItemModel{parent}
{
    m_networkManager.setAutoDeleteReplies(true);
}

QVariant KomplexSearchModel::data(const QModelIndex &index, int role) const
{
    if(index.row() < 0 || index.row() >= m_data.count())
        return QVariant();

    QVariant data;

    switch (static_cast<DataRoles>(role))
    {
        case Date:
            data = QVariant::fromValue(m_data[index.row()].metadata.date);
            break;
        case Description:
            data = QVariant::fromValue(m_data[index.row()].metadata.description);
            break;
        case EmbedUrl:
            data = QVariant::fromValue(QStringLiteral("https://www.shadertoy.com/embed/%1").arg(m_data[index.row()].metadata.id));
            break;
        case Flags:
            data = QVariant::fromValue(m_data[index.row()].metadata.flags);
            break;
        case HasLiked:
            data = QVariant::fromValue(m_data[index.row()].metadata.hasLiked);
            break;
        case Id:
            data = QVariant::fromValue(m_data[index.row()].metadata.id);
            break;
        case Likes:
            data = QVariant::fromValue(m_data[index.row()].metadata.likes);
            break;
        case Name:
            data = QVariant::fromValue(m_data[index.row()].metadata.name);
            break;
        case Published:
            data = QVariant::fromValue(m_data[index.row()].metadata.published);
            break;
        case Tags:
            data = QVariant::fromValue(m_data[index.row()].metadata.tags);
            break;
        case Thumbnail:
            data = QVariant::fromValue(QStringLiteral("https://www.shadertoy.com/media/shaders/%1.jpg").arg(m_data[index.row()].metadata.id));
            break;
        case UsePreview:
            data = QVariant::fromValue(m_data[index.row()].metadata.usePreview);
            break;
        case Username:
            data = QVariant::fromValue(m_data[index.row()].metadata.username);
            break;
        case Version:
            data = QVariant::fromValue(m_data[index.row()].metadata.version);
            break;
        case Views:
            data = QVariant::fromValue(m_data[index.row()].metadata.views);
            break;
        case State:
            data = QVariant::fromValue(m_data[index.row()].status);
            break;
        }

    return data;
}

QHash<int, QByteArray> KomplexSearchModel::roleNames() const
{
    return m_dataRoles;
}

void KomplexSearchModel::downloadMedia(QString fileLocation, QString fileUrl)
{
    QUrl remoteUrl(QStringLiteral("http://api.artifex.services/v1%2").arg(fileUrl));
    QNetworkRequest request(remoteUrl);
    QNetworkReply *reply = m_manager.get(request);

    QEventLoop loop;

    QObject::connect
    (
        reply,
        &QNetworkReply::finished,
        this,
        [this, reply, fileLocation, fileUrl]()
        {
            if(reply->error())
            {
                qWarning() << reply->errorString();
                setDownloadText(reply->errorString());
                return;
            }

            QByteArray headerData = reply->rawHeader(QStringLiteral("Content-Type"));

            if(!headerData.isValidUtf8())
            {
                qWarning() << QStringLiteral("Header data is not valid UTF8 data");
                return;
            }

            QString type = QString::fromUtf8(headerData);

            if(!type.startsWith(QStringLiteral("image/")))
            {
                qWarning() << QStringLiteral("Downloaded content is not an image").arg(type.toUpper());
                setDownloadText(QStringLiteral("Downloaded content is not an image").arg(type.toUpper()));
                return;
            }

            QFile file(fileLocation);
            QByteArray data = reply->readAll();

            if(!file.open(QFile::ReadWrite))
            {
                qWarning() << QStringLiteral("Could not open file to download").arg(type.toUpper());
                setDownloadText(QStringLiteral("Could not open file to download").arg(type.toUpper()));
                return;
            }

            if(file.write(data) != data.length())
            {
                file.close();
                qWarning() << QStringLiteral("Could not write file to download").arg(type.toUpper());
                setDownloadText(QStringLiteral("Could not write file to download").arg(type.toUpper()));
                return;
            }

            file.close();
            
            // This is causing errors on JPG format, but JPEG is fine

            // type.remove(QStringLiteral("image/"));

            // QPixmap pixmap;
            // pixmap.loadFromData(reply->readAll(), type.toUpper().toStdString().c_str());

            // if(pixmap.isNull())
            // {
            //     qWarning() << QStringLiteral("Media format (%1) is not supported").arg(type.toUpper());
            //     setDownloadText(QStringLiteral("Media format (%1) is not supported").arg(type.toUpper()));
            //     return;
            // }

            // pixmap.save(fileLocation, type.toUpper().toStdString().c_str());

            setDownloadText(QStringLiteral("Downloaded %1").arg(fileUrl));
            setCompletedDownloads(completedDownloads() + 1);
        }
    );
}

void KomplexSearchModel::compile(quint64 index)
{
    setStatus(Compiling, QStringLiteral("Compiling Shader"));

    ShaderToyEntry entry = m_data[index];

    QDir localToolsDirectory(QStringLiteral("%1/.local/share/komplex/tools").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation)));
    QString inputDirectory = QStringLiteral("%1/komplex/src/%2").arg(QStandardPaths::writableLocation(QStandardPaths::TempLocation), entry.metadata.id);
    QString outputDirectory = QStringLiteral("%1/komplex/build").arg(QStandardPaths::writableLocation(QStandardPaths::TempLocation));
    QString shaderPackDirectory = QStringLiteral("%1/komplex/build/%2").arg(QStandardPaths::writableLocation(QStandardPaths::TempLocation), entry.metadata.id);

    QStringList arguments =
    {
        localToolsDirectory.absoluteFilePath(QStringLiteral("stc.py")),
        QStringLiteral("-i"),
        inputDirectory,
        QStringLiteral("-o"),
        outputDirectory
    };

    if(!QFile::exists(localToolsDirectory.absoluteFilePath(QStringLiteral("stc.py"))))
    {
        setStatus(Error, QStringLiteral("Shader Compiler is not installed at %1").arg(localToolsDirectory.absoluteFilePath(QStringLiteral("stc.py"))));
        return;
    }

    QProcess *process = new QProcess(this);

    QObject::connect
    (
        process,
        &QProcess::readyReadStandardOutput,
        this,
        [this, process]()
        {
            QByteArray processData = process->readAllStandardOutput();

            if(!processData.isValidUtf8())
            {
                qWarning() << QStringLiteral("Process output not valid UTF8 data");
                return;
            }

            setCompilerOutput(m_compilerOutput + QString::fromUtf8(processData));
        }
    );

    QObject::connect
    (
        process,
        &QProcess::readyReadStandardError,
        this,
        [this, process]()
        {
            QByteArray processData = process->readAllStandardError();

            if(!processData.isValidUtf8())
            {
                qWarning() << QStringLiteral("Process output not valid UTF8 data");
                return;
            }

            setCompilerErrorOutput(m_compilerOutput + QString::fromUtf8(processData));
        }
    );

    process->start(QStringLiteral("python3"), arguments);

    if(!process->waitForStarted(3000))
    {
        qWarning() << process->readAll();
        setStatus(Error, QStringLiteral("Could not start shader compiler"));

        process->deleteLater();
        return;
    }

    if(!process->waitForFinished())
    {
        qWarning() << process->readAll();
        setStatus(Error, QStringLiteral("Shader compiler timeout"));

        process->deleteLater();
        return;
    }

    if(process->exitCode() != 0)
    {
        qWarning() << process->readAll();
        setStatus(Error, QStringLiteral("Shader compiler error"));

        process->deleteLater();
        return;
    }

    qWarning() << process->readAll();
    process->deleteLater();
}

void KomplexSearchModel::save(quint64 index)
{
    ShaderToyEntry entry = m_data[index];

    setStatus(Compiling, QStringLiteral("Saving shader data"));
    setCompletedDownloads(0);
    setTotalDownloads(0);

    QString directoryLocation = QStringLiteral("%1/komplex/src/%2").arg(QStandardPaths::writableLocation(QStandardPaths::TempLocation), entry.metadata.id);
    QDir directory(directoryLocation);

    if(!directory.exists())
    {
        directory.mkpath(directoryLocation + QStringLiteral("/shaders"));
        directory.mkpath(directoryLocation + QStringLiteral("/images"));
        directory.mkpath(directoryLocation + QStringLiteral("/videos"));
    }

    QDir shaderDirectory(directoryLocation + QStringLiteral("/shaders"));
    QDir imageDirectory(directoryLocation + QStringLiteral("/images"));
    // QDir videoDirectory(directoryLocation + QStringLiteral("/videos"));

    QJsonObject rootObject;
    rootObject[QStringLiteral("author")] = entry.metadata.username;
    rootObject[QStringLiteral("name")] = entry.metadata.name;
    rootObject[QStringLiteral("version")] = entry.metadata.version;
    rootObject[QStringLiteral("engine")] = QStringLiteral("shadertoy");
    rootObject[QStringLiteral("description")] = entry.metadata.description;
    rootObject[QStringLiteral("id")] = entry.metadata.id;
    rootObject[QStringLiteral("tags")] = QJsonArray::fromStringList(entry.metadata.tags);
    QMap<QString,QString> externalMedia;

    externalMedia.insert
    (
        directory.absoluteFilePath(QStringLiteral("thumbnail.jpg")),
        QStringLiteral("/media/shaders/%1.jpg").arg(entry.metadata.id)
    );

    for(const ShaderToyRenderPass &pass : std::as_const(entry.renderPasses))
    {
        // skip tone generators
        if(pass.type == QStringLiteral("sound"))
            continue;

        QString passName = pass.name;

        if(passName.contains(QStringLiteral("Buf")) && !passName.contains(QStringLiteral("Buffer")))
            passName.replace(QStringLiteral("Buf"), QStringLiteral("Buffer"));

        QFile shaderFile(shaderDirectory.absoluteFilePath(passName + QStringLiteral(".frag")));

        if(!shaderFile.open(QFile::WriteOnly))
        {
            qWarning() << QStringLiteral("Could not open shader file for saving");
            return;
        }

        if(shaderFile.write(pass.code) != pass.code.length())
        {
            qWarning() << QStringLiteral("Could not write shader file data");
            shaderFile.close();
            return;
        }

        shaderFile.close();

        //this is the common file
        if(pass.type == QStringLiteral("common"))
            continue; // wont have any inputs

        const ShaderToyRenderOutput *channelOutput = nullptr;

        for(const ShaderToyRenderOutput &output : std::as_const(pass.outputs))
        {
            if(output.channel == 0)
            {
                channelOutput = &output;
                break;
            }
        }

        QList<QJsonObject> channels(4);

        QJsonObject *passObject = nullptr;

        //this is the root shader
        if(pass.type == QStringLiteral("image"))
        {
            rootObject[QStringLiteral("source")] = QStringLiteral("./shaders/%1.frag.qsb").arg(pass.name);
            passObject = &rootObject;
        }
        else
            passObject = new QJsonObject;

        for(const ShaderToyRenderInput &input : std::as_const(pass.inputs))
        {
            /*
            * Only recursive buffers, images, videos and shader buffers are currently supported.
            * audio will default to audio capture
            */

            if(!m_supportedChannelTypes.contains(input.ctype))
            {
                qWarning() << input.ctype << QStringLiteral(" is not a valid channel type");
                continue;
            }

            // recursive buffer reference
            if(channelOutput && input.id == channelOutput->id)
            {
                passObject->insert(QStringLiteral("frame_buffer_channel"), input.channel);
                continue;
            }

            if(input.ctype == QStringLiteral("buffer"))
            {
                // get input reference by id
                const ShaderToyRenderPass *inputPass = nullptr;

                for(const ShaderToyRenderPass &passSubScan : std::as_const(entry.renderPasses))
                {
                    for(const ShaderToyRenderOutput &output : std::as_const(passSubScan.outputs))
                    {
                        if(output.id == input.id && output.channel == 0)
                        {
                            inputPass = &passSubScan;
                            break;
                        }

                        if(inputPass)
                            break;
                    }
                }

                //whoopsie
                if(!inputPass)
                    continue;

                QString name = inputPass->name.toCaseFolded();
                name.replace(name.length() - 1, 1, name.right(1).toUpper());
                name.remove(QLatin1Char(' '));
                name.replace(QStringLiteral("buf"), QStringLiteral("buffer"));

                channels[input.channel][QStringLiteral("source")] = QStringLiteral("{%1}").arg(name);
            }

            else if(input.ctype == QStringLiteral("audio"))
                channels[input.channel][QStringLiteral("type")] = 4;

            else if(input.ctype == QStringLiteral("texture"))
            {
                QString filename = input.source;
                filename = filename.mid(filename.lastIndexOf(QLatin1Char('/')) + 1);

                channels[input.channel][QStringLiteral("type")] = 0;
                channels[input.channel][QStringLiteral("source")] = QStringLiteral("./images/%1").arg(filename);

                externalMedia.insert(imageDirectory.absoluteFilePath(filename), input.source);
            }

            //select video file after compilation
            else if(input.ctype == QStringLiteral("video"))
            {
                //set the channel source to a uuid then add that uuid to the video
                // selection stringlist
                QString sourceName = QUuid::createUuidV7().toString();
                channels[input.channel][QStringLiteral("type")] = 1;
                channels[input.channel][QStringLiteral("source")] = sourceName;

                QStringList newSelections = m_videoSelections;
                newSelections += sourceName;

                setVideoSelections(newSelections);
            }

            channels[input.channel][QStringLiteral("filter")] = input.filter;
            channels[input.channel][QStringLiteral("wrap")] = input.wrap;
            channels[input.channel][QStringLiteral("invert")] = input.verticalFlip;
            channels[input.channel][QStringLiteral("srgb")] = input.srgb;
            channels[input.channel][QStringLiteral("internal")] = input.internal;
        }

        for(int i = 0; i < 4; ++i)
        {
            if(channels[i].isEmpty())
                continue;

            passObject->insert(QStringLiteral("channel%1").arg(i), channels[i]);
        }

        //this is a buffer
        if(pass.type == QStringLiteral("buffer"))
        {
            QString name = pass.name.toCaseFolded();
            name.replace(name.length() - 1, 1, name.right(1).toUpper());
            name.remove(QLatin1Char(' '));
            name.replace(QStringLiteral("buf"), QStringLiteral("buffer"));
            passObject->insert(QStringLiteral("source"), QStringLiteral("./shaders/%1.frag.qsb").arg(passName));

            rootObject[name] = *passObject;
        }

        if(*passObject != rootObject)
            delete passObject;
    }

    QFile shaderPackFile(directory.absoluteFilePath(QStringLiteral("pack.json")));

    if(!shaderPackFile.open(QFile::WriteOnly))
    {
        qWarning() << QStringLiteral("Could not open pack file");
        return;
    }

    QJsonDocument packDocument;
    packDocument.setObject(rootObject);

    QByteArray jsonData = packDocument.toJson(QJsonDocument::Indented);

    if(shaderPackFile.write(jsonData) != jsonData.length())
    {
        qWarning() << QStringLiteral("Could not write pack data");
        return;
    }

    const QStringList keys = externalMedia.keys();

    qWarning() << QStringLiteral("Downloading %1 Images").arg(externalMedia.count());

    setStatus(Compiling, QStringLiteral("Downloading images"));

    setTotalDownloads(externalMedia.count());

    for(const QString &key : keys)
        downloadMedia(key, externalMedia[key]);
}

void KomplexSearchModel::install(quint64 index)
{
    ShaderToyEntry entry = m_data[index];

    setStatus(Finalizing, QStringLiteral("Installing Shader"));
    setCompletedDownloads(0);
    setTotalDownloads(0);

    QString tempLocation = QStringLiteral("%1/komplex/build/%2").arg(QStandardPaths::writableLocation(QStandardPaths::TempLocation), entry.metadata.id);
    QString installLocation = QStringLiteral("%1/.local/share/komplex/packs/%2").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation), entry.metadata.id);

    QDir installDirectory(installLocation);

    if(installDirectory.exists())
        installDirectory.removeRecursively();

    QProcess process;

    QObject::connect
    (
        &process,
        &QProcess::readyReadStandardOutput,
        this,
        [this, &process]()
        {
            QByteArray processData = process.readAllStandardOutput();

            if(!processData.isValidUtf8())
            {
                qWarning() << QStringLiteral("Process output not valid UTF8 data");
                return;
            }

            setCompilerOutput(m_compilerOutput + QString::fromUtf8(processData));
        }
    );

    QObject::connect
    (
        &process,
        &QProcess::readyReadStandardError,
        this,
        [this, &process]()
        {
            QByteArray processData = process.readAllStandardError();

            if(!processData.isValidUtf8())
            {
                qWarning() << QStringLiteral("Process output not valid UTF8 data");
                return;
            }

            setCompilerErrorOutput(m_compilerOutput + QString::fromUtf8(processData));
        }
    );

    QStringList arguments = QStringList { QStringLiteral("-R"), tempLocation, installLocation};
    process.start(QStringLiteral("cp"), arguments);

    if(!process.waitForStarted(3000))
    {
        qWarning() << QStringLiteral("Could not start copy process: %1").arg(process.readAllStandardError());
        setStatus(Error, QStringLiteral("Could not start install process"));
        return;
    }

    if(!process.waitForFinished())
    {
        qWarning() << QStringLiteral("Copy process took longer than expected (>30s)");
        setStatus(Error, QStringLiteral("Install process took longer than expected (>30s)"));
        return;
    }
}

void KomplexSearchModel::download(quint64 index)
{
    ShaderToyEntry entry = m_data[index];
    entry.status = ShaderToyEntry::Loading;
    m_data[index] = entry;

    QModelIndex modelIndex = this->index(index, 0);
    Q_EMIT dataChanged(modelIndex, modelIndex);

    setStatus(Loading, QStringLiteral("Downloading Metadata"));
    QString id = entry.metadata.id;

    QUrl url(QStringLiteral("https://api.artifex.services/v1/shaders/item/%1").arg(entry.metadata.id));
    QNetworkReply *reply = m_manager.get(QNetworkRequest(url));

    QObject::connect
    (
        reply,
        &QNetworkReply::finished,
        this,
        [this, reply, index, id]
        {
            if(reply->error())
            {
                setStatus(Error, QStringLiteral("Network Error %1:\n %2\n %3").arg(id, reply->errorString(), QStringLiteral("https://api.komplex.services/v1/shaders/item/")));
                return;
            }

            QByteArray data = reply->readAll();
            QJsonParseError jsonError;

            QJsonDocument document = QJsonDocument::fromJson(data, &jsonError);

            if(jsonError.error != QJsonParseError::NoError)
            {
                qWarning() << jsonError.errorString();
                setStatus(Error, jsonError.errorString());
                return;
            }

            QJsonObject documentObject = document.object();
            QJsonObject rootObject = documentObject[QStringLiteral("Shader")].toObject();
            QJsonObject infoObject = rootObject[QStringLiteral("info")].toObject();
            QJsonArray tagsArray = infoObject[QStringLiteral("tags")].toArray();

            QStringList tags;

            for(const QJsonValue &tag : std::as_const(tagsArray))
                tags += tag.toString();

            ShaderToyEntry entry = m_data[index];

            entry.metadata = ShaderToyMetadata
            {
                QDateTime::fromSecsSinceEpoch(infoObject[QStringLiteral("date")].toInt()),
                infoObject[QStringLiteral("description")].toString(),
                static_cast<quint64>(infoObject[QStringLiteral("flags")].toInt()),
                static_cast<bool>(infoObject[QStringLiteral("hasLiked")].toInt()),
                infoObject[QStringLiteral("id")].toString(),
                static_cast<quint64>(infoObject[QStringLiteral("likes")].toInt()),
                infoObject[QStringLiteral("name")].toString(),
                static_cast<quint64>(infoObject[QStringLiteral("published")].toInt()),
                tags,
                static_cast<bool>(infoObject[QStringLiteral("usePreview")].toInt()),
                infoObject[QStringLiteral("username")].toString(),
                rootObject[QStringLiteral("ver")].toString(),
                static_cast<quint64>(infoObject[QStringLiteral("views")].toInt())
            };

            QJsonArray ShaderToyRenderPassArray = rootObject[QStringLiteral("renderpass")].toArray();

            for(const QJsonValue &ShaderToyRenderPassValue : std::as_const(ShaderToyRenderPassArray))
            {
                QJsonArray inputArray = ShaderToyRenderPassValue[QStringLiteral("inputs")].toArray();
                QJsonArray outputArray = ShaderToyRenderPassValue[QStringLiteral("outputs")].toArray();
                QList<ShaderToyRenderInput> inputs;
                QList<ShaderToyRenderOutput> outputs;

                for(const QJsonValue &inputValue : std::as_const(inputArray))
                {
                    QJsonObject samplerObject = inputValue[QStringLiteral("sampler")].toObject();
                    inputs.append
                    (
                        ShaderToyRenderInput
                        {
                            static_cast<quint8>(inputValue[QStringLiteral("channel")].toInt()),
                            inputValue[QStringLiteral("ctype")].toString(),
                            samplerObject[QStringLiteral("filter")].toString(),
                            static_cast<quint64>(inputValue[QStringLiteral("id")].toInt()),
                            samplerObject[QStringLiteral("internal")].toString(),
                            static_cast<bool>(inputValue[QStringLiteral("published")].toInt()),
                            inputValue[QStringLiteral("src")].toString(),
                            samplerObject[QStringLiteral("srgb")].toBool(),
                            samplerObject[QStringLiteral("verticalFlip")].toBool(),
                            samplerObject[QStringLiteral("wrap")].toString()
                        }
                    );
                }

                for(const QJsonValue &outputValue : std::as_const(outputArray))
                {
                    outputs.append
                    (
                        ShaderToyRenderOutput
                        {
                            static_cast<quint8>(outputValue[QStringLiteral("channel")].toInt()),
                            static_cast<quint64>(outputValue[QStringLiteral("id")].toInt())
                        }
                    );
                }

                entry.renderPasses.append
                (
                    ShaderToyRenderPass
                    {
                        ShaderToyRenderPassValue[QStringLiteral("code")].toVariant().toByteArray(),
                        ShaderToyRenderPassValue[QStringLiteral("description")].toString(),
                        inputs,
                        ShaderToyRenderPassValue[QStringLiteral("name")].toString(),
                        outputs,
                        ShaderToyRenderPassValue[QStringLiteral("type")].toString()
                    }
                );
            }

            entry.status = ShaderToyEntry::Idle;

            m_data.replace(index, entry);

            QModelIndex modelIndex = this->index(index, 0);
            Q_EMIT dataChanged(modelIndex, modelIndex);

            convert(index);
        }
    );
}

void KomplexSearchModel::resetModel()
{
    beginResetModel();
    m_data.clear();
    endResetModel();
}

KomplexSearchModel::Status KomplexSearchModel::status() const
{
    return m_status;
}

void KomplexSearchModel::setStatus(const Status &status, const QString &message)
{
    setStatusMessage(message);

    if (m_status == status)
        return;

    if(status == Error && !message.isEmpty())
        qWarning() << message;

    m_status = status;
    Q_EMIT statusChanged();
}

QModelIndex KomplexSearchModel::index(int row, int column, const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return createIndex(row, column, &m_data.at(row));
}

int KomplexSearchModel::columnCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return 0;
}

QModelIndex KomplexSearchModel::parent(const QModelIndex &index) const
{
    Q_UNUSED(index)
    return QModelIndex();
}

bool KomplexSearchModel::setData(const QModelIndex &index, const QVariant &value, int role)
{
    if(index.row() < 0 || index.row() >= m_data.count())
        return false;

    ShaderToyEntry entry = m_data[index.row()];

    switch (static_cast<DataRoles>(role))
    {
        case Date:
            entry.metadata.date = value.toDateTime();
            break;
        case Description:
            entry.metadata.description = value.toString();
            break;
        case EmbedUrl:
            break;
        case Flags:
            entry.metadata.flags = value.toInt();
            break;
        case HasLiked:
            entry.metadata.hasLiked = value.toBool();
            break;
        case Id:
            entry.metadata.id = value.toString();
            break;
        case Likes:
            entry.metadata.likes = value.toInt();
            break;
        case Name:
            entry.metadata.name = value.toString();
            break;
        case Published:
            entry.metadata.published = value.toBool();
            break;
        case Tags:
            entry.metadata.tags = value.toStringList();
            break;
        case Thumbnail:
            break;
        case UsePreview:
            entry.metadata.usePreview = value.toBool();
            break;
        case Username:
            entry.metadata.username = value.toString();
            break;
        case Version:
            entry.metadata.version = value.toString();
            break;
        case Views:
            entry.metadata.views = value.toInt();
            break;
        case State:
            break;
        }

        beginInsertRows(QModelIndex(), index.row(), index.row());
        m_data.replace(index.row(), entry);
        endInsertRows();

        return true;
}

QString KomplexSearchModel::lastSavedFile() const
{
    return m_lastSavedFile;
}

void KomplexSearchModel::setLastSavedFile(const QString &lastSavedFile)
{
    if (m_lastSavedFile == lastSavedFile)
        return;

    m_lastSavedFile = lastSavedFile;
    Q_EMIT lastSavedFileChanged();
}

QStringList KomplexSearchModel::videoSelections() const
{
    return m_videoSelections;
}

void KomplexSearchModel::setVideoSelections(const QStringList &videoSelections)
{
    if (m_videoSelections == videoSelections)
        return;
    m_videoSelections = videoSelections;
    Q_EMIT videoSelectionsChanged();
}

QString KomplexSearchModel::statusMessage() const
{
    return m_statusMessage;
}

void KomplexSearchModel::setStatusMessage(const QString &statusMessage)
{
    if (m_statusMessage == statusMessage)
        return;

    m_statusMessage = statusMessage;
    Q_EMIT statusMessageChanged();
}

QString KomplexSearchModel::downloadText() const
{
    return m_downloadText;
}

void KomplexSearchModel::setDownloadText(const QString &downloadText)
{
    if (m_downloadText == downloadText)
        return;
    m_downloadText = downloadText;
    Q_EMIT downloadTextChanged();
}

quint64 KomplexSearchModel::completedDownloads() const
{
    return m_completedDownloads;
}

void KomplexSearchModel::setCompletedDownloads(quint64 completedDownloads)
{
    if (m_completedDownloads == completedDownloads)
        return;
    m_completedDownloads = completedDownloads;
    Q_EMIT completedDownloadsChanged();
}

quint64 KomplexSearchModel::totalDownloads() const
{
    return m_totalDownloads;
}

void KomplexSearchModel::setTotalDownloads(quint64 totalDownloads)
{
    if (m_totalDownloads == totalDownloads)
        return;
    m_totalDownloads = totalDownloads;
    Q_EMIT totalDownloadsChanged();
}

QString KomplexSearchModel::compilerErrorOutput() const
{
    return m_compilerErrorOutput;
}

void KomplexSearchModel::setCompilerErrorOutput(const QString &compilerErrorOutput)
{
    if (m_compilerErrorOutput == compilerErrorOutput)
        return;
    m_compilerErrorOutput = compilerErrorOutput;
    Q_EMIT compilerErrorOutputChanged();
}

QString KomplexSearchModel::compilerOutput() const
{
    return m_compilerOutput;
}

void KomplexSearchModel::setCompilerOutput(const QString &compilerOutput)
{
    if (m_compilerOutput == compilerOutput)
        return;
    m_compilerOutput = compilerOutput;
    Q_EMIT compilerOutputChanged();
}

quint64 KomplexSearchModel::totalPages() const
{
    return m_totalPages;
}

void KomplexSearchModel::setTotalPages(quint64 totalPages)
{
    if (m_totalPages == totalPages)
        return;

    m_totalPages = totalPages;
    Q_EMIT totalPagesChanged();
}

void KomplexSearchModel::next()
{
    if(m_currentPage >= m_totalPages)
        return;

    setCurrentPage(m_currentPage + 1);
    setQuery(m_query);
}

void KomplexSearchModel::previous()
{
    if(m_currentPage <= 0)
        return;

    setCurrentPage(m_currentPage - 1);
    setQuery(m_query);
}

void KomplexSearchModel::convert(qsizetype index)
{
    if(index < 0 || index >= m_data.count())
        return;

    setVideoSelections(QStringList());

    save(index);

    if(status() == Error)
        return;

    compile(index);

    if(status() == Error)
        return;

    if(videoSelections().count() > 0)
        setStatus(Compiled, QStringLiteral("Shader Compiled"));
    else
        finalize(index);
}

ShaderToyEntry KomplexSearchModel::entry(qsizetype index)
{
    if(index < 0 || index >= m_data.count())
        return ShaderToyEntry();

    return m_data[index];
}

void KomplexSearchModel::finalize(qsizetype index)
{
    setStatus(Finalizing, QStringLiteral("Finalizing Shader"));
    install(index);
    setStatus(Idle, QStringLiteral("Shader Installed"));
    setVideoSelections(QStringList());

    Q_EMIT shaderInstalled();
}

void KomplexSearchModel::replaceSource(qsizetype index, QString uuid, QString source)
{
    if(index < 0 || index >= m_data.count() || m_data.count() == 0)
        return;

    QString tempLocation = QStringLiteral("%1/komplex/build/%2").arg(QStandardPaths::writableLocation(QStandardPaths::TempLocation), m_data[index].metadata.id);

    QFile sourceFile(source);
    QFileInfo sourceInfo(source);

    if(!sourceFile.exists())
    {
        setStatus(Error, QStringLiteral("Source file does not exist"));
        return;
    }

    if(QFile::exists(QStringLiteral("%1/videos/%2").arg(tempLocation, sourceInfo.fileName())))
        QFile::remove(QStringLiteral("%1/videos/%2").arg(tempLocation, sourceInfo.fileName()));

    if(!sourceFile.copy(QStringLiteral("%1/videos/%2").arg(tempLocation, sourceInfo.fileName())))
    {
        qWarning() << sourceFile.errorString();
        setStatus(Error, QStringLiteral("Source file could not be copied to temp directory"));
        return;
    }

    QFile packFile(QStringLiteral("%1/pack.json").arg(tempLocation));

    if(!packFile.exists())
    {
        setStatus(Error, QStringLiteral("Pack file could not be located"));
        return;
    }

    if(!packFile.open(QFile::ReadOnly))
    {
        setStatus(Error, QStringLiteral("Could not open pack file"));
        return;
    }

    QString sourceName = QStringLiteral("./videos/%1").arg(sourceInfo.fileName());

    QByteArray packData = packFile.readAll();
    packData.replace(uuid.toLatin1(), sourceName.toLatin1());

    packFile.close();

    if(!packFile.open(QFile::WriteOnly))
    {
        setStatus(Error, QStringLiteral("Could not open pack file"));
        return;
    }

    if(packFile.write(packData) != packData.length())
    {
        setStatus(Error, QStringLiteral("Could not write to pack file. File may be corrupted"));
        return;
    }

    packFile.close();

    m_selectionMutex.lock();
    QStringList newSelections = m_videoSelections;
    newSelections.removeAll(uuid);
    setVideoSelections(newSelections);

    if(videoSelections().count() == 0)
        finalize(index);

    m_selectionMutex.unlock();
}

quint64 KomplexSearchModel::currentPage() const
{
    return m_currentPage;
}

void KomplexSearchModel::setCurrentPage(quint64 currentPage)
{
    if (m_currentPage == currentPage)
        return;

    m_currentPage = currentPage;
    Q_EMIT currentPageChanged();
}

quint64 KomplexSearchModel::resultsPerPage() const
{
    return m_resultsPerPage;
}

void KomplexSearchModel::setResultsPerPage(quint64 resultsPerPage)
{
    if (m_resultsPerPage == resultsPerPage)
        return;

    m_resultsPerPage = resultsPerPage;
    Q_EMIT resultsPerPageChanged();

    setTotalPages(m_totalResults / m_resultsPerPage);
    setQuery(m_query);
}

QString KomplexSearchModel::query() const
{
    return m_query;
}

void KomplexSearchModel::setQuery(const QString &query)
{
    m_query = query;
    Q_EMIT queryChanged();

    if(m_currentPage == 0)
        setCurrentPage(1);

    getSearchResults(QStringLiteral("https://api.artifex.services/v1/shaders/search/%1/%2/%3").arg(QUrl::toPercentEncoding(m_query)).arg((m_currentPage - 1) * m_resultsPerPage).arg(m_resultsPerPage));
}

void KomplexSearchModel::getSearchResults(QString url)
{
    setStatus(Searching, QStringLiteral("Loading Query \"%1\"").arg(m_query));

    resetModel();

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
                setStatus(Error, jsonError.errorString());
                return;
            }

            QJsonObject rootObject = document.object();
            setTotalResults(rootObject[QStringLiteral("total_results")].toInt());

            QJsonArray results = rootObject[QStringLiteral("results")].toArray();
            beginInsertRows(QModelIndex(), 0, results.count() - 1);

            for(const QJsonValue &value : std::as_const(results))
            {
                if(!value.isObject())
                    continue;

                QJsonObject entryObject = value.toObject();

                // add mostly default entry to be filled out async
                ShaderToyEntry entry;
                entry.metadata = ShaderToyMetadata
                {
                    QDateTime::currentDateTime(),
                    entryObject.value(QStringLiteral("description")).toString(),
                    0,
                    false,
                    entryObject.value(QStringLiteral("id")).toString(),
                    0,
                    entryObject.value(QStringLiteral("name")).toString(),
                    0,
                    entryObject.value(QStringLiteral("tags")).toVariant().toStringList(),
                    false,
                    entryObject.value(QStringLiteral("username")).toString(),
                    QString(),
                    0
                };
                m_data.append(entry);
                //download(m_data.count() - 1);
            }

            endInsertRows();
            setStatus(Idle, QString());
        }
    );
}

quint64 KomplexSearchModel::totalResults() const
{
    return m_totalResults;
}

void KomplexSearchModel::setTotalResults(quint64 totalResults)
{
    if (m_totalResults == totalResults)
        return;

    m_totalResults = totalResults;
    Q_EMIT totalResultsChanged();

    setTotalPages(m_totalResults / m_resultsPerPage);
}

int KomplexSearchModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return m_data.size();
}