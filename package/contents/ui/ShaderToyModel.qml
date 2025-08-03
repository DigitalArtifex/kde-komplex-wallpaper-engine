 /*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  This was originally part of the KDE Shader Wallpaper Project, which was the inspiration for this project.
 *  It has been modified to use the new channel structure and is being used to support
 *  ShaderToy imports.
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
import QtQuick.Controls
import QtQuick.Dialogs as Dialogs

import org.kde.plasma.core as PlasmaCore

Item
{
    property real pixelRatio: 1 //This will (hopefully) be set to PlasmaCore.Units.devicePixelRatio in onCompleted
    property vector3d iResolution: Qt.vector3d(wallpaper.configuration.resolution_x,wallpaper.configuration.resolution_y,1)//width, height, pixel aspect ratio
    property real iTime: 0 //used by most motion shaders 
    property real iTimeDelta: iTime 
    property var iChannelTime: [iTime, iTime, iTime, iTime] //individual channel time values
    property real iSampleRate: 44100 //used by audio shaders
    property int iFrame: 0
    property real iFrameRate: wallpaper.configuration.framerate_limit // Default frame rate for the shader
    property vector4d iMouse
    property var iDate
    property bool running: windowModel.runShader // Controls whether the wallpaper is running or paused

    // Individual channel resolutions to customize performance and quality
    property var iChannelResolution: [Qt.vector3d(wallpaper.configuration.iChannel0_resolution_x, wallpaper.configuration.iChannel0_resolution_y, pixelRatio),
                                      Qt.vector3d(wallpaper.configuration.iChannel1_resolution_x, wallpaper.configuration.iChannel1_resolution_y, pixelRatio),
                                      Qt.vector3d(wallpaper.configuration.iChannel2_resolution_x, wallpaper.configuration.iChannel2_resolution_y, pixelRatio),
                                      Qt.vector3d(wallpaper.configuration.iChannel3_resolution_x, wallpaper.configuration.iChannel3_resolution_y, pixelRatio)]

    id: mainItem

    // The WindowModel is used to manage the interaction with the desktop environment
    WindowModel
    {
        id: windowModel
        screenGeometry: mainItem.parent.screenGeometry
    }

    Rectangle
    {
        anchors.fill: parent
        color: "black"

        Text
        {
            color: "white"
            text: "<h1>" + wallpaper.configuration.selectedShaderPath + "</h1>"
        }

        // Setup the shader channels (iChannel0, iChannel1, iChannel2, iChannel3)
        // These channels are used to pass channel data to the shader sources and can
        // be configured to use different types of media (Image, Video, Shader, Audio, CubeMap)
        ShaderChannel
        {
            //Fallback to a channel if the output channel is not set or there was an error loading the shader
            visible: wallpaper.configuration.iChannel0_flag && (channelOutput.source === "" || channelOutput.source === undefined)
            iTime: mainItem.iTime
            iMouse: mainItem.iMouse
            iResolution: mainItem.iChannelResolution[0]

            id: channel0
            anchors.fill: parent
            type: wallpaper.configuration.iChannel0_flag ? wallpaper.configuration.iChannel0_type : 0

            source: wallpaper.configuration.iChannel0_flag ? Qt.resolvedUrl(wallpaper.configuration.iChannel0) : ""
        }

        ShaderChannel
        {
            //Fallback to a channel if the output channel is not set or there was an error loading the shader
            visible: wallpaper.configuration.iChannel1_flag && (channelOutput.source === "" || channelOutput.source === undefined)
            iTime: mainItem.iTime
            iResolution: mainItem.iChannelResolution[1]

            id: channel1
            anchors.fill: parent
            type: wallpaper.configuration.iChannel1_flag ? wallpaper.configuration.iChannel1_type : 0

            source: wallpaper.configuration.iChannel1_flag ? Qt.resolvedUrl(wallpaper.configuration.iChannel1) : ""
        }

        ShaderChannel
        {
            //Fallback to a channel if the output channel is not set or there was an error loading the shader
            visible: wallpaper.configuration.iChannel2_flag && (channelOutput.source === "" || channelOutput.source === undefined)
            iTime: mainItem.iTime
            iResolution: mainItem.iChannelResolution[2]

            id: channel2
            anchors.fill: parent
            type: wallpaper.configuration.iChannel2_flag ? wallpaper.configuration.iChannel2_type : 0

            source: wallpaper.configuration.iChannel2_flag ? Qt.resolvedUrl(wallpaper.configuration.iChannel2) : ""
        }

        ShaderChannel
        {
            //Fallback to a channel if the output channel is not set or there was an error loading the shader
            visible: wallpaper.configuration.iChannel3_flag && (channelOutput.source === "" || channelOutput.source === undefined)
            iTime: mainItem.iTime
            iChannelTime: [mainItem.iTime, mainItem.iTime, mainItem.iTime, mainItem.iTime]
            iResolution: mainItem.iChannelResolution[3]
            iDate: mainItem.iDate

            id: channel3
            anchors.fill: parent
            type: wallpaper.configuration.iChannel3_flag ? wallpaper.configuration.iChannel3_type : 0

            source: wallpaper.configuration.iChannel3_flag ? Qt.resolvedUrl(wallpaper.configuration.iChannel3) : ""
        }

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
            source: wallpaper.configuration.selectedShaderPath ? wallpaper.configuration.selectedShaderPath : ""

            iChannel0: channel0
            iChannel1: channel1
            iChannel2: channel2
            iChannel3: channel3

            visible: true // Set to true to display the output
        }

        // To save on performance, just use one timer for all channels
        Timer
        {
            id: channelTimer

            //Not entirely sure if this will actually limit the frame rate
            interval: (1 / mainItem.iFrameRate) * 1000 //fps to ms cycles :: fps = 60 = 1 / 60 = 0.01666 * 1000 = 16
            repeat: true

            running: mainItem.running

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
    
    Component.onCompleted:
    {
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

        // Initialize pixelRatio for shader use
        pixelRatio = 1 //PlasmaCore.Units.devicePixelRatio was removed in Plasma6
    }
}
