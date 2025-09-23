#include "ShaderPackModel.h"

ShaderPackModel::ShaderPackModel(QObject *parent)
    : QObject(parent), 
    m_shaderPackPath(QStringLiteral("%1/.local/share/komplex/packs/default")),
    m_shaderPackInstallPath(QStringLiteral("%1/.local/share/komplex/packs").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation))),
    m_shadersPath(QStringLiteral("%1/.local/share/komplex/shaders").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation))),
    m_imagesPath(QStringLiteral("%1/.local/share/komplex/images").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation))),
    m_cubeMapsPath(QStringLiteral("%1/.local/share/komplex/cubemaps").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation))),
    m_videosPath(QStringLiteral("%1/.local/share/komplex/videos").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation))),
    m_scenesPath(QStringLiteral("%1/.local/share/komplex/scenes").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation))),
    m_json(QString())
{
    m_metadata = new ShaderPackMetadata;
    initialize();
    refreshShaderPacks();
}

ShaderPackModel::~ShaderPackModel()
{
    const QStringList keys = m_availableShaderPacks.keys();

    for(const QString &key : keys)
    {
        ShaderPackMetadata *metadata = m_availableShaderPacks.take(key);
        metadata->deleteLater();
    }

    m_metadata->deleteLater();
}

void ShaderPackModel::initialize()
{
    QString komplexLocation = QStringLiteral("/usr/share/komplex");
    QString komplexHomeLocation = QStringLiteral("%1/.local/share/komplex").arg(QStandardPaths::writableLocation(QStandardPaths::HomeLocation));
    QDir komplexHomeDirectory(komplexHomeLocation);
    QDir komplexDirectory(komplexLocation);

    if(!komplexHomeDirectory.exists())
        komplexHomeDirectory.mkpath(komplexHomeLocation);

    QStringList directories = komplexDirectory.entryList(QDir::NoDotAndDotDot | QDir::Dirs);

    for(const QString &direcoryName : directories)
    {
        if(!komplexHomeDirectory.exists(direcoryName))
        {
            komplexHomeDirectory.mkpath(direcoryName);
            copyDirectoryFiles(komplexDirectory.absoluteFilePath(direcoryName), komplexHomeDirectory.absoluteFilePath(direcoryName));
        }
    }

    // make sure all home dirs are created even if the usr/share data
    // is missing
    QStringList requiredSubDirectories =
    {
        QStringLiteral("images"),
        QStringLiteral("videos"),
        QStringLiteral("shaders"),
        QStringLiteral("cubemaps"),
        QStringLiteral("scenes"),
        QStringLiteral("packs")
    };

    for(const QString &homeDirectory : std::as_const(requiredSubDirectories))
    {
        if(!komplexHomeDirectory.exists(homeDirectory))
            komplexHomeDirectory.mkpath(homeDirectory);
    }
}

void ShaderPackModel::copyDirectoryFiles(QString source, QString destination)
{
    QDir sourceDirectory(source);

    if(destination.endsWith(QLatin1Char('/')))
        destination.removeLast();

    if(sourceDirectory.exists())
    {
        // recurse into directories first
        QStringList directories = sourceDirectory.entryList(QDir::NoDotAndDotDot | QDir::Dirs);

        for(const QString &directory : std::as_const(directories))
        {
            QDir dir;
            if(!dir.exists(QStringLiteral("%1/%2").arg(destination, directory)))
                dir.mkpath(QStringLiteral("%1/%2").arg(destination, directory));
            
            copyDirectoryFiles(sourceDirectory.absoluteFilePath(directory), QStringLiteral("%1/%2").arg(destination, directory));
        }
        
        QStringList fileList = sourceDirectory.entryList(QDir::NoDotAndDotDot | QDir::Files);

        for(const QString &fileName : std::as_const(fileList))
        {
            QFile file(sourceDirectory.absoluteFilePath(fileName));

            if(!file.exists())
            {
                qWarning() << QStringLiteral("File population error. %1 doesn't exist in the source directory").arg(fileName);
                continue;
            }

            if(!file.link(QStringLiteral("%1/%2").arg(destination, fileName)))
            {
                qWarning() << QStringLiteral("File population error. Could not create symlink for %1").arg(fileName);
                continue;
            }
        }
    }
}

void ShaderPackModel::loadJson(const QString &filePath)
{
    if (filePath.isEmpty())
        return;
    
    setState(Loading); // Set the state to Loading

    // Open the file and read its contents
    QFile file(QUrl(filePath).toLocalFile());

    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) 
    {
        setState(Idle); // Reset state to Idle
        qWarning("Could not open file %s for reading", qPrintable(filePath));
        return;
    }

    QByteArray fileData = file.readAll();
    file.close();

    // Parse the JSON data to validate it
    QJsonParseError error;
    QJsonDocument document = QJsonDocument::fromJson(fileData, &error);

    if(error.error != QJsonParseError::NoError) 
    {
        setState(Idle); // Reset state to Idle
        qWarning("JSON parse error: %s at offset %d", qPrintable(error.errorString()), error.offset);
        return;
    }

    // Minify the JSON document to a QString
    QString json = QString::fromLatin1(document.toJson(QJsonDocument::Compact));

    // Check if the JSON content has changed
    if (json != m_json) 
    {
        QFileInfo info(file);
        setShaderPackPath(info.absolutePath()); // Update the shader pack path

        m_json = json;
        Q_EMIT jsonChanged();
    }

    setState(Idle); // Reset state to Idle
}

