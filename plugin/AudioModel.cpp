/* PipeWire */
/* SPDX-FileCopyrightText: Copyright © 2022 Wim Taymans */
/* SPDX-License-Identifier: MIT */

/*
 [title]
 Audio capture using \ref pw_stream "pw_stream".
 [title]
 */

#include <stdio.h>
#include <math.h>
#include <fftw3.h>

#include "AudioModel.h"

AudioModel::AudioModel(QObject *parent) : QObject(parent)
{
    m_impl_data = { nullptr, nullptr, {0, 0, {}}, 1, {}, {}, 0.0};
    m_impl_data.samples.reserve(4096);
    m_impl_data.smoothed.reserve(2048);

    //fill the smoothed data buffer with 0s
    for(int i = 0; i < 2048; ++i)
        m_impl_data.smoothed.insert(i, 0);

    m_thread = new QThread(parent);

    moveToThread(m_thread);
    connect(m_thread, &QThread::started, this, &AudioModel::startCaptureAsync);

    const struct spa_pod *params[1];
    uint8_t buffer[1024];
    struct pw_properties *props;
    struct spa_pod_builder b = SPA_POD_BUILDER_INIT(buffer, sizeof(buffer));

    pw_init(nullptr, nullptr);

    /* make a main loop. If you already have another main loop, you can add
         * the fd of this pipewire mainloop to it. */
    m_impl_data.loop = pw_main_loop_new(NULL);

    pw_loop_add_signal(pw_main_loop_get_loop(m_impl_data.loop), SIGINT, do_quit, &m_impl_data);
    pw_loop_add_signal(pw_main_loop_get_loop(m_impl_data.loop), SIGTERM, do_quit, &m_impl_data);

    /* Create a simple stream, the simple stream manages the core and remote
         * objects for you if you don't need to deal with them.
         *
         * If you plan to autoconnect your stream, you need to provide at least
         * media, category and role properties.
         *
         * Pass your events and a user_data pointer as the last arguments. This
         * will inform you about the stream state. The most important event
         * you need to listen to is the process event where you need to produce
         * the data.
         */
    props = pw_properties_new(PW_KEY_MEDIA_TYPE, "Audio",
                              PW_KEY_MEDIA_CATEGORY, "Capture",
                              PW_KEY_MEDIA_ROLE, "Music",
                              NULL);

    /* uncomment if you want to capture from the sink monitor ports */
    pw_properties_set(props, PW_KEY_STREAM_CAPTURE_SINK, "true");

    m_impl_data.stream = pw_stream_new_simple(
        pw_main_loop_get_loop(m_impl_data.loop),
        "audio-capture",
        props,
        &stream_events,
        &m_impl_data);

    struct spa_audio_info_raw info = SPA_AUDIO_INFO_RAW_INIT(
                                        .format = SPA_AUDIO_FORMAT_F32,
                                        .rate = 44100,
                                        .channels = 2
                                    );

    /* Make one parameter with the supported formats. The SPA_PARAM_EnumFormat
         * id means that this is a format enumeration (of 1 value).
         * We leave the channels and rate empty to accept the native graph
         * rate and channels. */
    params[0] = spa_format_audio_raw_build(&b, SPA_PARAM_EnumFormat, &info);

    /* Now connect this stream. We ask that our process function is
         * called in a realtime thread. */
    pw_stream_connect(m_impl_data.stream,
                      PW_DIRECTION_INPUT,
                      PW_ID_ANY,
                      static_cast<pw_stream_flags>(PW_STREAM_FLAG_AUTOCONNECT |
                          PW_STREAM_FLAG_MAP_BUFFERS |
                          PW_STREAM_FLAG_RT_PROCESS),
                      params, 1);

    if(!m_instance)
        m_instance = this;
}

AudioModel::~AudioModel()
{
    stopCapture();

    if (m_impl_data.stream)
    {
        pw_stream_disconnect(m_impl_data.stream);
        pw_stream_destroy(m_impl_data.stream);
    }
    if (m_impl_data.loop)
        pw_main_loop_destroy(m_impl_data.loop);

    if(m_thread)
    {
        if(m_thread->isRunning())
            m_thread->quit();

        m_thread->deleteLater();
    }

    pw_deinit();
}

