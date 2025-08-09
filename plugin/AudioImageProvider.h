#ifndef AUDIOIMAGEPROVIDER_H
#define AUDIOIMAGEPROVIDER_H
#include <QObject>
#include <QPixmap>
#include <QQuickImageProvider>

#include "AudioModel.h"

class AudioImageProvider : public QQuickImageProvider
{
    public:
        explicit AudioImageProvider();

        QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize) override;
};

#endif