QString ShaderPackModel::json() const
{
    return m_json;
}

QStringList ShaderPackModel::availableShaderPacks() const
{
    return m_availableShaderPacks.keys();
}

void ShaderPackModel::refreshShaderPacks()
{
    setState(Loading);

    // check for and create the directory if it doesn't exist
    QDir dir(m_shaderPackInstallPath);

    if (!dir.exists())
    {
        if (!dir.mkpath(m_shaderPackInstallPath))
        {
            setState(Idle); // Reset state to Idle
            qWarning("Failed to create shader pack directory: %s", qPrintable(m_shaderPackInstallPath));
            return;
        }
    }

    // Get a list of directories in the shader pack path
    QStringList shaderPacks = dir.entryList(QDir::Dirs | QDir::NoDotAndDotDot);
    QMap<QString, ShaderPackMetadata*> verifiedShaderPacks;

    // Only keep shader packs that contain a valid pack.json file
    for(const QString &pack : std::as_const(shaderPacks))
    {
        QDir packDir(dir.absoluteFilePath(pack));
        ShaderPackMetadata *metadata = new ShaderPackMetadata;
        bool valid = false;

        // Check if the pack directory contains a pack.json file
        if(packDir.exists(QString::fromLatin1("pack.json")))
        {
            // Load the pack.json data
            QFile packFile(packDir.absoluteFilePath(QString::fromLatin1("pack.json")));
            if (packFile.open(QIODevice::ReadOnly | QIODevice::Text)) 
            {
                QByteArray packData = packFile.readAll();
                packFile.close(); // close the file immediately after reading

                // Parse the JSON data to validate it
                QJsonParseError error;
                QJsonDocument doc = QJsonDocument::fromJson(packData, &error);
                if (error.error != QJsonParseError::NoError) 
                {
                    qWarning("Shader pack %s has invalid JSON: %s at offset %d",
                             qPrintable(pack), qPrintable(error.errorString()), error.offset);
                    
                    continue;
                }
                
                metadata->setAuthor(doc.object().value(QLatin1String("author")).toString());
                metadata->setDescription(doc.object().value(QLatin1String("description")).toString());
                metadata->setEngine(doc.object().value(QLatin1String("engine")).toString());
                metadata->setFile(packDir.absoluteFilePath(QLatin1String("pack.json")));
                metadata->setId(doc.object().value(QLatin1String("id")).toString());
                metadata->setLicense(doc.object().value(QLatin1String("license")).toString());
                metadata->setName(doc.object().value(QLatin1String("name")).toString());
                metadata->setVersion(doc.object().value(QLatin1String("version")).toString());

                valid = true; // JSON is valid
            }
        }

        // If valid, add to the list of verified shader packs
        if(valid)
        {
            verifiedShaderPacks.insert(metadata->name(), metadata); // Store the path to the pack.json file
        }
        // Otherwise, log a warning
        else
            qWarning("Shader pack %s does not contain a valid pack.json file", qPrintable(pack));
    }

    m_availableShaderPacks = verifiedShaderPacks;
    Q_EMIT shaderPacksChanged(); // Emit signal to notify that the list has changed
    
    setState(Idle); // Reset state to Idle
}

void ShaderPackModel::loadShaderPack(const QString &name)
{
    setState(Loading);

    if (name.isEmpty() || !m_availableShaderPacks.contains(name)) 
    {
        qWarning("Shader pack '%s' not found", qPrintable(name));
        return;
    }

    QString filePath = m_availableShaderPacks.value(name)->file();
    loadJson(filePath); // Load the JSON content of the shader pack
}

