/*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  ShaderChannelConfiguration.qml
 *  
 *  This component is used to configure the shader channels for the output shader.
 *  It allows the user to select a file or folder for each channel type (Image,
 *  Video, Shader, Audio, CubeMap) and sets the appropriate properties on the
 *  ShaderChannel component.
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
 *  along with this program.  If not, see <https://www.gnu.org/licenses/>
 */
pragma ComponentBehavior: Bound

import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import QtCore
import Qt.labs.folderlistmodel 2.15

import QtQuick.Dialogs as Dialogs
import com.github.digitalartifex.komplex 1.0 as Komplex

Item
{
    signal accepted()
    signal rejected()

    property bool file: true
    property string selectionTitle: "Select a file"
    property var selectionFilter: ["All Files (*)"]

    // The current folder is used to set the initial folder for the file and folder dialogs
    property string currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]

    // Individual folders for each channel type
    property string shaderFolder: shaderPackModel.shadersPath
    property string imageFolder: shaderPackModel.imagesPath
    property string videoFolder: shaderPackModel.videosPath
    property string cubemapFolder: shaderPackModel.cubeMapsPath

    property alias tmp_source: sourceEdit.text
    property int tmp_type: 1
    property alias tmp_timeScale: speedSlider.value
    property alias tmp_resolution_scale: resolutionScaleSlider.value
    property alias tmp_resolution_x: resolutionXEdit.value
    property alias tmp_resolution_y: resolutionYEdit.value
    property alias tmp_invert: channelInvertedCheckBox.checked
    property bool tmp_enabled: tmp_source !== ""
    property Palette palette

    property string source
    property int type
    property real timeScale
    property real resolution_scale
    property int resolution_x
    property int resolution_y
    property bool enabled
    property bool invert
    property bool changed

    id: window

    Komplex.ShaderPackModel
    {
        id: shaderPackModel
    }

    // The selection model contains the list of available shader channel types
    // and their respective properties.
    ListModel
    {
        id: selectionModel

        ListElement
        {
            file: true
            name: "Audio"
            icon: "./icons/audio.svg"
            type: ShaderChannel.Type.AudioChannel
        }

        ListElement
        {
            file: false
            name: "Cubemap"
            icon: "./icons/cube.svg"
            title: "Select a CubeMap folder"
            filter: ""
            type: ShaderChannel.Type.CubeMapChannel
        }

        ListElement
        {
            file: true
            name: "Image"
            icon: "./icons/image.svg"
            title: "Select an Image File"
            filter: "Image Files (*.jpg *.jpeg *.png *.svg *.gif *.tiff *.webp)"
            type: ShaderChannel.Type.ImageChannel
        }

        ListElement
        {
            file: true
            name: "Scene"
            icon: "./icons/image.svg"
            title: "Select a scene file"
            filter: "Image Files (*.qml)"
            type: ShaderChannel.Type.SceneChannel
        }

        ListElement
        {
            file: true
            name: "Shader"
            icon: "./icons/3d-glasses.svg"
            title: "Select a Shader File"
            filter: "Shader Files (*frag.qsb)"
            type: ShaderChannel.Type.ShaderChannel
        }

        ListElement
        {
            file: true
            name: "Video"
            icon: "./icons/video.svg"
            title: "Select a Video File"
            filter: "Video Files (*.mov *.avi *.mkv *.mp4)"
            type: ShaderChannel.Type.VideoChannel
        }

        function indexOf(type) 
        {
            for(var i = 0; i < count; ++i) if (get(i).type == type) 
                return i

            return -1
        }
    }

    Component
    {
        id: selectionDelegate

        Item
        {
            required property int index
            required property int type
            required property string name
            required property string icon
            required property string title
            required property var filter
            required property bool file
                
            width: 100
            height: 75

            ColumnLayout
            {
                anchors.fill: parent
                Image
                {
                    source: icon

                    Layout.preferredHeight: 50
                    Layout.preferredWidth: 50
                    Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                }

                Text
                {
                    id: label
                    text: name
                    color: "white"

                    horizontalAlignment: Text.AlignHCenter

                    Layout.fillHeight: false
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignBottom
                }
            }

            MouseArea
            {
                hoverEnabled: true
                anchors.fill: parent
                z: 9000 // this is dumb but I can't get the mouse area to propogate without it

                onClicked: 
                {
                    list.currentIndex = parent.index
                    window.tmp_type = parent.type
                    window.selectionFilter = parent.filter.split(':')
                    window.selectionTitle = parent.title
                    window.file = parent.file

                    switch(parent.type) 
                    {
                        // case ShaderChannel.Type.AudioChannel:
                        //     break;
                        case ShaderChannel.Type.CubeMapChannel:
                            window.currentFolder = window.cubemapFolder
                            window.tmp_source = ""
                            break;
                        case ShaderChannel.Type.ImageChannel:
                            window.currentFolder = window.imageFolder
                            window.tmp_source = ""
                            break;
                        case ShaderChannel.Type.ShaderChannel:
                            window.currentFolder = window.shaderFolder
                            window.tmp_source = ""
                            break;
                        case ShaderChannel.Type.VideoChannel:
                            window.currentFolder = window.videoFolder
                            window.tmp_source = ""
                            break;
                        case ShaderChannel.Type.AudioChannel:
                            window.currentFolder = window.videoFolder
                            window.tmp_source = "Audio Channel"
                            break;
                    }
                }
            }
        }
    }

    Component 
    {
        id: highlight
        Rectangle 
        {
            width: list.currentItem.width; height: list.currentItem.height
            color: "lightsteelblue"; radius: 5
            y: list.currentItem.y
            Behavior on y 
            {
                SpringAnimation 
                {
                    spring: 2
                    damping: 0.1
                }
            }
        }
    }

    ColumnLayout
    {
        anchors.fill: parent
        spacing: 10

        ListView
        {
            id: list
            model: selectionModel

            Layout.fillWidth: true
            Layout.preferredHeight: 100
            Layout.alignment: Qt.AlignTop

            delegate: selectionDelegate
            orientation: Qt.Horizontal
            clip: true

            highlight: highlight
            highlightFollowsCurrentItem: true
            focus: true
        }

        RowLayout
        {
            visible: window.tmp_type != ShaderChannel.Type.AudioChannel
            Layout.alignment: Qt.AlignTop

            Label
            {
                color: palette.text
                verticalAlignment: Text.AlignVCenter
                text: i18nd("@option:shader_source_label", "Source")

                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            }

            TextField
            {
                id: sourceEdit
                Layout.fillWidth: true
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            }

            Button
            {
                icon.name: "folder-symbolic"
                Layout.preferredWidth: Kirigami.Units.gridUnit * 2
                Layout.preferredHeight: Kirigami.Units.gridUnit * 2

                onClicked: 
                {
                    if(window.file === true)
                        fileDialog.open()
                    else
                        folderDialog.open()
                }
            }
        }

        CheckBox 
        {
            id: channelInvertedCheckBox
            text: i18n("Invert Channel Data")
        }

        RowLayout 
        {
            Layout.alignment: Qt.AlignTop
            id: speedLayout

            Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Shader speed:")

            Label
            {
                color: palette.text
                verticalAlignment: Qt.AlignVCenter
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6

                text: i18nd("@option:time_scale_label", "Shader Speed")
            }

            Slider 
            {
                id: speedSlider
                Layout.fillWidth: true
                from: 0
                to: 4
                stepSize: 0.1
                onValueChanged: shaderSpeedField.text = String(value.toFixed(2));
            }

            TextField 
            {
                id: shaderSpeedField
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                horizontalAlignment: Text.AlignRight
                Layout.preferredWidth: Kirigami.Units.gridUnit * 4
                onEditingFinished: () =>
                {
                    let inputValue = parseFloat(text);

                    if (isNaN(inputValue) || inputValue < speedSlider.from)
                        inputValue = speedSlider.from;
                    else if (inputValue > speedSlider.to)
                        inputValue = speedSlider.to;

                    text = inputValue.toFixed(2);
                    speedSlider.value = inputValue;
                }

                Keys.onPressed: (event) => 
                {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) 
                    {
                        shaderSpeedField.focus = false; // Unfocus the TextField
                        event.accepted = true; // Prevent further propagation of the key event
                    }
                }

                background: Rectangle 
                {
                    color: shaderSpeedField.activeFocus ? palette.base : "transparent"
                    border.color: shaderSpeedField.activeFocus ? palette.highlight : "transparent"
                    border.width: 1
                    radius: 4
                    anchors.fill: shaderSpeedField
                    anchors.margins: -2
                }
            }
        }

        RowLayout 
        {
            Layout.alignment: Qt.AlignTop
            id: resolutionScaleLayout

            Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Shader speed:")

            Label
            {
                color: palette.text
                verticalAlignment: Qt.AlignVCenter
                text: i18nd("@option:time_scale_label", "Resolution Scale")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
            }

            Slider 
            {
                id: resolutionScaleSlider
                Layout.fillWidth: true
                from: 0.125
                to: 1
                stepSize: 0.01
                onValueChanged: resolutionScaleField.text = String(value.toFixed(3));
            }

            TextField 
            {
                id: resolutionScaleField
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                horizontalAlignment: Text.AlignRight

                Layout.preferredWidth: Kirigami.Units.gridUnit * 4

                onEditingFinished: () =>
                {
                    let inputValue = parseFloat(text);

                    if (isNaN(inputValue) || inputValue < resolutionScaleSlider.from)
                        inputValue = resolutionScaleSlider.from;
                    else if (inputValue > resolutionScaleSlider.to)
                        inputValue = resolutionScaleSlider.to;

                    text = inputValue.toFixed(3);
                    resolutionScaleSlider.value = inputValue;
                }
                Keys.onPressed: (event) => 
                {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) 
                    {
                        resolutionScaleField.focus = false; // Unfocus the TextField
                        event.accepted = true; // Prevent further propagation of the key event
                    }
                }
                background: Rectangle 
                {
                    color: resolutionScaleField.activeFocus ? palette.base : "transparent"
                    border.color: resolutionScaleField.activeFocus ? palette.highlight : "transparent"
                    border.width: 1
                    radius: 4
                    anchors.fill: resolutionScaleField
                    anchors.margins: -2
                }
            }
        }

        RowLayout
        {
            Layout.alignment: Qt.AlignTop
            Layout.fillWidth: true

            Label
            {
                color: palette.text
                text: i18nd("@option:resolution_label_x", "Resolution X")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
            }

            TextField
            {
                property int value
                
                Layout.preferredHeight: 35
                Layout.fillWidth: true

                id: resolutionXEdit
                text: value
                onEditingFinished: () =>
                {
                    var inputValue = parseInt(text);

                    if (isNaN(inputValue) || inputValue < 0)
                        inputValue = 0

                    value = inputValue;
                }
                Keys.onPressed: (event) => 
                {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) 
                    {
                        resolutionScaleField.focus = false; // Unfocus the TextField
                        event.accepted = true; // Prevent further propagation of the key event
                    }
                }
            }
            Label
            {
                color: palette.text
                text: i18nd("@option:resolution_label_y", "Resolution Y")
                Layout.preferredWidth: Kirigami.Units.gridUnit * 6
            }

            TextField
            {
                property int value
                
                Layout.preferredHeight: 35
                Layout.fillWidth: true

                id: resolutionYEdit
                text: value
                onEditingFinished: () =>
                {
                    var inputValue = parseInt(text);

                    if (isNaN(inputValue) || inputValue < 0)
                        inputValue = 0

                    value = inputValue;
                }
                Keys.onPressed: (event) => 
                {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) 
                    {
                        resolutionScaleField.focus = false; // Unfocus the TextField
                        event.accepted = true; // Prevent further propagation of the key event
                    }
                }
            }
        }
        RowLayout
        {
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignBottom | Qt.AlignRight
            Layout.bottomMargin: 5


            Button
            {
                id: okayButton
                text: "Okay"
                onClicked: window.accept()

                Layout.alignment: Qt.AlignRight
            }

            Button
            {
                id: cancelButton
                text: "Cancel"
                onClicked: window.reject()

                Layout.alignment: Qt.AlignRight
            }
        }
    }

    // FileDialog is used to select a file for the Image, Shader, and Video channels
    Dialogs.FileDialog
    {
        id: fileDialog
        currentFolder: "file://" + window.currentFolder
        nameFilters: window.selectionFilter
        title: window.selectionTitle

        onAccepted: window.tmp_source = selectedFile
    }

    // FolderDialog is used to select a folder for the CubeMap channel
    Dialogs.FolderDialog
    {
        id: folderDialog
        currentFolder: window.cubemapFolder
        title: window.selectionTitle

        onAccepted: window.tmp_source = selectedFolder
    }

    function accept()
    {
        // copy over temp values
        type = tmp_type
        source = tmp_source
        timeScale = tmp_timeScale
        resolution_scale = tmp_resolution_scale
        resolution_x = tmp_resolution_x
        resolution_y = tmp_resolution_y
        enabled = tmp_enabled
        invert = tmp_invert

        // Emit the accepted signal and reset the selection
        window.accepted()
    }

    function reject()
    {
        // Emit the rejected signal and reset the selection
        resetSelection()
        window.rejected()
    }

    function configureChannel()
    {
        resetSelection()
    }

    // Function to update the current selection based on the channel type
    function updateCurrentSelection()
    {
        // Set the dialog properties based on the channel properties
        switch(type) 
        {
            case ShaderChannel.Type.CubeMapChannel:
                window.currentFolder = window.cubemapFolder
                break;
            case ShaderChannel.Type.ImageChannel:
                window.currentFolder = window.imageFolder
                break;
            case ShaderChannel.Type.ShaderChannel:
                window.currentFolder = window.shaderFolder
                break;
            case ShaderChannel.Type.VideoChannel:
                window.currentFolder = window.videoFolder
                break;
            case ShaderChannel.Type.AudioChannel:
                window.tmp_source = "Audio Channel"
                break;
        }

        // Set the current selection index
        list.currentIndex = selectionModel.indexOf(type)
    }

    // Function to reset the selection to default values
    function resetSelection()
    {
        if((tmp_source !== source) || (tmp_enabled !== enabled) ||
        (tmp_invert !== invert) || (tmp_resolution_scale !== resolution_scale) ||
        (tmp_resolution_x !== resolution_x) || (tmp_resolution_y !== resolution_y) ||
        (tmp_timeScale !== timeScale) || (tmp_type !== type))
            changed = true;
        
        tmp_source = source
        tmp_timeScale = timeScale
        tmp_resolution_scale = resolution_scale
        tmp_resolution_x = resolution_x
        tmp_resolution_y = resolution_y
        tmp_invert = invert

        tmp_type = type
        updateCurrentSelection()
    }
}