void AudioModel::startCapture()
{
    if(!m_instance)
        m_instance = new AudioModel();
        
    ++m_clients;

    if(m_thread->isRunning())
        return;

    m_thread->start(QThread::NormalPriority);
}

void AudioModel::stopCapture()
{
    if(--m_clients > 0)
        return;
    
    if(m_thread->isRunning())
        m_thread->quit();
    
    m_running = false;
    pw_main_loop_quit(m_impl_data.loop);
}

void AudioModel::startCaptureAsync()
{
    pw_main_loop_run(m_impl_data.loop);
}

QPixmap AudioModel::frame()
{
    if(!m_instance)
        return QPixmap();
    
    return m_instance->m_frame;
}

/* Be notified when the stream param changes. We're only looking at the
 * format changes.
 */
void AudioModel::on_stream_param_changed(void *_data, uint32_t id, const struct spa_pod *param)
{
    struct impl *data = reinterpret_cast<impl*>(_data);

    /* NULL means to clear the format */
    if (param == NULL || id != SPA_PARAM_Format)
        return;

    if (spa_format_parse(param, &data->format.media_type, &data->format.media_subtype) < 0)
        return;

    /* only accept raw audio */
    if (data->format.media_type != SPA_MEDIA_TYPE_audio ||
        data->format.media_subtype != SPA_MEDIA_SUBTYPE_raw)
        return;

    /* call a helper function to parse the format for us. */
    spa_format_audio_raw_parse(param, &data->format.info.raw);

    fprintf(stdout, "capturing rate:%d channels:%d\n", data->format.info.raw.rate, data->format.info.raw.channels);
}

/* our data processing function is in general:
 *
 *  struct pw_buffer *b;
 *  b = pw_stream_dequeue_buffer(stream);
 *
 *  .. consume stuff in the buffer ...
 *
 *  pw_stream_queue_buffer(stream, b);
 */
