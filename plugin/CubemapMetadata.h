#ifndef CUBEMAPMETADATA_H
#define CUBEMAPMETADATA_H

#include <QObject>
#include <QUrl>

#include "Komplex_global.h"

struct KOMPLEX_EXPORT CubemapMetadata
{
    QString description;
    QString id;
    QString name;
    QUrl thumbnail;
};

#endif // CUBEMAPMETADATA_H