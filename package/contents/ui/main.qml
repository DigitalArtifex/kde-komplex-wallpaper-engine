import QtCore
import QtQuick
import QtQml

import org.kde.plasma.core
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

WallpaperItem 
{
    Item
    {
        anchors.fill: parent
        
        Loader 
        {
            id: pageLoader
            anchors.fill: parent
            active: true
            sourceComponent: shaderToysContent

            states: [
                State
                {
                    when: wallpaper.komplex_mode === 0
                    PropertyChanges
                    {
                        pageLoader.sourceComponent: shaderToysContent
                    }
                },
                State
                {
                    when: wallpaper.komplex_mode === 1
                    PropertyChanges
                    {
                        pageLoader.sourceComponent: packContent
                    }
                }
            ]
        }

        Component
        {
            id: shaderToysContent

            ShaderToyModel
            {
                anchors.fill: parent
            }
        }

        Component
        {
            id: packContent

            KomplexModel
            {
                anchors.fill: parent
            }
        }
    }
}