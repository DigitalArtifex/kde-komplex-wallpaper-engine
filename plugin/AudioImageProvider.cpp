#include "AudioImageProvider.h"

AudioImageProvider::AudioImageProvider() 
    : QQuickImageProvider(QQuickImageProvider::Pixmap) {}

QPixmap AudioImageProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id) // id is useless here. we always want to return the latest frame from AudioModel
    Q_UNUSED(requestedSize) // requested size is useless too. texture must always be 512x2

    if(size)
        *size = AudioModel::frame().size();

    //return the latest frame
    return AudioModel::frame();
}