void AudioModel::on_process(void *userdata)
{
    struct impl *data = reinterpret_cast<impl*>(userdata);
    struct pw_buffer *b;
    struct spa_buffer *buf;

    float *samples;
    uint32_t n_channels, n_samples;

    if ((b = pw_stream_dequeue_buffer(data->stream)) == NULL) {
        pw_log_warn("out of buffers: %m");
        return;
    }

    buf = b->buffer;
    if ((samples = reinterpret_cast<float*>(buf->datas[0].data)) == NULL)
        return;

    n_channels = data->format.info.raw.channels;
    n_samples = buf->datas[0].chunk->size / sizeof(float);

    // convert channels to mono
    for(uint32_t index = 0; index < n_samples; index += n_channels)
    {
        float average = 0;

        for(uint32_t channel = 0; channel < n_channels; channel++)
            average += samples[index + channel];

        average /= n_channels;

        if(index > 0)
            data->samples.push_back(average);
    }

    /**
     * To convert the captured samples to an audio texture we need to:
     *
     * Take 2048 samples of audio data as an array of floating point data
     * 1. Calculate wave data
     * 2. Multiply it with Blackman window
     * 3. Convert samples into complex numbers (imaginary parts are all zeros)
     * 4. Apply the Fourier transform with fftSize = 2048, as a result we get 1024 FFT bins
     * 5. Convert complex result into real values using cabs() function
     * 6. Divide each value by fftSize
     * 7. Apply smoothing by using previously calculated spectrum values
     * 8. Convert resulting values to dB: dB = 20 * log10(v)
     * 9. Convert floating point dB spectrum into 8-bit values:
     * 10. Write 8-bit values into texture
     */

    // 1
    if(data->samples.length() >= 2048)
    {
        QVector<qreal> rawSamples = data->samples.mid(0, 2048);
        data->samples.remove(0, 2048);

        int N = 2048;
        auto window = createBlackmanWindow(N);
        std::vector<double> windowedSamples(N);

        QVector<int> waveData;

        for (int i = 0; i < N; ++i) {
            waveData.push_back(static_cast<int>(std::clamp(static_cast<int>(128 * rawSamples[i] + 1) * 2, 0, 255)));
            windowedSamples[i] = rawSamples[i] * window[i];
        }

        // Step 2: Convert to complex
        std::vector<std::complex<double>> complexSamples(N);
        for (int i = 0; i < N; ++i) {
            complexSamples[i] = std::complex<double>(windowedSamples[i], 0.0);
        }

        // Step 3: Apply FFTW3 transformation
        fftw_plan plan = fftw_plan_dft_1d(N,
                                          reinterpret_cast<fftw_complex*>(complexSamples.data()),
                                          reinterpret_cast<fftw_complex*>(complexSamples.data()),
                                          FFTW_FORWARD, FFTW_ESTIMATE);

        fftw_execute(plan);
        fftw_destroy_plan(plan);

        // Step 4: Convert back to floats and divide by N
        std::vector<float> magnitude(N);
        for (int i = 0; i < N; ++i) {
            double real = complexSamples[i].real();
            double imag = complexSamples[i].imag();
            magnitude[i] = static_cast<float>(std::sqrt(real * real + imag * imag) / N);
        }

        // Step 5: Apply smoothing
        auto smoothed = smoothData(magnitude, 3); // Using window size of 3

        // Step 6: Convert to decibels
        std::vector<float> dbValues(smoothed.size());
        const float minDb = -100.0f; // Minimum dB value for clamping
        const float reference = 1.0f; // Reference amplitude

        for (size_t i = 0; i < smoothed.size(); ++i) {
            if (smoothed[i] > 0) {
                dbValues[i] = 20.0f * std::log10(smoothed[i] / reference);
            } else {
                dbValues[i] = minDb;
            }
        }

        // Step 7: Clamp to 8-bit values for red channel
        std::vector<uint8_t> redChannel(dbValues.size());

        for (size_t i = 0; i < dbValues.size(); ++i) {
            // Clamp between -100dB and 0dB, then map to 0-255 range
            float clamped = std::max(minDb, std::min(0.0f, dbValues[i]));
            redChannel[i] = static_cast<uint8_t>((clamped + 100.0f) * 2.55f);
        }

        QPixmap audioTexture(512,2);
        QPainter painter(&audioTexture);
        painter.fillRect(QRect(0,0,512,2), QColor::fromRgb(0,0,0));

        //we can only paint the lower half of the spectrum
        for(int index = 0; index < 512; ++index)
        {
            //paint the pixels
            painter.setPen(QPen(QColor::fromRgb(redChannel[index], 0, 0), 1));
            painter.drawPoint(index, 0);
            painter.setPen(QPen(QColor::fromRgb(waveData[index], 0, 0), 1));
            painter.drawPoint(index, 1);
        }

        painter.end();

        if(m_mutex.tryLock(4))
        {
            m_instance->m_frame = audioTexture;
            m_mutex.unlock();
        }
    }

    pw_stream_queue_buffer(data->stream, b);
}

// Blackman window function
std::vector<double> AudioModel::createBlackmanWindow(int size)
{
    std::vector<double> window(size);
    const double a0 = 0.42;
    const double a1 = 0.5;
    const double a2 = 0.08;

    for (int i = 0; i < size; ++i) {
        window[i] = a0 - a1 * std::cos(2.0 * M_PI * i / (size - 1)) +
                    a2 * std::cos(4.0 * M_PI * i / (size - 1));
    }
    return window;
}

// Simple smoothing function using moving average
std::vector<float> AudioModel::smoothData(const std::vector<float>& data, int windowSize) {
    std::vector<float> smoothed(data.size());

    for (size_t i = 0; i < data.size(); ++i) {
        float sum = 0.0f;
        int count = 0;

        for (int j = -windowSize/2; j <= windowSize/2; ++j) {
            int idx = i + j;
            if (idx >= 0 && idx < static_cast<int>(data.size())) {
                sum += data[idx];
                count++;
            }
        }

        smoothed[i] = count > 0 ? sum / count : 0.0f;
    }

    return smoothed;
}

void AudioModel::do_quit(void *userdata, int signal_number)
{
    Q_UNUSED(signal_number)

    struct impl *data = reinterpret_cast<impl*>(userdata);
    pw_main_loop_quit(data->loop);
}
