#include "GeometryProvider.h"
GeometryProvider::GeometryProvider(QQuick3DObject *parent) : QQuick3DGeometry{parent}
{

}

void GeometryProvider::setHasNormals(bool hasNormals)
{
    if(m_hasNormals != hasNormals)
    {
        m_hasNormals = hasNormals;
        Q_EMIT hasNormalsChanged();
    }
}

void GeometryProvider::setHasUv(bool hasUv)
{
    if(m_hasUV != hasUv)
    {
        m_hasUV = hasUv;
        Q_EMIT hasUvChanged();
    }
}

void GeometryProvider::setUVAdjust(qreal adjust)
{
    if(m_uvAdjust != adjust)
    {
        m_uvAdjust = adjust;
        Q_EMIT uvAdjustChanged();
    }
}

void GeometryProvider::setSource(QString &source)
{
    QFile file(source);
    QFileInfo fileInfo(file);

    if(!fileInfo.exists())
    {
        qWarning() << QLatin1String("File %1 does not exist").arg(fileInfo.absoluteFilePath());
        return;
    }

    if(fileInfo.suffix() == QLatin1String("obj"))
        loadObj(file);
    
    else if(fileInfo.suffix() == QLatin1String("stl"))
        loadStl(file);
}

void GeometryProvider::loadObj(QFile &file)
{
    // 1e9 = 1*10^9 = 1,000,000,000
    QVector3D boundsMin( 1e9, 1e9, 1e9);
    QVector3D boundsMax(-1e9,-1e9,-1e9);
    setHasNormals(false);
    setHasUv(false);

    QTextStream in(&file);
    while (!in.atEnd()) {
        QString input = in.readLine();
        // # means comment
        if (input.isEmpty() || input[0] == QLatin1Char('#'))
            continue;

        QTextStream ts(&input);
        QString id;
        ts >> id;
        //---------------  v = List of vertices with (x,y,z[,w]) corrdinates. -----------------
        if (id == QLatin1String("v")) {
            QVector3D p;
            for (int i = 0; i < 3; ++i)
            {
                ts >> p[i];
                boundsMin[i] = qMin(boundsMin[i], p[i]);
                boundsMax[i] = qMax(boundsMax[i], p[i]);
            }
            m_vertices << p;

        //--------------- f = Face definitions -----------------
        } else if (id == QLatin1String("f") || id == QLatin1String("fo")) {
            QVarLengthArray<int, 4> p;

            while (!ts.atEnd()) {
                QString vertex;
                ts >> vertex;
                //e.g. vertex / texture
                // vertex index in correspondence with vertex list.
                const int vertexIndex = vertex.split(QLatin1Char('/')).value(0).toInt();
//                qDebug() << "> vertexIndex : " << vertexIndex;
                if (vertexIndex) {
                    p.append((vertexIndex > 0) ? (vertexIndex - 1) : (m_vertices.size() + vertexIndex));
//                    int d = (vertexIndex > 0) ? (vertexIndex - 1) : (m_vertices.size() + vertexIndex);
//                    qDebug() << "selected index : " << d;
                }
            }

            qDebug() << QLatin1String("p.size(%1) vs. vertexIndices.size(%2)").arg(QString::number(p.size())).arg(QString::number(m_vertexIndices.size()));
            
            for (int i = 0; i < p.size(); ++i) {
                const int edgeA = p[i];
                const int edgeB = p[(i + 1) % p.size()];
//                qDebug() << QString("edgeA(%1/%2), edgeB(%3/%4)").arg(QString::number(edgeA), QString::number(i), QString::number(edgeB), QString::number((i + 1) % p.size())) ;

                if (edgeA < edgeB) {
                    m_edgeIndices << edgeA << edgeB;                    
//                    qDebug() << "Added : edgeA : " << edgeA << " / edgeB : " << edgeB ;
                }
            }

            // append vertex / texture-coordinate / normal
            for (int i = 0; i < 3; ++i)
                m_vertexIndices << p[i];

            if (p.size() == 4)
                for (int i = 0; i < 3; ++i)
                    m_vertexIndices << p[(i + 2) % 4];
        }
    }

    qDebug() << QLatin1String("size(%1), max-x(%2), min-x(%3), max-y(%4), min-y(%5), max-z(%6), min-z(%7)")
                .arg(QString::number(m_vertices.size()),
                     QString::number(boundsMax.x()),
                     QString::number(boundsMin.x()),
                     QString::number(boundsMax.y()),
                     QString::number(boundsMin.y()),
                     QString::number(boundsMax.z()),
                     QString::number(boundsMin.z()));
    const QVector3D bounds = boundsMax - boundsMin;
    const qreal scale = 1 / qMax(bounds.x(), qMax(bounds.y(), bounds.z()));
    qDebug() << QLatin1String("scale(%1) = 1 / %2")
                .arg(QString::number(scale), QString::number(qMax(bounds.x(), qMax(bounds.y(), bounds.z()))));
//    for (int i = 0; i < m_vertices.size(); ++i) {
//        //the way to place the model by mutiplying the ratio.
//        float ratio = 0.f;
//        m_vertices[i] = (m_vertices[i] - (boundsMin + bounds * ratio)) * scale;
//    }

    m_verticesNew = m_vertices;
    recomputeAll();
}

