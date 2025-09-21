#ifndef Metadata_H
#define Metadata_H
#include <QObject>

#include "Komplex_global.h"

struct KOMPLEX_EXPORT PexelsVideoThumbnail
{
    quint64 id = 0;
    quint64 nr = 0;

    QString image;
};

struct KOMPLEX_EXPORT PexelsVideoMetadata
{
    quint64 id = 0;
    quint64 width = 0;
    quint64 height = 0;
    quint64 size = 0;
    qreal fps;
    QString quality;
    QString type;
    QString link;
    QString sizeText;

    // bool operator==(const PexelsVideoMetadata &other) const
    // {
    //     return ((id == other.id) && (height == other.height) &&
    //             (fps == other.fps) && (link == other.link) &&
    //             (quality == other.quality) && (type == other.type) &&
    //             (width == other.width) && (size == other.size) &&
    //             (sizeText == other.sizeText));
    // }

    // bool operator!=(const PexelsVideoMetadata &other) const
    // {
    //     return !(*this == other);
    // }
};

struct KOMPLEX_EXPORT PexelsVideoUser
{
    quint64 id;
    QString name;
    QString url;
};

struct KOMPLEX_EXPORT PexelsVideoEntry
{
    quint64 id = 0;
    quint64 width = 0;
    quint64 height = 0;
    quint64 duration = 0;
    QString url;
    QString image;
    QStringList tags;
    PexelsVideoUser author;
    QList<PexelsVideoMetadata> videos;
    QList<PexelsVideoThumbnail> thumbnails;
};

#endif // Metadata_H
