#include <QObject>
#include <QQmlEngine>
#include <QQmlExtensionPlugin>

#include "AudioModel.h"
#include "AudioImageProvider.h"
#include "ShaderPackModel.h"
#include "Komplex_global.h"

class KOMPLEX_EXPORT KomplexPlugin : public QQmlExtensionPlugin
{
	Q_OBJECT
	Q_PLUGIN_METADATA(IID QQmlExtensionInterface_iid FILE "plugin.json")
public:
	void registerTypes(const char *uri) override
    {
        Q_ASSERT(QLatin1String(uri) == QLatin1String("com.github.digitalartifex.komplex"));
    
        qmlRegisterType<AudioModel>(uri, 1, 0, "AudioModel");
        qmlRegisterType<ShaderPackModel>(uri, 1, 0, "ShaderPackModel");
    }

    void initializeEngine(QQmlEngine *engine, const char *uri) override
    {
        Q_ASSERT(QLatin1String(uri) == QLatin1String("com.github.digitalartifex.komplex"));
        engine->addImageProvider(QString::fromLatin1("audiotexture"), new AudioImageProvider);
    }
};

#include "plugin.moc"