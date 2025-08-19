#ifndef SHADERPACKMETADATA
#define SHADERPACKMETADATA

#include <QObject>
#include <QString>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonParseError>
#include <QStandardPaths>
#include <QDir>
#include <QMap>
#include <QProcess>
#include <QEventLoop>
#include <QtQml/qqmlregistration.h>

#include "Komplex_global.h"

class KOMPLEX_EXPORT ShaderPackMetadata : public QObject
{
    Q_OBJECT
    QML_ELEMENT

    QString m_author;
    QString m_description;
    QString m_engine;
    QString m_file;
    QString m_id;
    QString m_license;
    QString m_name;
    QString m_version;
    
    Q_PROPERTY(QString author READ author WRITE setAuthor NOTIFY authorChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)
    Q_PROPERTY(QString engine READ engine WRITE setEngine NOTIFY engineChanged)
    Q_PROPERTY(QString file READ file WRITE setFile NOTIFY fileChanged)
    Q_PROPERTY(QString id READ id WRITE setId NOTIFY idChanged)
    Q_PROPERTY(QString license READ license WRITE setLicense NOTIFY licenseChanged)
    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QString version READ version WRITE setVersion NOTIFY versionChanged)

    Q_SIGNALS:
        void authorChanged();
        void descriptionChanged();
        void engineChanged();
        void idChanged();
        void licenseChanged();
        void nameChanged();
        void versionChanged();
        void fileChanged();

    public:

    QString author() const { return m_author; }
    void setAuthor(const QString& author) 
    {
        if(author != m_author)
        {
            m_author = author;
            Q_EMIT authorChanged();
        }
    }

    QString description() const { return m_description; }
    void setDescription(const QString& description)
    {
        if(description != m_description)
        {
            m_description = description;
            Q_EMIT descriptionChanged();
        }
    }

    QString engine() const { return m_engine; }
    void setEngine(const QString& engine)
    {
        if(engine != m_engine)
        {
            m_engine = engine;
            Q_EMIT engineChanged();
        }
    }

    QString file() const { return m_file; }
    void setFile(const QString& file)
    {
        if(file != m_file)
        {
            m_file = file;
            Q_EMIT fileChanged();
        }
    }

    QString id() const { return m_id; }
    void setId(const QString& id) 
    {
        if(id != m_id)
        {
            m_id = id;
            Q_EMIT idChanged();
        }
    }

    QString license() const { return m_license; }
    void setLicense(const QString& license)
    {
        if(license != m_license)
        {
            m_license = license;
            Q_EMIT licenseChanged();
        }
    }

    QString name() const { return m_name; }
    void setName(const QString& name)
    {
        if(name != m_name)
        {
            m_name = name;
            Q_EMIT nameChanged();
        }
    }

    QString version() const { return m_version; }
    void setVersion(const QString& version)
    {
        if(version != m_version)
        {
            m_version = version;
            Q_EMIT versionChanged();
        }
    }
};

Q_DECLARE_METATYPE(ShaderPackMetadata)
#endif