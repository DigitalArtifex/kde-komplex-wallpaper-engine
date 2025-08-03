#include "AudioModel.h"

#ifdef AUDIOMODEL_H

AudioModel::AudioModel(QObject *parent)
    : QObject(parent), m_deviceString(QString())
{
}

AudioModel::~AudioModel()
{
    if (m_recorder) 
    {
        m_recorder->stop();
        delete m_recorder;
    }

    if (m_audioInput) 
        delete m_audioInput;

    if (m_captureSession)
        delete m_captureSession;
}

QByteArray AudioModel::frame() const
{
    // This function should return the current audio frame.
    // For now, we return an empty QByteArray.
    return QByteArray();
}

QString AudioModel::device() const
{
    return m_deviceString;
}

QStringList AudioModel::availableDevices() const
{
    QStringList devices;
    
    // Assuming QAudioDeviceInfo is used to get available audio devices
    for (const auto &device : QMediaDevices::audioInputs()) 
    {
        devices.append(QString::fromLatin1(device.id()));
    }

    return devices;
}

void AudioModel::setDeviceName(const QString &device)
{
    if (m_deviceString == device)
        return;

    m_deviceString = device;

    // if (m_audioInput) 
    // {
    //     m_audioInput->setDevice(QAudioInput(device));
    //     getAudioFrame();
    // }
}

void AudioModel::getAudioFrame()
{
    // This function should be implemented to retrieve the audio frame
    // from the audio input device and emit the frameChanged signal.
    // For now, we will just emit the signal to indicate that the frame is ready.
    Q_EMIT frameChanged();
}

#endif