void GeometryProvider::loadStl(QFile &file)
{    
    QTextStream stream(&file);
    const QString &head = stream.readLine();
    setHasUv(false);
    if (head.left(6) == QLatin1String("solid ") && head.size() < 80)	// ASCII format
    {
//        name = head.right(head.size() - 6).toStdString();
        QString word;
        stream >> word;
        for(; word == QLatin1String("facet") ; stream >> word)
        {
            stream >> word;	// normal x y z
            QVector3D n;
            stream >> n[0] >> n[1] >> n[2];
            n.normalize();

            stream >> word >> word;	// outer loop
            stream >> word;
            size_t startIndex = m_vertices.size();
            for(; word != QLatin1String("endloop") ; stream >> word)
            {
                QVector3D v; //vertex x y z
                stream >> v[0] >> v[1] >> v[2];
                m_vertices.push_back(v);
//                qDebug() << "==== outer loop ===";
            }

            for(qsizetype i = startIndex + 2 ; i < m_vertices.size() ; ++i)
            {
                m_vertexIndices.push_back(startIndex);
                m_vertexIndices.push_back(i - 1);
                m_vertexIndices.push_back(i);

                qDebug() << QLatin1String("edgeA(%1), edgeB(%2)").arg(QString::number(startIndex), QString::number(i)) ;

//                if (startIndex < (i-1))
                    m_edgeIndices << (startIndex) << (i - 1) << i;
            }
            stream >> word;	// endfacet
            setHasNormals(false);
        }
    } else {
        file.setTextModeEnabled(false);
        file.seek(80);
        quint32 triangleCount;
        file.read((char*)&triangleCount, sizeof(triangleCount));
        m_vertices.reserve(triangleCount * 3U);
        m_normals.reserve(triangleCount * 3U);
        m_vertexIndices.reserve(triangleCount * 3U);
        for(size_t i = 0 ; i < triangleCount ; ++i)
        {
            QVector3D n, a, b, c;

            READ_VECTOR(n);
            READ_VECTOR(a);
            READ_VECTOR(b);
            READ_VECTOR(c);

            m_vertexIndices.push_back(m_vertices.size());
            m_vertexIndices.push_back(m_vertices.size() + 1);
            m_vertexIndices.push_back(m_vertices.size() + 2);
            m_vertices.push_back(a);
            m_vertices.push_back(b);
            m_vertices.push_back(c);

            quint16 attribute_byte_count;
            file.read((char*)&attribute_byte_count, sizeof(attribute_byte_count));
        }
        setHasNormals(true);
    }
    m_verticesNew = m_vertices;
    recomputeAll();
}

