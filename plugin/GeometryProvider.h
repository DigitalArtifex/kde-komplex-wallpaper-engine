/*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  GeometryProvider.h
 * 
 *  This class provides a way to use .obj and .stl in QML
 * 
 *  The loadObj() and loadStl() functions are from stl-gcode-viewer
 *  Copyright 2015-2025 @sokunmin | github.com/sokunmin
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
#ifndef  GeometryProvider_H
#define  GeometryProvider_H

#define READ_VECTOR(v)\
do {\
    float f;\
    file.read((char*)&f, sizeof(float));	v[0] = f;\
    file.read((char*)&f, sizeof(float));	v[1] = f;\
    file.read((char*)&f, sizeof(float));	v[2] = f;\
} while(false)

#include <QObject>
#include <QQuick3DGeometry>
#include <QFile>
#include <QFileInfo>
#include <QVector3D>
#include <QMatrix4x4>

#include "Komplex_global.h"

class KOMPLEX_EXPORT GeometryProvider : public QQuick3DGeometry
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(bool hasNormals READ hasNormals WRITE setHasNormals NOTIFY hasNormalsChanged)
    Q_PROPERTY(bool hasUv READ hasUv WRITE setHasUv NOTIFY hasUvChanged)
    Q_PROPERTY(qreal uvAdjust READ uvAdjust WRITE setUVAdjust NOTIFY uvAdjustChanged)
    Q_PROPERTY(QString source READ source WRITE setSource NOTIFY sourceChanged)

public:
    enum State
    {
        Idle,
        Loading,
        Loaded,
        Error
    };

    GeometryProvider(QQuick3DObject *parent = nullptr);

    bool hasNormals() const { return m_hasNormals; }
    void setHasNormals(bool enable);

    bool hasUv() const { return m_hasUV; }
    void setHasUv(bool enable);

    float uvAdjust() const { return m_uvAdjust; }
    void setUVAdjust(qreal f);

    QString source() const { return m_source; }
    void setSource(QString &source);

Q_SIGNALS:
    void normalsChanged();
    void hasNormalsChanged();
    void uvChanged();
    void hasUvChanged();
    void uvAdjustChanged();
    void sourceChanged();

private:
    void loadObj(QFile &file);
    void loadStl(QFile &file);
    void recomputeAll();

    bool m_hasNormals = false;
    bool m_hasUV = false;
    
    qreal m_uvAdjust = 0.0f;
    QString m_source;

    QVector3D m_size;
    QVector3D m_center;
    QVector3D m_min;
    QVector3D m_max;
    QMatrix4x4 m_transform;

    QVector<QVector3D> m_vertices;
    QVector<QVector3D> m_verticesNew;
    QVector<QVector3D> m_normals;
    QVector<QVector2D> m_uv;

    QVector<int> m_edgeIndices;
    QVector<int> m_vertexIndices;
};

Q_DECLARE_METATYPE(GeometryProvider)
#endif