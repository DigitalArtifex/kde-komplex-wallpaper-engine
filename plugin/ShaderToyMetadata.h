#ifndef SHADERTOYShaderToyMetadata_H
#define SHADERTOYShaderToyMetadata_H

#include <QObject>
#include <QDateTime>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QStandardPaths>
#include <QUuid>
#include <QProcess>
#include <QTimer>
#include <QMutex>
#include <QDir>
#include <QEventLoop>
#include <QJsonDocument>
#include <QJsonParseError>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonValue>
#include <QNetworkAccessManager>
#include <QPixmap>
#include <qqmlintegration.h>

#include "Komplex_global.h"

struct KOMPLEX_EXPORT ShaderToyMetadata
{
    QDateTime date;
    QString description;
    quint64 flags = 0;
    bool hasLiked = false;
    QString id;
    quint64 likes = 0;
    QString name;
    quint64 published = 0;
    QStringList tags;
    bool usePreview = false;
    QString username;
    QString version;
    quint64 views = 0;
};

struct KOMPLEX_EXPORT ShaderToyRenderInput
{
    quint8 channel = 0;
    QString ctype;
    QString filter;
    quint64 id = 0;
    QString internal;
    bool published = false;
    QString source;
    bool srgb = false;
    bool verticalFlip = false;
    QString wrap;
};

struct KOMPLEX_EXPORT ShaderToyRenderOutput
{
    const quint8 channel = 0;
    const quint64 id = 0;
};

struct KOMPLEX_EXPORT ShaderToyRenderPass
{
    QByteArray code;
    QString description;
    QList<ShaderToyRenderInput> inputs;
    QString name;
    QList<ShaderToyRenderOutput> outputs;
    QString type;
};

enum KOMPLEX_EXPORT ShaderToyErrorCode
{
    NoError = 0,
    NetworkError = (0x10 << 24),
    MediaError = (0x20 << 24),
    DiskError = (0x30 << 24),
    CompileError = (0x40 << 24)
};

struct KOMPLEX_EXPORT ShaderToyError
{
    QString message;
    ShaderToyErrorCode code;
};

struct KOMPLEX_EXPORT ShaderToyEntry
{
    enum Status
    {
        Idle,
        Loading,
        Compiling,
        Compiled,
        Error
    };

    ShaderToyMetadata metadata;
    QList<ShaderToyRenderPass> renderPasses;
    QByteArray data;
    ShaderToyError error;
    QStringList videoSelections;
    Status status = Idle;
};

Q_DECLARE_METATYPE(ShaderToyEntry)
Q_DECLARE_METATYPE(ShaderToyError)

#endif // SHADERTOYShaderToyMetadata_H