//Bounding Box : http://en.wikibooks.org/wiki/OpenGL_Programming/Bounding_box
void GeometryProvider::recomputeAll()
{
    qDebug() << Q_FUNC_INFO;

    //calculate normals of each face
    int size = m_verticesNew.size();
    m_normals.resize(size);
    for (int i = 0; i < m_vertexIndices.size(); i += 3) {
        const QVector3D a = m_verticesNew.at(m_vertexIndices.at(i));
        const QVector3D b = m_verticesNew.at(m_vertexIndices.at(i+1));
        const QVector3D c = m_verticesNew.at(m_vertexIndices.at(i+2));

        const QVector3D normal = QVector3D::crossProduct(b - a, c - a).normalized();

        for (int j = 0; j < 3; ++j)
            m_normals[m_vertexIndices.at(i + j)] += normal;
    }

    /* //debug output
    qDebug() << "=========== Output =============";
    for (int i = 0; i < m_verticesNew.size(); ++i) {
        qDebug() << QString("x(%1), y(%2), z(%3)").arg(m_verticesNew.at(i).x()).arg(m_verticesNew.at(i).y()).arg(m_verticesNew.at(i).z());
    }

    for (int i = 0; i< m_vertexIndices.size(); ++i) {
        qDebug() << QString("index %1").arg(m_vertexIndices.at(i));
    }

    for (int i = 0; i < m_normals.size(); ++i ) {
        qDebug() << QString("x(%1), y(%2), z(%3)").arg(m_normals.at(i).x()).arg(m_normals.at(i).y()).arg(m_normals.at(i).z());
    }
    qDebug() << "========================";
    */
    //recompute normals and bounding volume
    qreal minX, maxX,
            minY, maxY,
            minZ, maxZ;

    minX = maxX = m_verticesNew[0].x();
    minY = maxY = m_verticesNew[0].y();
    minZ = maxZ = m_verticesNew[0].z();

    for (int i = 0; i < size; ++i) 
    {
        //compute normals
        m_normals[i] = m_normals[i].normalized();

        //calculate values of maximum and minimum
        if (m_verticesNew[i].x() < minX) minX = m_verticesNew[i].x();
        if (m_verticesNew[i].x() > maxX) maxX = m_verticesNew[i].x();
        if (m_verticesNew[i].y() < minY) minY = m_verticesNew[i].y();
        if (m_verticesNew[i].y() > maxY) maxY = m_verticesNew[i].y();
        if (m_verticesNew[i].z() < minZ) minZ = m_verticesNew[i].z();
        if (m_verticesNew[i].z() > maxZ) maxZ = m_verticesNew[i].z();
    }

    m_size   = QVector3D(maxX-minX, maxY-minY, maxZ-minZ);
    m_center = QVector3D((minX+maxX)/2, (minY+maxY)/2, (minZ+maxZ)/2);

    m_min = QVector3D(minX, minY, minZ);
    m_max = QVector3D(maxX, maxY, maxZ);

    // qDebug() << QLatin1String("MIN : x(%1), y(%2), z(%3)").arg(m_min.x()).arg(m_min.y()).arg(m_min.z());
    // qDebug() << QLatin1String("MAN : x(%1), y(%2), z(%3)").arg(m_max.x()).arg(m_max.y()).arg(m_max.z());
    // qDebug() << QLatin1String("SIZE : x(%1), y(%2), z(%3)").arg(m_size.x()).arg(m_size.y()).arg(m_size.z());

//    QMatrix4x4 center(1,1,1,1), scale(1,1,1,1);
//    m_transform.translate(QMatrix4x4(1,1,1) * center)

    int stride = 3 * sizeof(qreal);

    if(hasNormals())
        stride += 3 * sizeof(qreal);
    if(hasUv())
        stride += 2 * sizeof(qreal);

    QByteArray vertexData(3 * stride, Qt::Uninitialized);
    qreal *pointer = reinterpret_cast<qreal*>(vertexData.data());

    for(int i = 0; i < m_vertices.count(); i++)
    {
        *pointer++ = m_vertices.at(i).x();
        *pointer++ = m_vertices.at(i).y();
        *pointer++ = m_vertices.at(i).z();

        if(hasNormals())
        {
            *pointer++ = m_normals.at(i).x();
            *pointer++ = m_normals.at(i).y();
            *pointer++ = m_normals.at(i).z();
        }

        if(hasUv())
        {
            *pointer++ = m_uv.at(i).x() - m_uvAdjust;
            *pointer++ = m_uv.at(i).y() - m_uvAdjust;
        }
    }

    setBounds(m_min, m_max);
    setVertexData(vertexData);
    setStride(stride);
    
    setPrimitiveType(QQuick3DGeometry::PrimitiveType::Points);

    addAttribute(QQuick3DGeometry::Attribute::PositionSemantic,
                 0,
                 QQuick3DGeometry::Attribute::F32Type);

    if (m_hasNormals) {
        addAttribute(QQuick3DGeometry::Attribute::NormalSemantic,
                     3 * sizeof(float),
                     QQuick3DGeometry::Attribute::F32Type);
    }

    if (m_hasUV) {
        addAttribute(QQuick3DGeometry::Attribute::TexCoordSemantic,
                     m_hasNormals ? 6 * sizeof(float) : 3 * sizeof(float),
                     QQuick3DGeometry::Attribute::F32Type);
    }
}