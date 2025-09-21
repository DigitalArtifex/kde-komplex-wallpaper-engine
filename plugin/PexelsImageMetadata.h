#ifndef PEXELSIMAGEMETADATA_H
#define PEXELSIMAGEMETADATA_H

#include <QObject>
#include <QQmlEngine>

#include "Komplex_global.h"

struct KOMPLEX_EXPORT PexelsImageMetadata
{
    QString alt;
    QString averageColorCode;
    quint64 height = 0;
    quint64 id = 0;
    bool liked = false;
    QString photographer;
    QUrl photographerUrl;
    quint64 photographerId = 0;
    QMap<QString,QUrl> sources;
    QUrl thumbnail;
    QUrl url;
    quint64 width = 0;
};

#endif // PEXELSIMAGEMETADATA_H
