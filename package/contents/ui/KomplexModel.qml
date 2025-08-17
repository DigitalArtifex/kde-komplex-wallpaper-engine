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

    property var bufferA: null
    property var bufferB: null
    property var bufferC: null
    property var bufferD: null

    id: mainItem

    Item
    {
        id: data
        property var channels: []
    }

    Komplex.ShaderPackModel
    {
        id: shaderPackModel
        onJsonChanged: () =>
        {
            // clean up old channels
            while(data.channels.length > 0)
                data.channels.pop().destroy()
                
            // Handle the JSON change if needed
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
                mainItem.iFrame += 1
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

        if (pack.bufferA)
            mainItem.bufferA = parseChannel(pack.bufferA, 2);
        if (pack.bufferB)
            mainItem.bufferB = parseChannel(pack.bufferB, 2);
        if (pack.bufferC)
            mainItem.bufferC = parseChannel(pack.bufferC, 2);
        if (pack.bufferD)
            mainItem.bufferD = parseChannel(pack.bufferD, 2);

        if (pack.channel0)
        {
            if(typeof pack.channel0 === "string")
            {
                switch(pack.channel0)
                {
                    case "{bufferA}":
                        channelOutput.iChannel0 = mainItem.bufferA
                        break;
                    case "{bufferB}":
                        channelOutput.iChannel0 = mainItem.bufferB
                        break;
                    case "{bufferC}":
                        channelOutput.iChannel0 = mainItem.bufferC
                        break;
                    case "{bufferD}":
                        channelOutput.iChannel0 = mainItem.bufferD
                        break;
                    default:
                        console.log('Uknown channel type ' + pack.channel0)
                        break;
                }
                
            }
            else if(typeof pack.channel0 === "object")
                channelOutput.iChannel0 = parseChannel(pack.channel0);
        }
        if (pack.channel1)
        {
            if(typeof pack.channel1 === "string")
            {
                switch(pack.channel1)
                {
                    case "{bufferA}":
                        channelOutput.iChannel1 = mainItem.bufferA
                        break;
                    case "{bufferB}":
                        channelOutput.iChannel1 = mainItem.bufferB
                        break;
                    case "{bufferC}":
                        channelOutput.iChannel1 = mainItem.bufferC
                        break;
                    case "{bufferD}":
                        channelOutput.iChannel1 = mainItem.bufferD
                        break;
                    default:
                        console.log('Uknown channel type ' + pack.channel1)
                        break;
                }
                
            }
            else if(typeof pack.channel1 === "object")
                channelOutput.iChannel1 = parseChannel(pack.channel1);
        }
        if (pack.channel2)
        {
            if(typeof pack.channel2 === "string")
            {
                switch(pack.channel2)
                {
                    case "{bufferA}":
                        channelOutput.iChannel2 = mainItem.bufferA
                        break;
                    case "{bufferB}":
                        channelOutput.iChannel2 = mainItem.bufferB
                        break;
                    case "{bufferC}":
                        channelOutput.iChannel2 = mainItem.bufferC
                        break;
                    case "{bufferD}":
                        channelOutput.iChannel2 = mainItem.bufferD
                        break;
                    default:
                        console.log('Uknown channel type ' + pack.channel2)
                        break;
                }
                
            }
            else if(typeof pack.channel2 === "object")
                channelOutput.iChannel2 = parseChannel(pack.channel2);
        }
        if (pack.channel3)
        {
            if(typeof pack.channel3 === "string")
            {
                switch(pack.channel3)
                {
                    case "{bufferA}":
                        channelOutput.iChannel3 = mainItem.bufferA
                        break;
                    case "{bufferB}":
                        channelOutput.iChannel3 = mainItem.bufferB
                        break;
                    case "{bufferC}":
                        channelOutput.iChannel3 = mainItem.bufferC
                        break;
                    case "{bufferD}":
                        channelOutput.iChannel3 = mainItem.bufferD
                        break;
                    default:
                        console.log('Uknown channel type ' + pack.channel3)
                        break;
                }
                
            }
            else if(typeof pack.channel3 === "object")
                channelOutput.iChannel3 = parseChannel(pack.channel3);
        }

        channelOutput.source = getFilePath(pack.source); // Set the shader source file
        channelOutput.type = ShaderChannel.Type.ShaderChannel; // Set the shader

        if(pack.mouse_scale)
            channelOutput.mouseBias = pack.mouse_scale

        if(pack.speed)
            channelOutput.iTimeScale = pack.speed
    }

    // Recursive helper function to parse channels
    function parseChannel(channel, typeDefault = 0)
    {
        if (!channel) return;

        var source = getFilePath(channel.source)

        // Qt.createQmlObject() method was not working the same inside plasma
        // as it was inside a QMLEngine instance. This resulted in the Loader
        // object being undefined and thus breaking the Komplex wallpaper mode. (oops)

        // Instead, use Qt.createComponent() then manually setup bindings
        var component = Qt.createComponent("./ShaderChannel.qml")
        var result

        if (component.status === Component.Ready) {
            result = component.createObject(mainItem, { x: 100, y: 100 });
        }
        result.frameBufferChannel = channel.frame_buffer_channel !== undefined ? channel.frame_buffer_channel : -1
        result.type = channel.type ? channel.type : typeDefault
        result.anchors.fill = mainItem
        result.visible = false
        result.iMouse = Qt.binding(() => { return mainItem.iMouse; })
        result.iTime = Qt.binding(() => { return mainItem.iTime; })
        result.iResolution = Qt.binding(() => { return Qt.vector3d(channel.resolution_x || mainItem.width, channel.resolution_y || mainItem.height, 1.0); })
        result.mouseBias = channel.mouse_scale ? channel.mouse_scale : 1.0
        result.iTimeScale = channel.time_scale ? channel.time_scale : 1.0
        result.iTimeDelta = Qt.binding(() => { return mainItem.iTimeDelta; })

        result.iChannelResolution = Qt.binding(() => {
            return [
                Qt.vector3d(channel.resolution_x || mainItem.width, channel.resolution_y || mainItem.height, 1.0),
                Qt.vector3d(channel.resolution_x || mainItem.width, channel.resolution_y || mainItem.height, 1.0),
                Qt.vector3d(channel.resolution_x || mainItem.width, channel.resolution_y || mainItem.height, 1.0),
                Qt.vector3d(channel.resolution_x || mainItem.width, channel.resolution_y || mainItem.height, 1.0)
            ];
        });

        result.iChannelTime = Qt.binding(() => {
            return [
                mainItem.iTime * result.iTimeScale,
                mainItem.iTime * result.iTimeScale,
                mainItem.iTime * result.iTimeScale,
                mainItem.iTime * result.iTimeScale
            ];
        });

        result.iFrameRate = Qt.binding(() => { return mainItem.iFrameRate; })
        result.iFrame = Qt.binding(() => { return mainItem.iFrame; })
        result.invert = channel.invert ? channel.invert : false

        result.source = source

        if (channel.channel0)
        {
            if(typeof channel.channel0 === "string")
            {
                switch(channel.channel0)
                {
                    case "{bufferA}":
                        result.iChannel0 = mainItem.bufferA
                        break;
                    case "{bufferB}":
                        result.iChannel0 = mainItem.bufferB
                        break;
                    case "{bufferC}":
                        result.iChannel0 = mainItem.bufferC
                        break;
                    case "{bufferD}":
                        result.iChannel0 = mainItem.bufferD
                        break;
                    default:
                        console.log('Uknown channel type ' + channel.channel0)
                        break;
                }
                
            }
            else if(typeof channel.channel0 === "object")
                result.iChannel0 = parseChannel(channel.channel0);
        }
        if (channel.channel1)
        {
            if(typeof channel.channel1 === "string")
            {
                switch(channel.channel1)
                {
                    case "{bufferA}":
                        result.iChannel1 = mainItem.bufferA
                        break;
                    case "{bufferB}":
                        result.iChannel1 = mainItem.bufferB
                        break;
                    case "{bufferC}":
                        result.iChannel1 = mainItem.bufferC
                        break;
                    case "{bufferD}":
                        result.iChannel1 = mainItem.bufferD
                        break;
                    default:
                        console.log('Uknown channel type ' + channel.channel1)
                        break;
                }
                
            }
            else if(typeof channel.channel1 === "object")
                result.iChannel1 = parseChannel(channel.channel1);
        }
        if (channel.channel2)
        {
            if(typeof channel.channel2 === "string")
            {
                switch(channel.channel2)
                {
                    case "{bufferA}":
                        result.iChannel2 = mainItem.bufferA
                        break;
                    case "{bufferB}":
                        result.iChannel2 = mainItem.bufferB
                        break;
                    case "{bufferC}":
                        result.iChannel2 = mainItem.bufferC
                        break;
                    case "{bufferD}":
                        result.iChannel2 = mainItem.bufferD
                        break;
                    default:
                        console.log('Uknown channel type ' + channel.channel2)
                        break;
                }
                
            }
            else if(typeof channel.channel2 === "object")
                result.iChannel2 = parseChannel(channel.channel2);
        }
        if (channel.channel3)
        {
            if(typeof channel.channel3 === "string")
            {
                switch(channel.channel3)
                {
                    case "{bufferA}":
                        result.iChannel3 = mainItem.bufferA
                        break;
                    case "{bufferB}":
                        result.iChannel3 = mainItem.bufferB
                        break;
                    case "{bufferC}":
                        result.iChannel3 = mainItem.bufferC
                        break;
                    case "{bufferD}":
                        result.iChannel3 = mainItem.bufferD
                        break;
                    default:
                        console.log('Uknown channel type ' + channel.channel3)
                        break;
                }
                
            }
            else if(typeof channel.channel3 === "object")
                result.iChannel3 = parseChannel(channel.channel3);
        }

        data.channels.push(result) // save for destroying

        return result;
    }

    function getFilePath(source)
    {
        if(source === undefined || source === "") 
            return "";

        // Ensure the source path is correctly resolved for relative paths
        if(source.startsWith("./"))
        {
            var temp = source.replace("./", "file://" + shaderPackModel.shaderPackPath + "/")
            return temp;
        }
        else if(source.startsWith("$/"))
        {
            var temp = source.replace("$/", "file://" + StandardPaths.writableLocation(StandardPaths.HomeLocation) + "/.local/share/komplex/")
            return temp;
        }
        else if(!source.startsWith("file://"))
            return "file://" + source;
    }
}
