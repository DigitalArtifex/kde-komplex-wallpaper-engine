/*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  AudioModel.h
 *
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>
 */

#ifndef AUDIOMODEL_H
#define AUDIOMODEL_H
#include "Komplex_global.h"

#include <QObject>
#include <QString>
#include <QFile>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonParseError>
#include <QAudioDevice>
#include <QMediaDevices>
#include <QAudioInput>
#include <QMediaCaptureSession>
#include <QMediaRecorder>
#include <QtQml/qqmlregistration.h>


    class KOMPLEX_EXPORT AudioModel : public QObject
    {
        Q_OBJECT
        QML_ELEMENT
    public:
        explicit AudioModel(QObject *parent = nullptr);
        ~AudioModel();

        /**!
         * @brief frame
         * This function returns the current audio frame as a QString.
         * It is expected to be called periodically to update the audio frame for the shader.
         * 
         * @return QString containing the current audio frame.
         */
        QByteArray frame() const;

        /**!
         * @brief device
         * This function returns the currently set audio device name.
         * 
         * @return QString containing the name of the audio device.
         */
        QString device() const;

        /**!
         * @brief availableDevices
         * This function returns a list of available audio devices on the system.
         * 
         * @return QStringList containing the names of available audio devices.
         */
        QStringList availableDevices() const;

        /**!
         * @brief setDeviceName
         * This function sets the audio device to be used for capturing audio frames.
         * 
         * @param device The name of the audio device to set.
         */
        Q_INVOKABLE void setDeviceName(const QString &device);

        /**!
         * @brief getAudioFrame
         * This function retrieves the current audio frame from the specified audio device.
         * It is expected to be called periodically to update the audio frame for the shader.
         * 
         * It is an asynchronous fuction and will emit the frameChanged signal when the audio frame is ready.
         */
        Q_INVOKABLE void getAudioFrame();

    Q_SIGNALS:
        void frameChanged();

    private:
        QString m_deviceString;

        QMediaCaptureSession *m_captureSession = nullptr;
        QAudioInput *m_audioInput = nullptr;
        QMediaRecorder *m_recorder = nullptr;

        Q_PROPERTY(QByteArray frame READ frame NOTIFY frameChanged)
        Q_PROPERTY(QString device READ device WRITE setDeviceName NOTIFY frameChanged)
    };


Q_DECLARE_METATYPE(AudioModel)

#endif