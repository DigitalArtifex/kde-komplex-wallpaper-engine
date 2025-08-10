#ifndef AUDIOIMAGEPROVIDER_H
#define AUDIOIMAGEPROVIDER_H
#include <QObject>
#include <QPixmap>
#include <QQuickImageProvider>

#include "AudioModel.h"
#include "Komplex_global.h"

class KOMPLEX_EXPORT AudioImageProvider : public QQuickImageProvider
{
    public:
        explicit AudioImageProvider();

        QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override;
};

#endif