// This may be replaced with Quazip and something similar for tarballs in the future
void ShaderPackModel::importShaderPack(const QString &filePath)
{
    if (filePath.isEmpty()) 
    {
        qWarning("File path is empty");
        return;
    }

    QFileInfo file(filePath);
    if (!file.exists()) 
    {
        qWarning("File does not exist: %s", qPrintable(filePath));
        return;
    }

    QProcess process;
    QString command;

    setState(Importing); // Set the state to Importing

    // Check if the file is a zip or tarball
    if(filePath.endsWith(QString::fromLatin1(".zip"), Qt::CaseInsensitive))
        command = QString::fromLatin1("unzip -o %1 -d %2/%3").arg(file.absoluteFilePath(), m_shaderPackInstallPath, file.baseName());
    else if(filePath.endsWith(QString::fromLatin1(".tar.gz"), Qt::CaseInsensitive) || filePath.endsWith(QString::fromLatin1(".tar"), Qt::CaseInsensitive))
        command = QString::fromLatin1("tar -xf %1 -C %2/%3").arg(file.absoluteFilePath(), m_shaderPackInstallPath, file.baseName());
    else 
    {
        setState(Idle); // Reset state to Idle
        qWarning("Unsupported file format for shader pack import: %s", qPrintable(filePath));
        return;
    }

    // Connect to the process finished signal to refresh shader packs and so the event loop can exit
    connect(&process, &QProcess::finished, this, [this](int exitCode, QProcess::ExitStatus exitStatus) 
    {
        // Check if the process exited normally and with a success code
        if (exitStatus == QProcess::NormalExit && exitCode == 0) 
            refreshShaderPacks(); // Refresh the list of shader packs
        else 
        {
            setState(Idle); // Reset state to Idle
            qWarning("Failed to import shader pack: Exit code %d, Status %d", exitCode, exitStatus);
            return;
        }
    });

    // Start the process
    process.start(command);

    // Make sure the process started successfully
    if (!process.waitForStarted())
    {
        setState(Idle); // Reset state to Idle
        qWarning("Failed to start process for importing shader pack: %s", qPrintable(process.errorString()));
        return;
    }
}

ShaderPackModel::State ShaderPackModel::state() const
{
    return m_state;
}

void ShaderPackModel::setState(State state)
{
    if (m_state != state) 
    {
        m_state = state;
        Q_EMIT stateChanged();
    }
}

QString ShaderPackModel::shaderPackPath() const
{
    return m_shaderPackPath;
}

void ShaderPackModel::setShaderPackPath(const QString &filePath)
{
    QFileInfo fileInfo(filePath);

    if (m_shaderPackPath != fileInfo.absolutePath()) 
    {
        m_shaderPackPath = filePath;
        Q_EMIT shaderPackPathChanged();
    }
}

QString ShaderPackModel::shaderPackName() const
{
    return m_shaderPackName;
}

QString ShaderPackModel::shaderPackInstallPath() const
{
    return m_shaderPackInstallPath;
}

QString ShaderPackModel::shadersPath() const
{
    return m_shadersPath;
}

QString ShaderPackModel::imagesPath() const
{
    return m_imagesPath;
}

QString ShaderPackModel::cubeMapsPath() const
{
    return m_cubeMapsPath;
}

QString ShaderPackModel::videosPath() const
{
    return m_videosPath;
}

QString ShaderPackModel::scenesPath() const
{
    return m_scenesPath;
}

ShaderPackMetadata *ShaderPackModel::metadata() const { return m_metadata; }
void ShaderPackModel::setMetadata(ShaderPackMetadata *metadata)
{
    m_metadata = metadata;
    Q_EMIT metadataChanged();
}

void ShaderPackModel::loadMetadata(const QString &name)
{
    if(!m_availableShaderPacks.contains(name))
        return;
    
    m_metadata->setAuthor(m_availableShaderPacks[name]->author());
    m_metadata->setDescription(m_availableShaderPacks[name]->description());
    m_metadata->setEngine(m_availableShaderPacks[name]->engine());
    m_metadata->setFile(m_availableShaderPacks[name]->file());
    m_metadata->setId(m_availableShaderPacks[name]->id());
    m_metadata->setLicense(m_availableShaderPacks[name]->license());
    m_metadata->setName(m_availableShaderPacks[name]->name());
    m_metadata->setVersion(m_availableShaderPacks[name]->version());

    Q_EMIT metadataChanged();
}

void ShaderPackModel::loadMetadataFromFile(const QString &file)
{ 
    // Load the pack.json data
    QFile packFile(QUrl(file).toLocalFile());
    if (packFile.open(QIODevice::ReadOnly | QIODevice::Text)) 
    {
        QByteArray packData = packFile.readAll();
        packFile.close(); // close the file immediately after reading

        // Parse the JSON data to validate it
        QJsonParseError error;
        QJsonDocument doc = QJsonDocument::fromJson(packData, &error);
        if (error.error != QJsonParseError::NoError) 
        {
            qWarning("Shader pack %s has invalid JSON: %s at offset %d",
                     qPrintable(file), qPrintable(error.errorString()), error.offset);
            
            return;
        }
        
        m_metadata->setAuthor(doc.object().value(QLatin1String("author")).toString());
        m_metadata->setDescription(doc.object().value(QLatin1String("description")).toString());
        m_metadata->setEngine(doc.object().value(QLatin1String("engine")).toString());
        m_metadata->setFile(file);
        m_metadata->setId(doc.object().value(QLatin1String("id")).toString());
        m_metadata->setLicense(doc.object().value(QLatin1String("license")).toString());
        m_metadata->setName(doc.object().value(QLatin1String("name")).toString());
        m_metadata->setVersion(doc.object().value(QLatin1String("version")).toString());

        Q_EMIT metadataChanged();
    }
}

QString ShaderPackModel::path(const QString &name)
{
    if(!m_availableShaderPacks.contains(name))
        return QString();

    return m_availableShaderPacks[name]->file();
}