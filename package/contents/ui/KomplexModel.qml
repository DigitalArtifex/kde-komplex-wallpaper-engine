/*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  WallpaperModel.qml
 *  
 *  This component provides a model for parsing and managing wallpaper configurations from
 *  a JSON file, specifically designed for the Komplex Wallpaper Engine.
 *
 *  This enables infinite complexity in shader configurations
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

import QtCore
import QtQuick

import com.github.digitalartifex.komplex 1.0 as Komplex

Item
{
    property var screenGeometry
    property real pixelRatio: 1 //This will (hopefully) be set to PlasmaCore.Units.devicePixelRatio in onCompleted
    property vector3d iResolution: Qt.vector3d(wallpaper.configuration.resolution_x ? wallpaper.configuration.resolution_x : 1920, wallpaper.configuration.resolution_y ? wallpaper.configuration.resolution_y : 1080, 1)//width, height, pixel aspect ratio
    property real iTime: 0 //used by most motion shaders 
    property real iTimeDelta: iTime 
    property var iChannelTime: [iTime, iTime, iTime, iTime] //individual channel time values
    property real iSampleRate: 44100 //used by audio shaders
    property int iFrame: 0
    property real iFrameRate: wallpaper.configuration.framerate_limit ? wallpaper.configuration.framerate_limit : 60 // Default frame rate for the shader
    property vector4d iMouse
    property var iDate
    property bool running: true

    // Individual channel resolutions to customize performance and quality
    property var iChannelResolution: [Qt.vector3d(wallpaper.configuration.iChannel0_resolution_x, wallpaper.configuration.iChannel0_resolution_y, pixelRatio),
                                      Qt.vector3d(wallpaper.configuration.iChannel1_resolution_x, wallpaper.configuration.iChannel1_resolution_y, pixelRatio),
                                      Qt.vector3d(wallpaper.configuration.iChannel2_resolution_x, wallpaper.configuration.iChannel2_resolution_y, pixelRatio),
                                      Qt.vector3d(wallpaper.configuration.iChannel3_resolution_x, wallpaper.configuration.iChannel3_resolution_y, pixelRatio)]

    property string iChannel0: ""
    property string iChannel1: ""
    property string iChannel2: ""
    property string iChannel3: ""

    id: mainItem

    Komplex.ShaderPackModel
    {
        id: shaderPackModel
        onJsonChanged: 
        {
            // Handle the JSON change if needed
            console.log("Shader pack JSON changed:", shaderPackModel.json);
            mainItem.parsePack(shaderPackModel.json);
        }
    }

    // The WindowModel is used to manage the interaction with the desktop environment
    WindowModel
    {
        id: windowModel
        screenGeometry: mainItem.screenGeometry
    }

    Rectangle
    {
        anchors.fill: parent
        color: "black"

        // The output channel that combines all the input channels and displays the final shader output
        // This channel must be set to a shader source file that has been pre-compiled to a QSB Fragment Shader
        ShaderChannel
        {
            iTime: mainItem.iTime
            iMouse: mainItem.iMouse
            iResolution: mainItem.iResolution

            id: channelOutput
            anchors.fill: parent
            type: ShaderChannel.Type.ShaderChannel

            visible: true // Set to true to display the output
            z: 9000
        }

        // To save on performance, just use one timer for all channels and shaders
        // they will need to be bound to the mainItem properties they need to access
        Timer
        {
            id: channelTimer

            //Not entirely sure if this will actually limit the frame rate
            interval: (1 / mainItem.iFrameRate) * 1000 //fps to ms cycles :: fps = 60 = 1 / 60 = 0.01666 * 1000 = 16
            repeat: true

            running: true //wallpaper.configuration.running ? mainItem.running : true

            triggeredOnStart: true
            onTriggered: 
            {
                var date = new Date();
                var startOfDay = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0);
                var secondsSinceMidnight = (date - startOfDay) / 1000;

                mainItem.iTime += (interval / 1000) * (wallpaper.configuration.shaderSpeed ? wallpaper.configuration.shaderSpeed : 1.0)
                mainItem.iDate = Qt.vector4d(date.getFullYear(), date.getMonth() + 1, date.getDate(), secondsSinceMidnight)
            }
        }
    }

    // Load the default shader pack configuration on component completion
    Component.onCompleted:
    {
        if(wallpaper.configuration.shader_package)
            shaderPackModel.loadJson(wallpaper.configuration.shader_package);
        else
            shaderPackModel.loadJson("/home/parametheus/kde/src/komplex/pack.json"); // Load a default shader pack if none is specified
    }

    // Function to parse the pack.json file and set the properties of the ShaderChannel
    function parsePack(json) 
    {
        var pack = JSON.parse(json);
        var currentChannel = null;

        if (pack.channel0)
            channelOutput.iChannel0 = parseChannel(pack.channel0);
        if (pack.channel1)
            channelOutput.iChannel1 = parseChannel(pack.channel1);
        if (pack.channel2)
            channelOutput.iChannel2 = parseChannel(pack.channel2);
        if (pack.channel3)
            channelOutput.iChannel3 = parseChannel(pack.channel3);

        channelOutput.source = getFilePath(pack.source); // Set the shader source file
        channelOutput.type = ShaderChannel.Type.ShaderChannel; // Set the shader

        if(pack.mouse_scale)
            channelOutput.mouseBias = pack.mouse_scale

        if(pack.speed)
            channelOutput.iTimeScale = pack.speed
    }

    // Recursive helper function to parse channels
    function parseChannel(channel)
    {
        if (!channel) return;

        var source = getFilePath(channel.source)

        var result = Qt.createQmlObject(`ShaderChannel
        {
            z: 0
            invert: ${channel.invert || true}
            iTimeScale: ${channel.time_scale || 1.0}
            iResolutionScale: ${channel.resolution_scale || 1.0}
            visible: false
            anchors.fill: parent
            source: "file://" + "${source || ''}"
            type: ${channel.type || 0}
            iTime: mainItem.iTime * ${channel.time_scale || 1.0}
            iMouse: mainItem.iMouse
            mouseBias: ${channel.mouse_scale || 1.0}
            iResolution: Qt.vector3d(${(channel.resolution_x || mainItem.width) * (channel.resolution_scale || 1.0)}, ${(channel.resolution_y || mainItem.width) * (channel.resolution_scale || 1.0)}, pixelRatio)
        }`, mainItem);

        if (channel.channel0)
            result.iChannel0 = parseChannel(channel.channel0);
        if (channel.channel1)
            result.iChannel1 = parseChannel(channel.channel1);
        if (channel.channel2)
            result.iChannel2 = parseChannel(channel.channel2);
        if (channel.channel3)
            result.iChannel3 = parseChannel(channel.channel3);

        return result;
    }

    function getFilePath(source)
    {
        if(source === "") 
            return "";

        // Ensure the source path is correctly resolved for relative paths
        if(source.startsWith("./"))
        {
            var temp = source.replace("./", "file://" + shaderPackModel.shaderPackPath + "/")
            return Qt.resolvedUrl(temp);
        }
        else if(source.startsWith("$/"))
        {
            var temp = source.replace("$/", "file://" + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/share/komplex/")
            return Qt.resolvedUrl(temp);
        }
        else if(!source.startsWith("file://"))
            return Qt.resolvedUrl("file://" + source);
    }
}
