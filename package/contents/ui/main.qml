 /*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  This file is responsible for loading the 2 different engine models
 *
 *  --------------------------------------------------------------------------------------------------------
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
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 *  This software uses some of the QML code from JaredTao/jared2020@163.com's ToyShader for Android.
 *  See: https://github.com/jaredtao/TaoShaderToy/
 */
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQml

import org.kde.plasma.core
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras as PlasmaExtras
import org.kde.plasma.plasmoid

WallpaperItem 
{
    id: wallpaperItem
    Item
    {
        property int resolution_x: wallpaper.configuration.resolution_x
        property int resolution_y: wallpaper.configuration.resolution_y
        property string shaderPack: wallpaper.configuration.shader_package
        property bool changing: false

        property bool updated: wallpaper.configuration.shader_updated

        property bool iChannel0_inverted: wallpaper.configuration.iChannel0_inverted
        property bool iChannel1_inverted: wallpaper.configuration.iChannel1_inverted
        property bool iChannel2_inverted: wallpaper.configuration.iChannel2_inverted
        property bool iChannel3_inverted: wallpaper.configuration.iChannel3_inverted

        anchors.fill: parent
        
        Loader 
        {
            id: pageLoader
            anchors.fill: parent
            active: true
            sourceComponent: wallpaper.configuration.komplex_mode === 0 ? shaderToysContent : packContent

            states: [
                State
                {
                    when: wallpaper.configuration.komplex_mode === 0
                    PropertyChanges
                    {
                        pageLoader.sourceComponent: shaderToyContent
                    }
                },
                State
                {
                    when: wallpaper.configuration.komplex_mode === 1
                    PropertyChanges
                    {
                        pageLoader.sourceComponent: packContent
                    }
                }
            ]
        }

        Component
        {
            id: shaderToyContent

            ShaderToyModel
            {
                //wallpaper: wallpaper
                screenGeometry: wallpaperItem.parent.screenGeometry
                anchors.fill: parent
            }
        }

        Component
        {
            id: packContent

            KomplexModel
            {
                screenGeometry: wallpaperItem.parent.screenGeometry
                anchors.fill: parent
            }
        }

        // band-aid section
        onResolution_xChanged: () => reload();
        onResolution_yChanged: () => reload();
        onShaderPackChanged: () => reload();
        onIChannel0_invertedChanged: () => reload();

        onUpdatedChanged: () =>
        {
            if(updated)
                reload();
        }

        function reload()
        {
            if(changing)
                return;

            changing = true

            pageLoader.sourceComponent = null

            if(wallpaper.configuration.komplex_mode === 0)
                pageLoader.sourceComponent = shaderToyContent
            else
                pageLoader.sourceComponent = packContent

            changing = false
        }
    }
}