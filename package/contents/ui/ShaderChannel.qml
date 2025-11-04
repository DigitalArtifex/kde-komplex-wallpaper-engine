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
        AudioChannel,
        SceneChannel
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
    property int frameBufferChannel: -1
    property bool blending: false
    property string materialTexture:""
    property string materialShader:""
    property var windowModel

    // bind to ShaderEffectSource.live to prevent data being updated causing a refresh between intended frames. I think this may be why
    // the shaders are using so many resources. This is likely to cause issues of its own since we have no way of knowing the progress
    // of the current capture, but we'll cross that bridge later
    property bool active: true

    // this seems to work better than doubling the timer frequency and setting active/inactive states,
    // but god damn does it feel hacky. Try to find a better way to actually limit framerate
    onIFrameChanged: () =>
    {
        // this method of frame limiting breaks video playback
        // even when the video is the source of an item being limited
        // in this way

        if(type === ShaderChannel.ShaderChannel)
        {
            active = true;
            active = false;

            return;
        }

        if(active === false)
            active = true;
    }

    property bool invert

    property var iChannelResolution: [Qt.vector3d(channel.iResolution.x * iResolutionScale, channel.iResolution.y * iResolutionScale, 1), Qt.vector3d(channel.iResolution.x * iResolutionScale, channel.iResolution.y * iResolutionScale, 1), Qt.vector3d(channel.iResolution.x * iResolutionScale, channel.iResolution.y * iResolutionScale, 1)]

    onIResolutionChanged: () =>
    {
        channel.iChannelResolution = [Qt.vector3d(channel.iResolution.x * iResolutionScale, channel.iResolution.y * iResolutionScale, 1), Qt.vector3d(channel.iResolution.x * iResolutionScale, channel.iResolution.y * iResolutionScale, 1), Qt.vector3d(channel.iResolution.x * iResolutionScale, channel.iResolution.y * iResolutionScale, 1)]
    }

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
    width: iResolution.x
    height: iResolution.y

    // This is used to dynamically load the appropriate channel type based on the `type` property of the channel
    Loader
    {
        id: loader
        anchors.fill: parent

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
                }
            },
            State
            {
                when: channel.type === ShaderChannel.Type.SceneChannel
                PropertyChanges
                {
                    loader.sourceComponent: Qt.createComponent(channel.source)
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
        Rectangle
        {
            anchors.fill: parent
            color: "black"

            VideoOutput
            {
                property alias duration: mediaPlayer.duration
                property alias mediaSource: mediaPlayer.source
                property alias metaData: mediaPlayer.metaData
                property alias playbackRate: mediaPlayer.playbackRate
                property alias position: mediaPlayer.position
                property alias seekable: mediaPlayer.seekable
                property alias volume: audioOutput.volume
                property bool loaded: false

                signal sizeChanged
                signal fatalError

                id: videoComponent

                visible: true
                anchors.fill: parent
                fillMode: VideoOutput.PreserveAspectCrop
                smooth: true

                onHeightChanged: this.sizeChanged()
            }

            MediaPlayer
            {
                id: mediaPlayer
                videoOutput: videoComponent
                loops: MediaPlayer.Infinite
                source: Qt.resolvedUrl(channel.source)
                playbackRate: channel.iTimeScale >= 0.01 ? channel.iTimeScale : 0.01

                audioOutput: AudioOutput 
                {
                    id: audioOutput
                    volume: 0
                }

                onErrorOccurred: (error, errorString) =>
                {
                    if (MediaPlayer.NoError !== error) 
                    {
                        console.log("[qmlvideo] VideoItem.onError error " + error + " errorString " + errorString)
                        videoComponent.fatalError()
                    }
                }

                onSourceChanged: 
                {
                    if(!videoComponent.loaded)
                        return;
                    delayedStartTimer.start()
                }

                onMediaStatusChanged:
                {
                    switch(mediaStatus)
                    {
                        case MediaPlayer.NoMedia:
                            console.log("No media loaded")
                            break;
                        case MediaPlayer.LoadingMedia:
                            console.log("Video loading")
                            break;
                        case MediaPlayer.LoadedMedia:
                            console.log("Video Loaded")
                            break;
                        case MediaPlayer.BufferingMedia:
                            console.log("Video buffering")
                            break;
                        case MediaPlayer.StalledMedia:
                            console.log("Video stalled")
                            break;
                        case MediaPlayer.BufferedMedia:
                            console.log("Video buffered")
                            break;
                        case MediaPlayer.EndOfMedia:
                            console.log("Video EOF")
                            break;
                        case MediaPlayer.InvalidMedia:
                            console.log("Video invalid")
                            break;
                    }
                }

                onPlaybackStateChanged:
                {
                    switch(playbackState)
                    {
                        case MediaPlayer.PlayingState:
                            console.log("Video playback started")
                            break;
                        case MediaPlayer.PausedState:
                            console.log("Video playback paused")
                            break;
                        case MediaPlayer.StoppedState:
                            console.log("Video playback stopped")
                            break;
                    }
                }

                Component.onCompleted:
                {
                    videoComponent.loaded = true
                    delayedStartTimer.start()
                }

                function autoStart()
                {
                    if(mediaPlayer.source !== "" && mediaPlayer.source !== undefined)
                    {
                        console.log("Starting playback of " + mediaPlayer.source)
                        mediaPlayer.play()
                    }
                    else
                    {
                        console.log("Stopping playback")
                        mediaPlayer.stop()
                    }
                }
            }

            Timer
            {
                id: delayedStartTimer
                interval: 500
                repeat: false
                onTriggered: mediaPlayer.autoStart()
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
            id: channelShaderContent
            anchors.fill: parent

            // Setup the shader effect sources for each channel
            // These are needed to provide the uniform data to the shader channel buffers
            ShaderEffectSource
            {
                id: channelSource0
                sourceItem: channel.iChannel0 ? channel.iChannel0 : null
                live: Qt.binding(() => { return isLive(); })
                smooth: true
                sourceRect: sourceItem ? Qt.rect(0,0, sourceItem.width, sourceItem.height) : Qt.rect(0,0,0,0)
                wrapMode: ShaderEffectSource.ClampToEdge
                textureSize: Qt.size(channel.iResolution.x, channel.iResolution.y)
                textureMirroring: ShaderEffectSource.NoMirroring
                recursive: false
                mipmap: true
                hideSource: true
                width: channel.iResolution.x
                height: channel.iResolution.y
                visible: false
                format: ShaderEffectSource.RGBA8

                function isLive()
                {
                    if(!channel.iChannel0 || channel.iChannel0 === undefined || channel.iChannel0.type === ShaderChannel.ImageChannel)
                        return false;
                    
                    return channel.iChannel0.type != ShaderChannel.VideoChannel && channel.active;
                }
            }

            ShaderEffectSource
            {
                id: channelSource1
                sourceItem: channel.iChannel1 ? channel.iChannel1 : null
                live: Qt.binding(() => { return isLive(); })
                smooth: false
                sourceRect: sourceItem ? Qt.rect(0,0, sourceItem.width, sourceItem.height) : Qt.rect(0,0,0,0)
                wrapMode: ShaderEffectSource.ClampToEdge
                textureSize: Qt.size(channel.iResolution.x, channel.iResolution.y)
                textureMirroring: ShaderEffectSource.NoMirroring
                recursive: true
                mipmap: true
                hideSource: true
                width: channel.iResolution.x
                height: channel.iResolution.y
                visible: false
                format: ShaderEffectSource.RGBA8

                function isLive()
                {
                    if(!channel.iChannel1 || channel.iChannel1 === undefined || channel.iChannel1.type === ShaderChannel.ImageChannel)
                        return false;
                    
                    return channel.iChannel1.type != ShaderChannel.VideoChannel && channel.active;
                }
            }

            ShaderEffectSource
            {
                id: channelSource2
                sourceItem: channel.iChannel2 ? channel.iChannel2 : null
                live: Qt.binding(() => { return isLive(); })
                smooth: false
                sourceRect: sourceItem ? Qt.rect(0,0, sourceItem.width, sourceItem.height) : Qt.rect(0,0,0,0)
                wrapMode: ShaderEffectSource.ClampToEdge
                textureSize: Qt.size(channel.iResolution.x, channel.iResolution.y)
                textureMirroring: ShaderEffectSource.NoMirroring
                recursive: true
                mipmap: true
                hideSource: true
                width: channel.iResolution.x
                height: channel.iResolution.y
                visible: false
                format: ShaderEffectSource.RGBA8

                function isLive()
                {
                    if(!channel.iChannel2 || channel.iChannel2 === undefined || channel.iChannel2.type === ShaderChannel.ImageChannel)
                        return false;
                    
                    return channel.iChannel2.type != ShaderChannel.VideoChannel && channel.active;
                }
            }

            ShaderEffectSource
            {
                id: channelSource3
                sourceItem: channel.iChannel3 ? channel.iChannel3 : null
                live: Qt.binding(() => { return isLive(); })
                smooth: false
                sourceRect: sourceItem ? Qt.rect(0,0, sourceItem.width, sourceItem.height) : Qt.rect(0,0,0,0)
                wrapMode: ShaderEffectSource.ClampToEdge
                textureSize: Qt.size(channel.iResolution.x, channel.iResolution.y)
                textureMirroring: ShaderEffectSource.NoMirroring
                recursive: true
                mipmap: true
                hideSource: true
                width: channel.iResolution.x
                height: channel.iResolution.y
                visible: false
                format: ShaderEffectSource.RGBA8

                function isLive()
                {
                    if(!channel.iChannel3 || channel.iChannel3 === undefined || channel.iChannel3.type === ShaderChannel.ImageChannel)
                        return false;
                    
                    return channel.iChannel3.type != ShaderChannel.VideoChannel && channel.active;
                }
            }

            // recursive frame buffer
            ShaderEffectSource
            {
                id: frameBufferSource
                sourceItem: channel.frameBufferChannel === -1 ? null : channelShaderContent
                sourceRect: Qt.rect(0,0, channelShaderContent.width, channelShaderContent.height)
                wrapMode: ShaderEffectSource.ClampToEdge
                live: channel.active
                mipmap: true
                recursive: true
                textureSize: Qt.size(channelShaderContent.width, channelShaderContent.height)
                visible: false
                textureMirroring: ShaderEffectSource.NoMirroring
                width: channel.iResolution.x
                height: channel.iResolution.y
                format: ShaderEffectSource.RGBA8
            }

            // The shader effect that will be used to render the shader
            ShaderEffect
            {
                property var iChannel0: channel.frameBufferChannel === 0 ? frameBufferSource : channelSource0
                property var iChannel1: channel.frameBufferChannel === 1 ? frameBufferSource : channelSource1
                property var iChannel2: channel.frameBufferChannel === 2 ? frameBufferSource : channelSource2
                property var iChannel3: channel.frameBufferChannel === 3 ? frameBufferSource : channelSource3

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
                width: channel.iResolution.x
                height: channel.iResolution.y

                id: channelShaderOutput

                blending: channel.blending
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

    // Connect the audio channel to the cpp backend
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
                anchors.top: !channel.invert ? undefined : parent.top
                anchors.bottom: !channel.invert ? parent.bottom : undefined
                id: textureImage
                source: "image://audiotexture/frame"
                fillMode: Image.Pad

                // we need to flip the texture when the channel itself is flipped
                // so the orientation of the audio data is preserved
                transform: Rotation
                {
                    origin.x: textureImage.width / 2
                    origin.y: textureImage.height / 2

                    // For vertical flipping, we need to transform the x axis
                    axis
                    {
                        x: 1
                        y: 0
                        z: 0
                    }

                    angle: data.angle + 180
                }
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

            Component.onDestruction:
            {
                Komplex.AudioModel.stopCapture()
            }
        }
    }

    // Scene is directly loaded, no comp needed

    // 3D Model
    Component
    {
        id: modelComponent

        Item
        {
            anchors.fill: parent
            id: channelModelContent

            // recursive frame buffer
            ShaderEffectSource
            {
                id: frameBufferSource
                sourceItem: channel.frameBufferChannel === -1 ? null : channelModelContent
                sourceRect: Qt.rect(0,0, channelModelContent.width, channelModelContent.height)
                wrapMode: ShaderEffectSource.ClampToEdge
                live: channel.active
                mipmap: true
                recursive: true
                textureSize: Qt.size(channelModelContent.width, channelModelContent.height)
                visible: false
                textureMirroring: ShaderEffectSource.NoMirroring
                width: channel.iResolution.x
                height: channel.iResolution.y
            }

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

                Model
                {
                    source: Qt.resolvedUrl(channel.source)
                    scale: Qt.vector3d(channel.scale)
                    geometry: Komplex.GeometryProvider
                    {
                        source: Qt.resolvedUrl(channel.source)
                    }
                    materials:
                    [
                        CustomMaterial
                        {
                            property var iChannel0: channel.frameBufferChannel === 0 ? frameBufferSource : channelSource0
                            property var iChannel1: channel.frameBufferChannel === 1 ? frameBufferSource : channelSource1
                            property var iChannel2: channel.frameBufferChannel === 2 ? frameBufferSource : channelSource2
                            property var iChannel3: channel.frameBufferChannel === 3 ? frameBufferSource : channelSource3

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

                            Texture 
                            {
                                id: baseColorMap
                                source: Qt.resolvedUrl(channel.materialTexture)
                            }

                            cullMode: PrincipledMaterial.NoCulling
                            fragmentShader: Qt.resolvedUrl(channel.materialShader)
                        }
                    ]
                }
            }
        }
    }
}
