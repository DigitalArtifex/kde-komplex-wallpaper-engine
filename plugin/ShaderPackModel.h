/*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  ShaderPackModel.h
 * 
 *  This class provides metadata and file data of the komplex packs
 *  to the QML layer 
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

#include "ShaderPackMetadata.h"

class KOMPLEX_EXPORT ShaderPackModel : public QObject
{
    Q_OBJECT
    QML_ELEMENT
public:
    explicit ShaderPackModel(QObject *parent = nullptr);
    ~ShaderPackModel();

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

    /**!
     * @brief path
     * This function returns the path of the requested shader pack
     * by name
     * 
     * @return QString representing the filepath
     */
    Q_INVOKABLE QString path(const QString &name);

    ShaderPackMetadata *metadata() const;
    void setMetadata(ShaderPackMetadata *metadata);
    Q_INVOKABLE void loadMetadata(const QString &name);
    Q_INVOKABLE void loadMetadataFromFile(const QString &file);
    
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
    void metadataChanged();

private:
    QString m_shaderPackPath;
    QString m_shaderPackName;
    const QString m_shaderPackInstallPath;

    const QString m_shadersPath;
    const QString m_imagesPath;
    const QString m_cubeMapsPath;
    const QString m_videosPath;

    ShaderPackMetadata *m_metadata = nullptr; // currently reported metadata

    QString m_json;
    QMap<QString, ShaderPackMetadata*> m_availableShaderPacks; // Maps shader pack names to their file paths
    State m_state = Idle;

    Q_PROPERTY(QString json READ json WRITE loadJson NOTIFY jsonChanged)
    Q_PROPERTY(QStringList availableShaderPacks READ availableShaderPacks NOTIFY shaderPacksChanged)
    Q_PROPERTY(State state READ state NOTIFY stateChanged)
    Q_PROPERTY(QString shaderPackPath READ shaderPackPath NOTIFY shaderPackPathChanged)
    Q_PROPERTY(QString shaderPackName READ shaderPackName NOTIFY shaderPackNameChanged)
    Q_PROPERTY(QString shaderPackInstallPath READ shaderPackInstallPath NOTIFY shaderPackInstallPathChanged)
    Q_PROPERTY(ShaderPackMetadata *metadata READ metadata WRITE setMetadata NOTIFY metadataChanged)

    Q_PROPERTY(QString shadersPath READ shadersPath CONSTANT)
    Q_PROPERTY(QString imagesPath READ imagesPath CONSTANT)
    Q_PROPERTY(QString cubeMapsPath READ cubeMapsPath CONSTANT)
    Q_PROPERTY(QString videosPath READ videosPath CONSTANT)
};

Q_DECLARE_METATYPE(ShaderPackModel)

#endif // SHADERPACKMODEL_H