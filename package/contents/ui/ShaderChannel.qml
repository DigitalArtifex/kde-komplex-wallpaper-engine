/*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  ShaderChannel.qml
 *  
 *  This component provides a configurable channel type to more closely resemble how ShaderToys
 *  works. It can be configured to be an Image, Video, Shader, Audio, or CubeMap that can be
 *  used as the input channel of another ShaderChannel, allowing for more complex shader compositions.
 *
 *  It would also appear that in order to support the audio channel, we will need to
 *  implement a way to capture the desktop audio in C++, as the MediaPlayer component does not support this.
 *  This will have to come later.
 *  
 *  Volumetric shaders do not seem to be widely used in ShaderToys, so it has not been implemented here.
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
pragma ComponentBehavior: Bound

import QtQuick
import QtMultimedia
import QtQuick3D

import com.github.digitalartifex.komplex 1.0 as Komplex

Item
{
    enum Type
    {
        ImageChannel,
        VideoChannel,
        ShaderChannel,
        CubeMapChannel,
        AudioChannel
    }

    property int type: ShaderChannel.Type.ImageChannel
    property string source: ""

    property int fillMode: Image.PreserveAspectCrop

    property var iChannel0: null
    property var iChannel1: null
    property var iChannel2: null
    property var iChannel3: null

    property vector3d iResolution
    property real iResolutionScale: 1 // This is used to scale the resolution of the shader, allowing for performance optimizations
    property real iTime: 0 //used by most motion shaders
    property real iTimeDelta: 0
    property var iChannelTime: [data.iTime, data.iTime, data.iTime, data.iTime] //individual channel time values
    property real iSampleRate: 44100 //used by audio shaders
    property int iFrame: 0
    property var iFrameRate: 60
    property vector4d iMouse
    property real mouseBias: 1
    property var iDate
    property real iTimeScale: 1 // This is used to scale the time for the shader, allowing for slow motion or fast forward effects per channel

    property bool invert

    property var iChannelResolution: [Qt.vector3d(channel.width * iResolutionScale, channel.height * iResolutionScale, 1), Qt.vector3d(channel.width * iResolutionScale, channel.height * iResolutionScale, 1), Qt.vector3d(channel.width * iResolutionScale, channel.height * iResolutionScale, 1)]

    QtObject
    {
        id: data

        property vector4d iMouse: Qt.vector4d(channel.iMouse.x * channel.mouseBias, channel.iMouse.y * channel.mouseBias, channel.iMouse.z, channel.iMouse.w)
        property real iTime: 0
        property real lastITime: 0
        property real angle: channel.invert ? 180 : 0
    }

    onITimeChanged: 
    {
        iTimeDelta = iTime - data.lastITime
        data.lastITime = iTime
        data.iTime += iTimeDelta * iTimeScale
    }

    id: channel
    visible: false // Set to false by default, main shader needs be set to true in MainWindow.qml

    // This is used to dynamically load the appropriate channel type based on the `type` property of the channel
    Loader
    {
        id: loader
        anchors.fill: channel.invert ? null : parent

        sourceComponent: channelImage

        states:[
            State
            {
                when: channel.type === ShaderChannel.Type.ImageChannel
                PropertyChanges
                {
                    loader.sourceComponent: channelImage
                }
            },
            State
            {
                when: channel.type === ShaderChannel.Type.VideoChannel
                PropertyChanges
                {
                    loader.sourceComponent: channelVideo
                }
            },
            State
            {
                when: channel.type === ShaderChannel.Type.CubeMapChannel
                PropertyChanges
                {
                    loader.sourceComponent: channelCubeMap
                }
            },
            State
            {
                when: channel.type === ShaderChannel.Type.ShaderChannel
                PropertyChanges
                {
                    loader.sourceComponent: channelShader
                }
            },
            State
            {
                when: channel.type === ShaderChannel.Type.AudioChannel
                PropertyChanges
                {
                    loader.sourceComponent: channelAudio

                    loader.width: 512
                    loader.height: 2
                }
            }
        ]

        transform: Rotation
        {
            id: channelRotation
            origin.x: channel.width / 2
            origin.y: channel.height / 2

            // For vertical flipping, we need to transform the x axis
            axis
            {
                x: 1
                y: 0
                z: 0
            }

            angle: data.angle
        }
    }

    //The image channel will be the default channel type for backwards compatability
    Component
    {
        id: channelImage

        Image
        {
            id: image
            anchors.fill: parent
            source: Qt.resolvedUrl(channel.source)
            fillMode: channel.fillMode
        }
    }

    //Video channel 
    Component
    {
        id: channelVideo

        VideoOutput
        {
            property alias duration: mediaPlayer.duration
            property alias mediaSource: mediaPlayer.source
            property alias metaData: mediaPlayer.metaData
            property alias playbackRate: mediaPlayer.playbackRate
            property alias position: mediaPlayer.position
            property alias seekable: mediaPlayer.seekable
            property alias volume: audioOutput.volume

            signal sizeChanged
            signal fatalError

            id: videoOutput

            visible: true
            anchors.fill: parent
            fillMode: VideoOutput.PreserveAspectCrop
            smooth: true

            onHeightChanged: this.sizeChanged()

            MediaPlayer 
            {
                id: mediaPlayer
                videoOutput: videoOutput
                loops: MediaPlayer.Infinite
                source: Qt.resolvedUrl(channel.source)

                audioOutput: AudioOutput 
                {
                    id: audioOutput
                    volume: 0
                }

                onErrorOccurred: function(error, errorString) 
                {
                    if (MediaPlayer.NoError !== error) 
                    {
                        console.log("[qmlvideo] VideoItem.onError error " + error + " errorString " + errorString)
                        videoOutput.fatalError()
                    }
                }

                onSourceChanged: 
                {
                    if(mediaPlayer.source != "")
                        mediaPlayer.play()
                    else
                        mediaPlayer.stop()
                }
            }

            function start() { mediaPlayer.play() }
            function stop() { mediaPlayer.stop() }
            function seek(position) { mediaPlayer.setPosition(position); }
        }
    }

    // A shader channel can be a shader
    Component
    {
        id: channelShader

        Item
        {
            // Setup the shader effect sources for each channel
            // These are needed to provide the uniform data to the shader channel buffers
            ShaderEffectSource
            {
                id: channelSource0
                sourceItem: channel.iChannel0 ? channel.iChannel0 : null
                live: true
                smooth: true
                sourceRect: Qt.rect(0,0, sourceItem ? sourceItem.width : 0, sourceItem ? sourceItem.height : 0)
            }

            ShaderEffectSource
            {
                id: channelSource1
                sourceItem: channel.iChannel1 ? channel.iChannel1 : null
                live: true
                smooth: true
                sourceRect: Qt.rect(0,0, sourceItem ? sourceItem.width : 0, sourceItem ? sourceItem.height : 0)
            }

            ShaderEffectSource
            {
                id: channelSource2
                sourceItem: channel.iChannel2 ? channel.iChannel2 : null
                live: true
                smooth: true
                sourceRect: Qt.rect(0,0, sourceItem ? sourceItem.width : 0, sourceItem ? sourceItem.height : 0)
            }

            ShaderEffectSource
            {
                id: channelSource3
                sourceItem: channel.iChannel3 ? channel.iChannel3 : null
                live: true
                smooth: true
                sourceRect: Qt.rect(0,0, sourceItem ? sourceItem.width : 0, sourceItem ? sourceItem.height : 0)
            }

            // The shader effect that will be used to render the shader
            ShaderEffect
            {
                property var iChannel0: channelSource0
                property var iChannel1: channelSource1
                property var iChannel2: channelSource2
                property var iChannel3: channelSource3

                property var iResolution: channel.iResolution
                property var iTime: data.iTime
                property var iTimeDelta: channel.iTimeDelta
                property var iChannelTime: channel.iChannelTime
                property var iSampleRate: channel.iSampleRate
                property var iFrame: channel.iFrame
                property var iFrameRate: channel.iFrameRate
                property var iMouse: data.iMouse
                property var iDate: channel.iDate

                property var iChannelResolution: channel.iResolution

                fragmentShader: Qt.resolvedUrl(channel.source)
                anchors.fill: parent
            }
        }
    }

    //In order to support CubeMaps, we will need to select a folder that contains a series of JPGs, named as described 
    //in the CubeMapTexture documentation ie "posx.jpg;negx.jpg;posy.jpg;negy.jpg;posz.jpg;negz.jpg"
    Component
    {
        id: channelCubeMap

        View3D 
        {
            id: view3d
            anchors.fill: parent

            property real lastX: 0
            property real lastY: 0
            property bool mousePressed: false
            property real yaw: 0
            property real pitch: 0

            environment: SceneEnvironment 
            {
                backgroundMode: SceneEnvironment.SkyBoxCubeMap
                skyBoxCubeMap: CubeMapTexture 
                {
                    source: channel.source !== "" ? Qt.resolvedUrl(channel.source) + "/%p.jpg" : ""
                }
            }

            camera: PerspectiveCamera 
            {
                id: camera
                position: Qt.vector3d(0, 0, 10)
            }

            function updateCamera() 
            {
                yaw -= (data.iMouse.x - lastX) * 0.5
                pitch -= (data.iMouse.y - lastY) * -0.5
                pitch = Math.max(-89, Math.min(89, pitch))
                lastX = data.iMouse.x
                lastY = data.iMouse.y

                var radYaw = yaw * Math.PI / 180
                var radPitch = pitch * Math.PI / 180
                var x = Math.cos(radPitch) * Math.sin(radYaw)
                var y = Math.sin(radPitch)
                var z = Math.cos(radPitch) * Math.cos(radYaw)

                camera.eulerRotation = Qt.vector3d((radPitch * 180 / Math.PI), (radYaw * 180 / Math.PI), 0)
            }

            Connections
            {
                target: channel
                function onIMouseChanged() 
                {
                    view3d.updateCamera()
                }
            }
        }
    }

    // Supporting this as an mp3 feels kinda silly. Should really figure out how to capture desktop audio with qml
    // UPDATE: This is not currently supported in QML, so we will need to implement this in C++ later
    Component
    {
        id: channelAudio

        Rectangle
        {
            anchors.fill: parent
            color: "black"
            Image
            {
                width: 512
                height: 2
                anchors.top: channel.invert ? undefined : parent.top
                anchors.bottom: channel.invert ? parent.bottom : undefined
                id: textureImage
                source: "image://audiotexture/frame"
                fillMode: Image.PreserveAspectFit
            }

            Timer
            {
                property int frame: 0
                interval: 16
                repeat: true
                triggeredOnStart: true
                running: true

                onTriggered:
                {
                    frame++
                    textureImage.source = "image://audiotexture/frame" + frame
                }
            }

            Component.onCompleted:
            {
                Komplex.AudioModel.startCapture()
            }
        }
    }
}