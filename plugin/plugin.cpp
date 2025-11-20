#include <QObject>
#include <QQmlEngine>
#include <QQmlExtensionPlugin>

#include "AudioModel.h"
#include "AudioImageProvider.h"
#include "ShaderPackModel.h"
#include "PexelsVideoSearch.h"
#include "PexelsImageSearch.h"
#include "CubemapSearch.h"
#include "ShaderToySearchModel.h"
#include "GeometryProvider.h"
#include "KomplexSearchModel.h"
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
    
        qmlRegisterSingletonType<AudioModel*>(uri, 1, 0, "AudioModel", komplexAudioSingletonProvider);
        qmlRegisterType<ShaderPackModel>(uri, 1, 0, "ShaderPackModel");
        qmlRegisterType<GeometryProvider>(uri, 1, 0, "GeometryProvider");
        qmlRegisterType<ShaderToySearchModel>(uri, 1, 0, "ShaderToySearchModel");
        qmlRegisterType<PexelsVideoSearchModel>(uri, 1, 0, "PexelsVideoSearchModel");
        qmlRegisterType<PexelsImageSearchModel>(uri, 1, 0, "PexelsImageSearchModel");
        qmlRegisterType<KomplexSearchModel>(uri, 1, 0, "KomplexSearchModel");
        qmlRegisterType<CubemapSearchModel>(uri, 1, 0, "CubemapSearchModel");
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