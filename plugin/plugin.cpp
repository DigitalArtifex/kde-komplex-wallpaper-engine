#include <QObject>
#include <QQmlEngine>
#include <QQmlExtensionPlugin>

#include "AudioModel.h"
#include "AudioImageProvider.h"
#include "ShaderPackModel.h"
#include "PexelsVideoSearch.h"
#include "PexelsImageSearch.h"
#include "ShaderToySearchModel.h"
#include "GeometryProvider.h"
#include "Komplex_global.h"

AudioModel *komplexAudioSingletonProvider(QQmlEngine *engine, QJSEngine *scriptEngine)
{
    Q_UNUSED(engine)
    Q_UNUSED(scriptEngine)

    AudioModel *model = new AudioModel();
    return model;
}

class KOMPLEX_EXPORT KomplexPlugin : public QQmlExtensionPlugin
{
	Q_OBJECT
	Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid FILE "plugin.json")

    inline static AudioModel *m_model = nullptr;

public:
	void registerTypes(const char *uri) override
    {
        Q_ASSERT(QLatin1String(uri) == QLatin1String("com.github.digitalartifex.komplex"));

        char *stUri = new char[std::strlen(uri) + std::strlen(".ShaderToy")];
        std::sprintf(stUri, "%s.ShaderToy", uri);

        char *pvUri = new char[std::strlen(uri) + std::strlen(".Pexels.Video")];
        std::sprintf(pvUri, "%s.Pexels.Video", uri);

        char *piUri = new char[std::strlen(uri) + std::strlen(".Pexels.Image")];
        std::sprintf(piUri, "%s.Pexels.Image", uri);
    
        qmlRegisterSingletonType<AudioModel*>(uri, 1, 0, "AudioModel", komplexAudioSingletonProvider);
        qmlRegisterType<ShaderPackModel>(uri, 1, 0, "ShaderPackModel");
        qmlRegisterType<GeometryProvider>(uri, 1, 0, "GeometryProvider");
        qmlRegisterType<ShaderToySearchModel>(stUri, 1, 0, "SearchModel");
        qmlRegisterType<PexelsVideoSearchModel>(pvUri, 1, 0, "SearchModel");
        qmlRegisterType<PexelsImageSearchModel>(piUri, 1, 0, "SearchModel");
    }

    void unregisterTypes() override
    {
        AudioModel::stopCapture();
    }

    void initializeEngine(QQmlEngine *engine, const char *uri) override
    {
        Q_ASSERT(QLatin1String(uri) == QLatin1String("com.github.digitalartifex.komplex"));
        engine->addImageProvider(QString::fromLatin1("audiotexture"), new AudioImageProvider);
    }
};

#include "plugin.moc"