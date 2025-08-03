#ifndef SHADERPACKMODEL_H
#define SHADERPACKMODEL_H

#include "Komplex_global.h"

#include <QObject>
#include <QString>
#include <QFile>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QJsonParseError>
#include <QStandardPaths>
#include <QDir>
#include <QMap>
#include <QProcess>
#include <QEventLoop>
#include <QtQml/qqmlregistration.h>

class KOMPLEX_EXPORT ShaderPackModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit ShaderPackModel(QObject *parent = nullptr);
    ~ShaderPackModel() override = default;

    // State enum to represent the current state of the model
    // for the UI and configuration
    enum State 
    {
        Idle,
        Loading,
        Importing
    };
    Q_ENUM(State)

    /**!
     * @brief json
     * This function returns the current JSON content as a QString.
     * It is expected to be called to retrieve the shader pack's JSON data,
     * after loadJson() has been called to load the shader pack.
     * 
     * @return QString containing the JSON data.
     */
    QString json() const;

    /**!
     * @brief loadJson
     * This function loads a JSON file from the specified path and updates 
     * the model. It emits jsonChanged() signal if the JSON content changes.
     * 
     * @param filePath The path to the JSON file to load.
     */
    Q_INVOKABLE void loadJson(const QString &filePath);

    /**!
     * @brief availableShaderPacks
     * This function returns a list of available shader packs.
     * It is expected to be called to retrieve the list of shader packs.
     * 
     * @return QStringList containing the names of available shader packs.
     */
    QStringList availableShaderPacks() const;

    /**!
     * @brief refreshShaderPacks
     * This function refreshes the list of available shader packs by checking
     * the shader pack directory for valid packs. It emits the shaderPacksChanged() 
     * signal if the list of available shader packs changes.
     */
    Q_INVOKABLE void refreshShaderPacks();

    /**!
     * @brief loadShaderPack
     * This function loads a shader pack from the specified file path.
     * It is expected to be called to load a specific shader pack.
     * 
     * @param name The name of the shader pack file to load.
     */
    Q_INVOKABLE void loadShaderPack(const QString &name);

    /**!
     * @brief importShaderPack
     * This function imports a shader pack from the specified file path.
     * It is expected to be called to be either a zip or tarball structured
     * as described in the wiki.
     * 
     * @param filePath The path to the shader pack file to import.
     */
    Q_INVOKABLE void importShaderPack(const QString &filePath);

    /**!
     * @brief state
     * This function returns the current state of the model.
     * It is expected to be called to retrieve the current state.
     * 
     * @return State representing the current state of the model.
     */
    State state() const;
    
    QString shaderPackPath() const;
    QString shaderPackName() const;
    QString shaderPackInstallPath() const;

    QString shadersPath() const;
    QString imagesPath() const;
    QString cubeMapsPath() const;
    QString videosPath() const;

    protected:
    void setState(State state);
    void setShaderPackPath(const QString &filePath);

Q_SIGNALS:
    void shaderPackPathChanged();
    void shaderPackNameChanged();
    void shaderPackInstallPathChanged();
    void jsonChanged();
    void shaderPacksChanged();
    void stateChanged();
    void error(const QString &errorString);

private:
    QString m_shaderPackPath;
    QString m_shaderPackName;
    const QString m_shaderPackInstallPath;

    const QString m_shadersPath;
    const QString m_imagesPath;
    const QString m_cubeMapsPath;
    const QString m_videosPath;

    QString m_json;
    QMap<QString, QString> m_availableShaderPacks; // Maps shader pack names to their file paths
    State m_state = Idle;

    Q_PROPERTY(QString json READ json WRITE loadJson NOTIFY jsonChanged)
    Q_PROPERTY(QStringList availableShaderPacks READ availableShaderPacks NOTIFY shaderPacksChanged)
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString shaderPackPath READ shaderPackPath NOTIFY shaderPackPathChanged)
    Q_PROPERTY(QString shaderPackName READ shaderPackName NOTIFY shaderPackNameChanged)
    Q_PROPERTY(QString shaderPackInstallPath READ shaderPackInstallPath NOTIFY shaderPackInstallPathChanged)

    Q_PROPERTY(QString shadersPath READ shadersPath CONSTANT)
    Q_PROPERTY(QString imagesPath READ imagesPath CONSTANT)
    Q_PROPERTY(QString cubeMapsPath READ cubeMapsPath CONSTANT)
    Q_PROPERTY(QString videosPath READ videosPath CONSTANT)
};

Q_DECLARE_METATYPE(ShaderPackModel)

#endif // SHADERPACKMODEL_H