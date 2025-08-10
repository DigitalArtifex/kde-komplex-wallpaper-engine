/*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  AudioModel.h
 * 
 *  This is pretty much just a reimplementation of the audiocapture example
 *  from the PipeWire docs.
 * 
 *  NOTICE:
 *  The spectrum data is currently out of spec according to the documentation
 *  https://webaudio.github.io/web-audio-api/#smoothing-over-time
 * 
 *  The described smoothing method was resulting in inconsistent data. This
 *  is likely due to a poor implementation. A linear smoothing algo seems to work
 *  (at least visually). Will need to revisit the temporal implementation if 
 *  things do not work as expected.
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
#include <QThread>
#include <QtEndian>
#include <QPixmap>
#include <QQmlEngine>
#include <QJSValue>
#include <QVector>
#include <QPainter>
#include <QBrush>
#include <QPen>
#include <QThread>
#include <QMutex>
#include <QtConcurrent/QtConcurrent>
#include <QtQml/qqmlregistration.h>

#include <complex>
#include <pipewire/pipewire.h>
#include <spa/param/audio/raw.h>
#include <spa/pod/pod.h>
#include <spa/pod/builder.h>
#include <spa/param/format-types.h>
#include <spa/param/buffers.h>
#include <spa/param/audio/format-utils.h>

class KOMPLEX_EXPORT AudioModel : public QObject
{
    Q_OBJECT
    QML_SINGLETON
    QML_NAMED_ELEMENT(AudioModel)

public:
    AudioModel(QObject *parent = nullptr);
    ~AudioModel();

    /**!
     * @brief frame
     * This function returns the current audio frame as a QPixmap.
     * It is expected to be called after the frameChanged signal is emitted, if using from CPP
     *
     * If it is being used from QML, it will need to be resolved from the AuidoTexture Image Provider (image:/audio/frame#.jpg).
     * See AudioImage provider for more details.
     * 
     * @return QPixmap containing the current audio frame.
     */
    static QPixmap frame();

    // Q_INVOKABLE bool init();
    Q_INVOKABLE static void startCapture();
    Q_INVOKABLE static void stopCapture();

private Q_SLOTS:
    static void startCaptureAsync();

private:
    static std::vector<double> createBlackmanWindow(int size);
    static std::vector<float> smoothData(const std::vector<float>& data, int windowSize = 5);

    struct impl
    {
        pw_main_loop *loop;
        pw_stream *stream;

        spa_audio_info format;
        unsigned move:1;

        QVector<qreal> samples; // we need at least 2048 samples
        QVector<qreal> smoothed; // we're supposed to save for smoothing, but I couldn't get this method to work
        qreal last;
    };

    inline static AudioModel *m_instance = nullptr;
    inline static QThread *m_thread = nullptr;
    inline static QMutex m_mutex;

    QPixmap m_frame;

    inline static impl m_impl_data;
    inline static bool m_running = false;

    static void on_process(void *user_data);
    static void do_quit(void *user_data, int signal_number);

    static void on_stream_param_changed(void *_data, uint32_t id, const struct spa_pod *param);

    inline static const struct pw_stream_events stream_events = {
        .version = PW_VERSION_STREAM_EVENTS,
        .param_changed = on_stream_param_changed,
        .process = on_process,
    };
};

Q_DECLARE_METATYPE(AudioModel)

#endif