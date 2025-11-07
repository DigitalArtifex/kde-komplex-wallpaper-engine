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

Rectangle
{
    property var screenGeometry
    property real pixelRatio: 1 //This will (hopefully) be set to PlasmaCore.Units.devicePixelRatio in onCompleted
    property vector3d iResolution: Qt.vector3d(wallpaper.configuration.resolution_x, wallpaper.configuration.resolution_y, 1)//width, height, pixel aspect ratio
    property real iTime: 0 //used by most motion shaders 
    property real iTimeDelta: iTime 
    property var iChannelTime: [iTime, iTime, iTime, iTime] //individual channel time values
    property real iSampleRate: 44100 //used by audio shaders
    property int iFrame: 0
    property real iFrameRate: wallpaper.configuration.framerate_limit ? wallpaper.configuration.framerate_limit : 60 // Default frame rate for the shader
    property vector4d iMouse
    property var iDate
    property bool running: windowModel.runShader && wallpaper.configuration.running
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

    id: mainItem
    color: "black"

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
        width: mainItem.iResolution.x
        height: mainItem.iResolution.y
        color: "black"
        id: channelRect

        // The output channel that combines all the input channels and displays the final shader output
        // This channel must be set to a shader source file that has been pre-compiled to a QSB Fragment Shader
        ShaderChannel
        {
            property var bufferA
            property var bufferB
            property var bufferC
            property var bufferD

            iTime: mainItem.iTime
            iMouse: mainItem.iMouse
            iResolution: mainItem.iResolution
            width: mainItem.iResolution.x
            height: mainItem.iResolution.y
            iFrame: mainItem.iFrame

            id: channelOutput
            type: ShaderChannel.Type.ShaderChannel

            visible: true // Set to true to display the output
            z: 9000
            blending: true
        }

        // To save on performance, just use one timer for all channels and shaders
        // they will need to be bound to the mainItem properties they need to access
        Timer
        {
            id: channelTimer

            //Not entirely sure if this will actually limit the frame rate
            interval: (1 / mainItem.iFrameRate) * 1000 //fps to ms cycles :: fps = 60 = 1 / 60 = 0.01666 * 1000 = 16
            repeat: true

            running: mainItem.running //wallpaper.configuration.running ? mainItem.running : true

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

    ShaderEffectSource
    {
        anchors.fill: parent
        sourceItem: channelRect
        sourceRect: Qt.rect(0,0, mainItem.iResolution.x, mainItem.iResolution.y)
        textureSize: Qt.size(mainItem.iResolution.x, mainItem.iResolution.y)
        hideSource: true
        visible: true
        smooth: true
        antialiasing: true
        live: true

        id: finalSource

        onSourceRectChanged: () =>
        {
            live = false;
            live = true;
        }
    }

    // Load the default shader pack configuration on component completion
    Component.onCompleted:
    {
        data.buffers.set("{bufferA}", channelOutput.bufferA)
        data.buffers.set("{bufferB}", channelOutput.bufferB)
        data.buffers.set("{bufferC}", channelOutput.bufferC)
        data.buffers.set("{bufferD}", channelOutput.bufferD)

        if(wallpaper.configuration.shader_package)
            shaderPackModel.loadJson(wallpaper.configuration.shader_package);

        Qt.createQmlObject(`import QtQuick
        MouseArea 
        {
            id: mouseTrackingArea
            propagateComposedEvents: true
            preventStealing: false
            enabled: wallpaper.configuration.mouseAllowed
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: (mouse) => {
                mouse.accepted = false
                mainItem.iMouse.x = mouse.x * wallpaper.configuration.mouseSpeedBias
                mainItem.iMouse.y = -mouse.y * wallpaper.configuration.mouseSpeedBias
            }
            onClicked:(mouse) => {
                mouse.accepted = false
                mainItem.iMouse.z = mouse.x
                mainItem.iMouse.w = mouse.y
            }
            // this still doesnt work... guess a C++ wrapper is all that can be done?
            onPressed:(mouse) => {
                mouse.accepted = false
            }
            onPressAndHold:(mouse) => {
                mouse.accepted = false
            }
            onDoubleClicked:(mouse) => {
                mouse.accepted = false
            }
            //cancelled, entered, and exited do not pass mouse events, so we can remove them
            onReleased:(mouse) => {
                mouse.accepted = false
            }
            onWheel: (mouse) => {
                mouse.accepted = false
            }
        }`, parent.parent, "mouseTrackerArea");

        ready = true
    }

    // Recursive helper function to parse channels
    function parseChannel(channel, json, typeDefault = 2, autodestroy = true)
    {
        var component = Qt.createComponent("./ShaderChannel.qml")

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
                if (component.status === Component.Ready) 
                { 
                    channel.iChannel0 = component.createObject(mainItem, {  })
                    parseChannel(channel.iChannel0, json.channel0)
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
                if (component.status === Component.Ready) 
                { 
                    channel.iChannel1 = component.createObject(mainItem, { })
                    parseChannel(channel.iChannel1, json.channel1)
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
                if (component.status === Component.Ready) 
                {
                    channel.iChannel2 = component.createObject(mainItem, { })
                    parseChannel(channel.iChannel2, json.channel2)
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
                if (component.status === Component.Ready) 
                { 
                    channel.iChannel3 = component.createObject(mainItem, { })
                    parseChannel(channel.iChannel3, json.channel3)
                }
            }
            else
                console.log('Uknown channel type 3 ' + typeof json.channel3)
        }

        /*
            Channel Type

            parse this one first so we can handle defaults, but not ignore overrides
        */
        if(typeof json.type === "number")
        {
            channel.type = json.type
        }
        else if(typeof json.type === "string")
        {
            switch(json.type.toLowerCase())
            {
                case "image":
                    channel.type = ShaderChannel.ImageChannel
                break;
                case "audio":
                    channel.type = ShaderChannel.AudioChannel
                break;
                case "video":
                    channel.type = ShaderChannel.VideoChannel
                break;
                case "cubemap":
                    channel.type = ShaderChannel.ImageChannel
                break;
                case "shader":
                    channel.type = ShaderChannel.ShaderChannel
                break;
                case "scene":
                    channel.type = ShaderChannel.SceneChannel
                break;
                default:
                    channel.type = ShaderChannel.ImageChannel
                break;
            }
        }

        channel.frameBufferChannel = typeof json.frame_buffer_channel === "number" ? json.frame_buffer_channel : -1
        channel.iTimeScale = typeof json.time_scale === "number" ? json.time_scale : 1.0
        channel.iResolutionScale = typeof json.resolution_scale === "number" ? json.resolution_scale : 1.0
        channel.iResolution = Qt.binding(() => { return json.resolution_x ? Qt.vector3d(json.resolution_x, json.resolution_y, 1.0) : Qt.vector3d(mainItem.iResolution.x,mainItem.iResolution.y,1.0); })
        channel.mouseBias = json.mouse_scale ? json.mouse_scale : 1.0
        channel.width = Qt.binding(() => channel.iResolution.x)
        channel.height = Qt.binding(() => channel.iResolution.y)
        channel.materialTexture = typeof json.materialTexture === "string" ? getFilePath(json.materialTexture) : ""
        channel.materialShader = typeof json.materialShader === "string" ? getFilePath(json.materialShader) : ""
        channel.mipmap = typeof json.mipmap === "boolean" ? json.mipmap : true
        channel.blending = typeof json.blending === "boolean" ? json.blending : true
        channel.samples = typeof json.samples === "number" ? json.samples : 1
        channel.invert = typeof json.invert === "boolean" ? json.invert : false

        if(typeof json.source === "string")
        {
            channel.source = getFilePath(json.source)
        }
        else
        {
            channel.source = ""
        }

        /*
            Source Format
        */
        var format = ShaderEffectSource.RGB8A
        
        if(typeof json.format === "string")
        {
            switch(json.format.toLowerCase())
            {
                case "rgb8a":
                    format = ShaderEffectSource.RGB8A
                    break;
                case "rgb16f":
                    format = ShaderEffectSource.RGB16F
                    break;
                case "rgb32f":
                    format = ShaderEffectSource.RGB32F
                    break;
                default:
                    format = ShaderEffectSource.RGB8A
                    break;
            }

            console.log("Set format mode to " + format)
        }

        channel.format = format

        /*
            Source Wrap Mode
        */
        var wrapMode = ShaderEffectSource.Repeat
        
        if(typeof json.wrap_mode === "string")
        {
            switch(json.wrap_mode.toLowerCase())
            {
                case "clamptoedge":
                    wrapMode = ShaderEffectSource.ClampToEdge
                    break;
                case "repeathorizontally":
                    wrapMode = ShaderEffectSource.RepeatHorizontally
                    break;
                case "repeatvertically":
                    wrapMode = ShaderEffectSource.RepeatVertically
                    break;
                case "repeat":
                    wrapMode = ShaderEffectSource.Repeat
                    break;
                default:
                    wrapMode = ShaderEffectSource.Repeat
                    break;
            }

            console.log("Set wrap mode to " + wrapMode)
        }

        channel.wrapMode = wrapMode

        /*
            Source Mirroring Mode
        */
        var mirrorMode = ShaderEffectSource.NoMirroring
        
        if(typeof json.texture_mirroring === "string")
        {
            switch(json.texture_mirroring.toLowerCase())
            {
                case "nomirroring":
                    mirrorMode = ShaderEffectSource.NoMirroring
                    break;
                case "mirrorhorizontally":
                    mirrorMode = ShaderEffectSource.MirrorHorizontally
                    break;
                case "mirrorvertically":
                    mirrorMode = ShaderEffectSource.MirrorVertically
                    break;
                default:
                    mirrorMode = ShaderEffectSource.NoMirroring
                    break;
            }

            console.log("Set mirror mode to " + mirrorMode)
        }

        channel.textureMirroring = mirrorMode

        /*
            Non-configurable bindings
        */
        channel.iMouse = Qt.binding(() => { return mainItem.iMouse; })
        channel.iTime = Qt.binding(() => { return mainItem.iTime; })
        channel.iTimeDelta = Qt.binding(() => { return mainItem.iTimeDelta; })
        channel.iFrameRate = Qt.binding(() => { return mainItem.iFrameRate; })
        channel.iFrame = Qt.binding(() => { return mainItem.iFrame; })
        channel.visible = false
 
        channel.iChannelTime = Qt.binding(() => {
            return [
                mainItem.iTime * channel.iTimeScale,
                mainItem.iTime * channel.iTimeScale,
                mainItem.iTime * channel.iTimeScale,
                mainItem.iTime * channel.iTimeScale
            ];
        });

        if(autodestroy)
            data.channels.push(channel)
    }

    // Function to parse the pack.json file and set the properties of the ShaderChannel
    function parsePack(json) 
    {
        // clean up old channels
        while(data.channels.length > 0)
            data.channels.pop().destroy()

        var pack = JSON.parse(json);
        var currentChannel = null;

        var component = Qt.createComponent("./ShaderChannel.qml")

        if (component.status === Component.Ready)
        { 
            channelOutput.bufferA = component.createObject(channelOutput, { visible: false })
            channelOutput.bufferB = component.createObject(channelOutput, { visible: false })
            channelOutput.bufferC = component.createObject(channelOutput, { visible: false })
            channelOutput.bufferD = component.createObject(channelOutput, { visible: false })

            data.buffers.set("{bufferA}", channelOutput.bufferA)
            data.buffers.set("{bufferB}", channelOutput.bufferB)
            data.buffers.set("{bufferC}", channelOutput.bufferC)
            data.buffers.set("{bufferD}", channelOutput.bufferD)
            //parseChannel(channel.iChannel0, json.channel0)
        }

        if (pack.bufferA)
            parseChannel(channelOutput.bufferA, pack.bufferA, 2);
        if (pack.bufferB)
            parseChannel(channelOutput.bufferB, pack.bufferB, 2);
        if (pack.bufferC)
            parseChannel(channelOutput.bufferC, pack.bufferC, 2);
        if (pack.bufferD)
            parseChannel(channelOutput.bufferD, pack.bufferD, 2);

        parseChannel(channelOutput, pack, 2, false)

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

        if (component.status === Component.Ready) 
        {
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

            data.channels.push(result) // save for destroying
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