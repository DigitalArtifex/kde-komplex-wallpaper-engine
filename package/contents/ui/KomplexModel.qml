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
    property bool ready: false


    // Individual channel resolutions to customize performance and quality
    property var iChannelResolution: [Qt.vector3d(wallpaper.configuration.iChannel0_resolution_x, wallpaper.configuration.iChannel0_resolution_y, pixelRatio),
                                      Qt.vector3d(wallpaper.configuration.iChannel1_resolution_x, wallpaper.configuration.iChannel1_resolution_y, pixelRatio),
                                      Qt.vector3d(wallpaper.configuration.iChannel2_resolution_x, wallpaper.configuration.iChannel2_resolution_y, pixelRatio),
                                      Qt.vector3d(wallpaper.configuration.iChannel3_resolution_x, wallpaper.configuration.iChannel3_resolution_y, pixelRatio)]

    property string iChannel0: ""
    property string iChannel1: ""
    property string iChannel2: ""
    property string iChannel3: ""
    
    property var pack: wallpaper.configuration.shader_package

    onPackChanged: ()=>
    {
        if(mainItem.ready)
            shaderPackModel.loadJson(pack)
    }

    ShaderChannel { id: bufferA; visible: true; anchors.fill: parent }
    ShaderChannel { id: bufferB; visible: true; anchors.fill: parent }
    ShaderChannel { id: bufferC; visible: true; anchors.fill: parent }
    ShaderChannel { id: bufferD; visible: true; anchors.fill: parent }
    

    id: mainItem

    Item
    {
        id: data
        property var channels: []
        property var buffers: new Map()
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
        data.buffers.set("{bufferA}", bufferA)
        data.buffers.set("{bufferB}", bufferB)
        data.buffers.set("{bufferC}", bufferC)
        data.buffers.set("{bufferD}", bufferD)

        if(wallpaper.configuration.shader_package)
            shaderPackModel.loadJson(wallpaper.configuration.shader_package);

        ready = true
    }

    // Recursive helper function to parse channels
    function parseChannel(channel, json, typeDefault = 2)
    {
        var source = getFilePath(json.source)

        channel.frameBufferChannel = json.frame_buffer_channel !== undefined ? json.frame_buffer_channel : -1
        channel.type = json.type !== undefined ? json.type : typeDefault
        channel.anchors.fill = channel.parent
        channel.visible = false
        channel.iMouse = Qt.binding(() => { return mainItem.iMouse; })
        channel.iTime = Qt.binding(() => { return mainItem.iTime; })
        channel.iResolution = Qt.binding(() => { return Qt.vector3d(json.resolution_x || mainItem.width, json.resolution_y || mainItem.height, 1.0); })
        channel.mouseBias = json.mouse_scale ? json.mouse_scale : 1.0
        channel.iTimeScale = json.time_scale ? json.time_scale : 1.0
        channel.iTimeDelta = Qt.binding(() => { return mainItem.iTimeDelta; })

        channel.iChannelResolution = Qt.binding(() => {
            return [
                Qt.vector3d(json.resolution_x || mainItem.width, json.resolution_y || mainItem.height, 1.0),
                Qt.vector3d(json.resolution_x || mainItem.width, json.resolution_y || mainItem.height, 1.0),
                Qt.vector3d(json.resolution_x || mainItem.width, json.resolution_y || mainItem.height, 1.0),
                Qt.vector3d(json.resolution_x || mainItem.width, json.resolution_y || mainItem.height, 1.0)
            ];
        });

        channel.iChannelTime = Qt.binding(() => {
            return [
                mainItem.iTime * channel.iTimeScale,
                mainItem.iTime * channel.iTimeScale,
                mainItem.iTime * channel.iTimeScale,
                mainItem.iTime * channel.iTimeScale
            ];
        });

        channel.iFrameRate = Qt.binding(() => { return mainItem.iFrameRate; })
        channel.iFrame = Qt.binding(() => { return mainItem.iFrame; })
        channel.invert = json.invert ? json.invert : false

        channel.source = source

        if (json.channel0)
        {
            if(typeof json.channel0 === "string")
            {
                if(data.buffers.has(json.channel0))
                    channel.iChannel0 = createBufferAssociation(json.channel0)
                else
                    console.log('Uknown channel buffer 0 ' + json.channel0)
            }
            else if(typeof json.channel0 === "object")
            {
                var component = Qt.createComponent("./ShaderChannel.qml")

                if (component.status === Component.Ready) { 
                    channel.iChannel0 = component.createObject(mainItem, {  })
                    parseChannel(channel.iChannel0, json.channel0)
                    data.channels.push(channel.iChannel0) // save for destroying
                }
            }
            else
                console.log('Uknown channel type 0 ' + typeof json.channel0)
        }

        if (json.channel1)
        {
            if(typeof json.channel1 === "string")
            {
                if(data.buffers.has(json.channel1))
                    channel.iChannel1 = createBufferAssociation(json.channel1)
                else
                    console.log('Uknown channel buffer 1 ' + json.channel1)
            }
            else if(typeof json.channel1 === "object")
            {
                var component = Qt.createComponent("./ShaderChannel.qml")

                if (component.status === Component.Ready) { 
                    channel.iChannel1 = component.createObject(mainItem, { })
                    parseChannel(channel.iChannel1, json.channel1)

                    data.channels.push(channel.iChannel1) // save for destroying
                }
            }
            else
                console.log('Uknown channel type 1 ' + typeof json.channel1)
        }

        if (json.channel2)
        {
            if(typeof json.channel2 === "string")
            {
                if(data.buffers.has(json.channel2))
                    channel.iChannel2 = createBufferAssociation(json.channel2)
                else
                    console.log('Uknown channel buffer 2 ' + json.channel2)
            }
            else if(typeof json.channel2 === "object")
            {
                var component = Qt.createComponent("./ShaderChannel.qml")

                if (component.status === Component.Ready) { 
                    channel.iChannel2 = component.createObject(mainItem, { })
                    parseChannel(channel.iChannel2, json.channel2)

                    data.channels.push(channel.iChannel2) // save for destroying
                }
            }
            else
                console.log('Uknown channel type 2 ' + typeof json.channel2)
        }

        if (json.channel3)
        {
            if(typeof json.channel3 === "string")
            {
                if(data.buffers.has(json.channel3))
                    channel.iChannel3 = createBufferAssociation(json.channel3)
                else
                    console.log('Uknown channel buffer 3 ' + json.channel3)
            }
            else if(typeof json.channel3 === "object")
            {
                var component = Qt.createComponent("./ShaderChannel.qml")

                if (component.status === Component.Ready) { 
                    channel.iChannel3 = component.createObject(mainItem, { })
                    parseChannel(channel.iChannel3, json.channel3)

                    data.channels.push(channel.iChannel3) // save for destroying
                }
            }
            else
                console.log('Uknown channel type 3 ' + typeof json.channel3)
        }
    }

    // Function to parse the pack.json file and set the properties of the ShaderChannel
    function parsePack(json) 
    {
        var pack = JSON.parse(json);
        var currentChannel = null;

        if (pack.bufferA)
            parseChannel(bufferA, pack.bufferA, 2);
        if (pack.bufferB)
            parseChannel(bufferB, pack.bufferB, 2);
        if (pack.bufferC)
            parseChannel(bufferC, pack.bufferC, 2);
        if (pack.bufferD)
            parseChannel(bufferD, pack.bufferD, 2);

        parseChannel(channelOutput, pack, 2)

        channelOutput.source = getFilePath(pack.source); // Set the shader source file
        channelOutput.type = ShaderChannel.Type.ShaderChannel; // Set the shader
        channelOutput.visible = true

        if(pack.mouse_scale)
            channelOutput.mouseBias = pack.mouse_scale

        if(pack.speed)
            channelOutput.iTimeScale = pack.speed
    }

    // Generate a new ShaderEffectSource for the requested buffer
    function createBufferAssociation(buffer)
    {

        var component = Qt.createComponent('./ShaderBuffer.qml')
        var result

        if (component.status === Component.Ready) {
            result = component.createObject(mainItem, {
                x:0,
                y:0,
                sourceItem: data.buffers.get(buffer),
                live: true,
                sourceRect: Qt.binding(() => { return Qt.rect(0,0,data.buffers.get(buffer).width || 0,data.buffers.get(buffer).height || 0); }),
                visible: false,
                z:0,
                wrapMode: ShaderEffectSource.Repeat,
                textureMirroring: ShaderEffectSource.NoMirroring,
                textureSize: Qt.size(Qt.binding(() => { return data.buffers.get(buffer).width || 0; } ), Qt.binding(() => { return data.buffers.get(buffer).height || 0; } )),
                recursive: false,
                mipmap: false
            });
        }

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
