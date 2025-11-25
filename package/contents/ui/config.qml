/*
 *  Komplex Wallpaper Engine
 *  Copyright (C) 2025 @DigitalArtifex | github.com/DigitalArtifex
 *
 *  config.qml
 *  
 *  This component provides a configuration interface for the Komplex Wallpaper Engine,
 *  allowing users to customize shader settings, channel configurations, and other
 *  parameters related to the wallpaper engine.
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
// pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import org.kde.kirigami as Kirigami
import org.kde.plasma.core as PlasmaCore
import QtCore
import Qt.labs.folderlistmodel 2.15

import com.github.digitalartifex.komplex 1.0 as Komplex

Kirigami.FormLayout 
{
    wideMode: true
    id: root
    twinFormLayouts: parentLayout // required by parent
    property alias formLayout: root // required by parent
    property alias cfg_pauseMode: pauseModeCombo.currentIndex
    property alias cfg_isPaused: runningCombo.checked
    property alias cfg_selectedShaderIndex: selectedShader.currentIndex
    property alias cfg_selectedShaderPath: selectedShader.shader
    property alias cfg_iChannel0: shaderChannelConfig0.source
    property alias cfg_iChannel1: shaderChannelConfig1.source
    property alias cfg_iChannel2: shaderChannelConfig2.source
    property alias cfg_iChannel3: shaderChannelConfig3.source
    property alias cfg_iChannel0_flag: shaderChannelConfig0.enabled
    property alias cfg_iChannel1_flag: shaderChannelConfig1.enabled
    property alias cfg_iChannel2_flag: shaderChannelConfig2.enabled
    property alias cfg_iChannel3_flag: shaderChannelConfig3.enabled
    property alias cfg_iChannel0_type: shaderChannelConfig0.type
    property alias cfg_iChannel1_type: shaderChannelConfig1.type
    property alias cfg_iChannel2_type: shaderChannelConfig2.type
    property alias cfg_iChannel3_type: shaderChannelConfig3.type
    property alias cfg_iChannel0_timeScale: shaderChannelConfig0.timeScale
    property alias cfg_iChannel1_timeScale: shaderChannelConfig1.timeScale
    property alias cfg_iChannel2_timeScale: shaderChannelConfig2.timeScale
    property alias cfg_iChannel3_timeScale: shaderChannelConfig3.timeScale
    property alias cfg_iChannel0_resolution_scale: shaderChannelConfig0.resolution_scale
    property alias cfg_iChannel1_resolution_scale: shaderChannelConfig1.resolution_scale
    property alias cfg_iChannel2_resolution_scale: shaderChannelConfig2.resolution_scale
    property alias cfg_iChannel3_resolution_scale: shaderChannelConfig3.resolution_scale
    property alias cfg_iChannel0_resolution_x: shaderChannelConfig0.resolution_x
    property alias cfg_iChannel0_resolution_y: shaderChannelConfig0.resolution_y
    property alias cfg_iChannel1_resolution_x: shaderChannelConfig1.resolution_x
    property alias cfg_iChannel1_resolution_y: shaderChannelConfig1.resolution_y
    property alias cfg_iChannel2_resolution_x: shaderChannelConfig2.resolution_x
    property alias cfg_iChannel2_resolution_y: shaderChannelConfig2.resolution_y
    property alias cfg_iChannel3_resolution_x: shaderChannelConfig3.resolution_x
    property alias cfg_iChannel3_resolution_y: shaderChannelConfig3.resolution_y
    property alias cfg_iChannel0_wrap_mode: shaderChannelConfig0.textureWrapping
    property alias cfg_iChannel1_wrap_mode: shaderChannelConfig1.textureWrapping
    property alias cfg_iChannel2_wrap_mode: shaderChannelConfig2.textureWrapping
    property alias cfg_iChannel3_wrap_mode: shaderChannelConfig3.textureWrapping
    property alias cfg_iChannel0_mirroring_mode: shaderChannelConfig0.textureMirroring
    property alias cfg_iChannel1_mirroring_mode: shaderChannelConfig1.textureMirroring
    property alias cfg_iChannel2_mirroring_mode: shaderChannelConfig2.textureMirroring
    property alias cfg_iChannel3_mirroring_mode: shaderChannelConfig3.textureMirroring
    property alias cfg_shaderSpeed: speedSlider.value
    property alias cfg_mouseSpeedBias: mouseBiasSlider.value
    property alias cfg_mouseAllowed: mouseEnableButton.checked
    property bool cfg_infoPlasma6Preview_dismissed
    property bool cfg_warningResources_dismissed
    property bool cfg_emergencyHelp_dismissed
    property bool cfg_infoiChannelSettings_dismissed
    property alias cfg_checkActiveScreen: activeScreenOnlyCheckbox.checked
    property alias cfg_excludeWindows: excludeWindows.windows
    property alias cfg_running: runningCombo.checked

    property alias cfg_shader_package: selectedShaderPack.shader
    property alias cfg_shader_package_index: selectedShaderPack.currentIndex
    property alias cfg_komplex_mode: engineModeSelect.currentIndex

    property alias cfg_resolution_x: resolutionXField.value
    property alias cfg_resolution_y: resolutionYField.value

    property alias cfg_framerate_limit: frameRateField.value
    property bool cfg_shader_updated

    Palette 
    {
        id: palette
    }

    Komplex.ShaderPackModel
    {
        id: shaderPackModel
        onJsonChanged: 
        {
            // Handle the JSON change if needed
            console.log("Shader pack JSON changed:", shaderPackModel.json);
            root.cfg_shader_package = shaderPackModel.shaderPackPath + "/" + shaderPackModel.shaderPackName + "/pack.json"
        }
    }

    // Engine Mode Selection

    RowLayout
    {
        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Engine Mode:")
        ComboBox
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11.5
            id: engineModeSelect
            currentIndex: root.cfg_komplex_mode
            onCurrentIndexChanged: root.cfg_komplex_mode = currentIndex
            textRole: "label"
            model: [
                { "label": i18nd("@option:komplex_mode", "Simple") },
                { "label": i18nd("@option:komplex_mode", "Komplex") }
            ] 
        }
    }

    RowLayout 
    {
        visible: root.cfg_komplex_mode === 0
        
        id: shaderOutputLayout
        spacing: Kirigami.Units.smallSpacing
        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Output Shader:")

        ComboBox 
        {
            property string shader

            id: selectedShader
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11.5
            model: FolderListModel 
            {
                id: folderListModel
                showDirs: false
                showFiles: true
                showHidden: true
                nameFilters: ["*.frag.qsb"]
                folder: "file://" + shaderPackModel.shadersPath + "/manipulative"
            }
            delegate: Component 
            {
                id: folderListDelegate
                ItemDelegate 
                {
                    width: parent ? parent.width : 0
                    text: fileBaseName.replace("_", " ").charAt(0).toUpperCase() + fileBaseName.replace("_", " ").slice(1)
                }
            }

            textRole: "fileBaseName"
            currentIndex: root.cfg_selectedShaderIndex
            displayText: currentIndex === -1 ? "Custom File" : currentText.replace("_", " ").charAt(0).toUpperCase() + currentText.replace("_", " ").slice(1)

            onCurrentTextChanged: 
            {
                root.cfg_selectedShaderIndex = currentIndex;

                if (root.cfg_selectedShaderIndex === -1)
                    return;

                var source = model.get(currentIndex, "fileUrl");
                shader = source;
            }
        }

        Button 
        {
            id: shaderFileButton
            icon.name: "folder-symbolic"
            text: i18nd("@button:toggle_select_shader", "Select File")
            Layout.preferredWidth: Kirigami.Units.gridUnit * 8.5
            Layout.preferredHeight: selectedShader.height
            onClicked: 
            {
                fileDialog.currentFolder = "file://" + shaderPackModel.shadersPath;
                fileDialog.open();
            }
        }

        FileDialog 
        {
            id: fileDialog
            fileMode: FileDialog.OpenFile
            title: i18nd("@dialog_title:choose_shader", "Choose a shader")
            // will accept and auto convert .frag in the near future
            nameFilters: ["Shader files (*.frag.qsb)", "All files (*)"]
            visible: false
            currentFolder: `${StandardPaths.writableLocation(StandardPaths.HomeLocation)}/.local/share/komplex/shaders/`
            onAccepted: 
            {
                root.cfg_selectedShaderIndex = -1;
                root.cfg_selectedShaderPath = selectedFile;
            }
        }
    }

    RowLayout 
    {
        visible: root.cfg_komplex_mode === 1
        
        spacing: Kirigami.Units.smallSpacing
        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Shader Pack:")

        ComboBox 
        {
            property string shader

            id: selectedShaderPack
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11.5
            model: shaderPackModel.availableShaderPacks
            delegate: Component 
            {
                id: packListDelegate
                ItemDelegate 
                {
                    width: parent ? parent.width : 0
                    text: modelData
                }
            }

            textRole: "modelData"
            currentIndex: root.cfg_shader_package_index
            displayText: currentIndex === -1 ? "Custom File" : currentText.replace("_", " ").charAt(0).toUpperCase() + currentText.replace("_", " ").slice(1)

            onCurrentTextChanged: 
            {
                root.cfg_shader_package_index = currentIndex;

                if (root.cfg_shader_package_index === -1)
                    return;

                var source = currentText
                shaderPackModel.loadMetadata(source)
                root.cfg_shader_package = "file://" + shaderPackModel.path(source)
            }
        }

        Button 
        {
            id: packFileButton
            icon.name: "folder-symbolic"
            hoverEnabled: true

            ToolTip.visible: hovered
            ToolTip.text: i18nd("@button:toggle_select_shader", "Select File")
            Layout.preferredWidth: selectedShaderPack.height
            Layout.preferredHeight: selectedShaderPack.height
            onClicked: 
            {
                packDialog.currentFolder = "file://" + shaderPackModel.shaderPackInstallPath;
                packDialog.open();
            }
        }

        Button 
        {
            id: shaderToyHubButton
            icon.name: "network-symbolic"
            hoverEnabled: true

            ToolTip.visible: hovered
            ToolTip.text: i18nd("@button:toggle_select_shader", "ShaderToy Import")
            Layout.preferredWidth: selectedShaderPack.height
            Layout.preferredHeight: selectedShaderPack.height
            onClicked: 
            {
                // packDialog.currentFolder = "file://" + shaderPackModel.shaderPackInstallPath;
                // packDialog.open();
                komplexHubDialog.open()
            }
        }

        FileDialog 
        {
            id: packDialog
            fileMode: FileDialog.OpenFile
            title: i18nd("@dialog_title:choose_shader", "Choose a shader")
            // will accept and auto convert .frag in the near future
            nameFilters: ["Shader Package files (*.json)", "All files (*)"]
            visible: false
            currentFolder: "file://" + shaderPackModel.shaderPackInstallPath
            onAccepted: 
            {
                root.cfg_shader_package_index = -1;
                root.cfg_shader_package = selectedFile;
                shaderPackModel.loadMetadataFromFile(selectedFile)
            }
        }

        Kirigami.OverlaySheet 
        {
            title: "ShaderToy Import"
            parent: applicationWindow().overlay
            implicitHeight: 420
            implicitWidth: 960
            id: komplexHubDialog

            ShaderToyHub
            {
                width: komplexHubDialog.width - 10
                height: komplexHubDialog.height - 40

                onAccepted:
                {
                    komplexHubDialog.close()
                    shaderPackModel.refreshShaderPacks()
                }
            }
        }
    }

    Kirigami.Separator 
    {
        Kirigami.FormData.isSection: false
    }
    TabBar 
    {
        Layout.topMargin: 6
        Layout.fillWidth: true
        id: navBar
        width: parent.width
        TabButton {
        height: 36
            text: root.cfg_komplex_mode === 0 ? qsTr("Channels") : qsTr("Information")
        }
        TabButton {
        height: 36
            text: qsTr("Settings")
        }
        TabButton {
        height: 36
            text: qsTr("Extra Settings")
        }
    }
    RowLayout
    {
        Layout.fillWidth: true
        Kirigami.InlineMessage 
        {
            id: warningResources
            Layout.fillWidth: true
            type: Kirigami.MessageType.Warning
            text: qsTr("Some shaders might consume more power and resources than others, beware!")
            showCloseButton: true
            visible: !root.cfg_warningResources_dismissed
            onVisibleChanged: () =>
            {
                root.cfg_warningResources_dismissed = true;
            }
        }
    }

    // iChannel0 Configuration
    RowLayout
    {
        visible: root.cfg_komplex_mode === 0 && navBar.currentIndex === 0
        id: channel0ConfigLayout
        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Channel 1:")

        spacing: Kirigami.Units.smallSpacing

        Text
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11

            color: palette.text
            text: i18nd("@iChannel0_source", root.cfg_iChannel0 ? root.cfg_iChannel0 : "No source selected")
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideLeft
        }

        Button
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            icon.name: "configure-symbolic"
            onClicked: () =>
            {
                shaderChannelConfig0.configureChannel();
                shaderChannelOverlay0.open();
            }
        }
    }

    Kirigami.OverlaySheet 
    {
        title: "Channel Configuration"
        id: shaderChannelOverlay0
        parent: applicationWindow().overlay
        implicitHeight: 420
        implicitWidth: 960

        ShaderChannelConfiguration
        {
            id: shaderChannelConfig0
            palette: palette
            height: 350
            onAccepted: () =>
            {
                if(shaderChannelConfig0.changed)
                    root.cfg_shader_updated = true

                shaderChannelOverlay0.close(); // Close the overlay after configuration
            }
            onRejected: shaderChannelOverlay0.close();
        }
    }

    // iChannel1 Configuration
    RowLayout
    {
        visible: root.cfg_komplex_mode === 0 && navBar.currentIndex === 0
        id: channel1ConfigLayout

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Channel 2:")

        Text
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11
            color: palette.text
            text: i18nd("@iChannel1_source", root.cfg_iChannel1 ? root.cfg_iChannel1 : "No source selected")
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Button
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            icon.name: "configure-symbolic"
            onClicked: () =>
            {
                shaderChannelConfig1.configureChannel();
                shaderChannelOverlay1.open();
            }
        }
    }

    Kirigami.OverlaySheet 
    {
        title: "Channel Configuration"
        id: shaderChannelOverlay1
        parent: applicationWindow().overlay
        implicitHeight: 420
        implicitWidth: 960

        ShaderChannelConfiguration
        {
            id: shaderChannelConfig1
            height: 350
            onAccepted: () =>
            {
                if(shaderChannelConfig1.changed)
                    root.cfg_shader_updated = true

                shaderChannelOverlay1.close(); // Close the overlay after configuration
            }
            onRejected: shaderChannelOverlay1.close();
        }
    }

    // iChannel2 Configuration
    RowLayout
    {
        visible: root.cfg_komplex_mode === 0 && navBar.currentIndex === 0
        id: channel2ConfigLayout

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Channel 3:")

        Text
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11
            color: palette.text
            text: i18nd("@iChannel2_source", root.cfg_iChannel2 ? root.cfg_iChannel2 : "No source selected")
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }

        Button
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            icon.name: "configure-symbolic"
            onClicked: () =>
            {
                shaderChannelConfig2.configureChannel();
                shaderChannelOverlay2.open();
            }
        }
    }

    Kirigami.OverlaySheet 
    {
        title: "Channel Configuration"
        id: shaderChannelOverlay2
        parent: applicationWindow().overlay
        implicitHeight: 420
        implicitWidth: 960

        ShaderChannelConfiguration
        {
            id: shaderChannelConfig2
            height: 350
            onAccepted: () =>
            {
                if(shaderChannelConfig2.changed)
                    root.cfg_shader_updated = true

                shaderChannelOverlay2.close(); // Close the overlay after configuration
            }
            onRejected: shaderChannelOverlay2.close();
        }
    }

    // iChannel3 Configuration
    RowLayout
    {
        visible: root.cfg_komplex_mode === 0 && navBar.currentIndex === 0
        Layout.fillWidth: true
        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Channel 4:")

        Text
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11
            color: palette.text
            text: i18nd("@iChannel0_source", root.cfg_iChannel3 ? root.cfg_iChannel3 : "No source selected")
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideLeft
        }

        Button
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 2
            Layout.preferredHeight: Kirigami.Units.gridUnit * 2
            icon.name: "configure-symbolic"
            onClicked: () =>
            {
                shaderChannelConfig3.configureChannel();
                shaderChannelOverlay3.open();
            }
        }
    }

    Kirigami.OverlaySheet 
    {
        title: "Channel Configuration"
        id: shaderChannelOverlay3
        parent: applicationWindow().overlay
        implicitHeight: 420
        implicitWidth: 960

        ShaderChannelConfiguration
        {
            id: shaderChannelConfig3
            height: 350
            onAccepted: () =>
            {
                if(shaderChannelConfig3.changed)
                    root.cfg_shader_updated = true

                shaderChannelOverlay3.close(); // Close the overlay after configuration
            }
            onRejected: shaderChannelOverlay3.close();
        }
    }

    RowLayout
    {
        visible: navBar.currentIndex === 1

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Resolution:")
        Text
        {
            color: palette.text
            text: "X"
            verticalAlignment: Text.AlignVCenter
        }
        TextField 
        {
            property int value
            id: resolutionXField
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
            text: value
            onEditingFinished: () =>
            {
                value = parseInt(text)
            }
            Keys.onPressed: (event) => 
            {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) 
                {
                    resolutionXField.focus = false; // Unfocus the TextField
                    event.accepted = true; // Prevent further propagation of the key event
                }
            }
            background: Rectangle 
            {
                color: resolutionXField.activeFocus ? palette.base : "transparent"
                border.color: resolutionXField.activeFocus ? palette.highlight : "transparent"
                border.width: 1
                radius: 4
                anchors.fill: resolutionXField
                anchors.margins: -2
            }
        }
        Text
        {
            color: palette.text
            text: "Y"
            verticalAlignment: Text.AlignVCenter
        }
        TextField 
        {
            property int value
            id: resolutionYField
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            horizontalAlignment: Text.AlignRight
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4
            text: value
            onEditingFinished: () =>
            {
                value = parseInt(text)
            }
            Keys.onPressed: (event) => 
            {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) 
                {
                    resolutionYField.focus = false; // Unfocus the TextField
                    event.accepted = true; // Prevent further propagation of the key event
                }
            }
            background: Rectangle 
            {
                color: resolutionYField.activeFocus ? palette.base : "transparent"
                border.color: resolutionYField.activeFocus ? palette.highlight : "transparent"
                border.width: 1
                radius: 4
                anchors.fill: resolutionYField
                anchors.margins: -2
            }
        }
    }

    RowLayout
    {
        visible: navBar.currentIndex === 1

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Frame Rate:")

        TextField
        {
            property int value

            id: frameRateField
            inputMethodHints: Qt.ImhFormattedNumbersOnly
            Layout.preferredWidth: Kirigami.Units.gridUnit * 4

            onEditingFinished: () =>
            {
                value = parseInt(text)
            }
            Keys.onPressed: (event) => 
            {
                if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) 
                {
                    frameRateField.focus = false; // Unfocus the TextField
                    event.accepted = true; // Prevent further propagation of the key event
                }
            }
            background: Rectangle 
            {
                color: frameRateField.activeFocus ? palette.base : "transparent"
                border.color: frameRateField.activeFocus ? palette.highlight : "transparent"
                border.width: 1
                radius: 4
                anchors.fill: frameRateField
                anchors.margins: -2
            }

            Component.onCompleted: () =>
            {
                text = value
            }
        }
    }

    RowLayout 
    {
        visible: navBar.currentIndex === 1
        id: speedLayout
        Layout.fillWidth: true

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Shader speed:")

        Slider 
        {
            id: speedSlider
            Layout.fillWidth: true
            from: -4.0
            to: 4.0
            stepSize: 0.01
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
    ComboBox 
    {
        visible: navBar.currentIndex === 1
        id: pauseModeCombo

        Kirigami.FormData.label: i18nd("@buttonGroup:pause_mode", "Pause:")
        model: [
            {
                'label': i18nd("@option:pause_mode", "Maximized or full-screen windows")
            },
            {
                'label': i18nd("@option:pause_mode", "Active window is present")
            },
            {
                'label': i18nd("@option:pause_mode", "At least one window is shown")
            },
            {
                'label': i18nd("@option:pause_mode", "Never")
            }
        ]
        textRole: "label"
        onCurrentIndexChanged: root.cfg_pauseMode = currentIndex
        currentIndex: root.cfg_pauseMode
    }

    CheckBox 
    {
        visible: navBar.currentIndex === 1
        id: activeScreenOnlyCheckbox

        Kirigami.FormData.label: i18nd("@checkbox:screen_filter", "Filter:")
        text: i18n("Only check for windows in active screen")
    }

    TextField 
    {
        visible: navBar.currentIndex === 1
        id: excludeWindows
        property var windows: []
        width: Kirigami.Units.gridUnit * 11
        
        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Exclude windows:")
        text: windows.join(",")
        onEditingFinished: () =>
        {
            windows = excludeWindows.text.trim().replace(/\s+/g, "").split(",");
        }
        ToolTip.visible: hovered
        ToolTip.text: qsTr("A comma-separated list of fully-qualified App-IDs to exclude their windows from triggering pause mode.")
    }

    CheckBox 
    {
        visible: navBar.currentIndex === 1
        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", cfg_isPaused ? "Playing" : "Paused")

        id: runningCombo
        checked: root.cfg_running
        text: i18n("Play/Pause the shader")
        onCheckedChanged: () =>
        {
            // wallpaper.configuration.running = checked;
            root.cfg_running = checked;
        }
    }
    
    RowLayout
    {
        visible: navBar.currentIndex === 2
        id: mouseLayout

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Mouse allowed:")
        Button 
        {
            id: mouseEnableButton
            icon.name: checked ? "followmouse-symbolic" : "hidemouse-symbolic"
            text: i18nd("@button:toggle_use_mouse", checked ? "Enabled" : "Disabled")
            checkable: true
            ToolTip.visible: hovered
            ToolTip.text: qsTr("Enabling this will allow the shader to interact with the cursor but will prevent interaction with desktop elements")
        }
    }

    RowLayout
    {
        id: mouseBiasLayout
        visible: root.cfg_mouseAllowed && navBar.currentIndex === 2

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Mouse bias:")
        ColumnLayout
        {
            Slider
            {
                id: mouseBiasSlider
                Layout.preferredWidth: Kirigami.Units.gridUnit * 16
                from: 0.0
                to: 4.0
                stepSize: 0.01
                value: root.cfg_mouseSpeedBias ? root.cfg_mouseSpeedBias : 1.0
                onValueChanged: () =>
                {
                    mouseBiasField.text = String(value.toFixed(2));
                    // wallpaper.configuration.mouseBias = mouseBiasField.text;
                    root.cfg_mouseSpeedBias = mouseBiasField.text;
                }
            }
        }
        ColumnLayout
        {
            TextField 
            {
                id: mouseBiasField
                text: root.cfg_mouseSpeedBias ? String(root.cfg_mouseSpeedBias.toFixed(2)) : "1.00"
                inputMethodHints: Qt.ImhFormattedNumbersOnly
                Layout.preferredWidth: Kirigami.Units.gridUnit * 3
                onEditingFinished: () =>
                {
                    let inputValue = parseFloat(text);

                    if (isNaN(inputValue) || inputValue < mouseBiasSlider.from)
                        inputValue = mouseBiasSlider.from;
                    else if (inputValue > mouseBiasSlider.to)
                        inputValue = mouseBiasSlider.to;
                    
                    text = inputValue.toFixed(2);
                    mouseBiasSlider.value = inputValue;
                    // wallpaper.configuration.mouseBias = inputValue;
                    root.cfg_mouseSpeedBias = inputValue;
                }
                Keys.onPressed: (event) =>
                {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) 
                    {
                        mouseBiasField.focus = false; // Unfocus the TextField
                        event.accepted = true; // Prevent further propagation of the key event
                    }
                }
                background: Rectangle 
                {
                    color: mouseBiasField.activeFocus ? palette.base : "transparent"
                    border.color: mouseBiasField.activeFocus ? palette.highlight : "transparent"
                    border.width: 1
                    radius: 4
                    anchors.fill: mouseBiasField
                    anchors.margins: -2
                }
            }
        }
    }

    Button 
    {
        visible: navBar.currentIndex === 2
        id: kofiButton
        Layout.preferredWidth: Kirigami.Units.gridUnit * 5
        Layout.preferredHeight: Kirigami.Units.gridUnit * 3

        contentItem: RowLayout 
        {
            AnimatedImage 
            {
                source: "icons/kofi.gif"
                sourceSize.width: 36
                sourceSize.height: 36
                fillMode: Image.Pad
                horizontalAlignment: Image.AlignLeft
                transform: Translate 
                {
                    x: 8
                }
            }
            Text 
            {
                text: i18nd("@button:kofi", "Kofi")
                horizontalAlignment: Text.AlignHCenter
                color: palette.text
                transform: Translate 
                {
                    x: -8
                }
            }
        }
        onClicked: () =>
        { 
            Qt.openUrlExternally("https://ko-fi.com/digitalartifex");
        }
    }
    
    RowLayout 
    {
        visible: root.cfg_komplex_mode === 1 && navBar.currentIndex === 0

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Author:")
        Text
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11
            text: shaderPackModel.metadata.author
            horizontalAlignment: Text.AlignLeft
            color: palette.text
        }
    }
    
    RowLayout 
    {
        visible: root.cfg_komplex_mode === 1 && navBar.currentIndex === 0

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Description:")
        Text
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 16
            text: shaderPackModel.metadata.description
            horizontalAlignment: Text.AlignLeft
            color: palette.text
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            elide: Text.ElideRight
        }
    }
    
    RowLayout 
    {
        visible: root.cfg_komplex_mode === 1 && navBar.currentIndex === 0

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "License:")
        Text
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11
            text: shaderPackModel.metadata.license
            horizontalAlignment: Text.AlignLeft
            color: palette.text
        }
    }
    
    RowLayout 
    {
        visible: root.cfg_komplex_mode === 1 && navBar.currentIndex === 0

        Kirigami.FormData.label: i18nd("com.github.digitalartifex.komplex", "Version:")
        Text
        {
            Layout.preferredWidth: Kirigami.Units.gridUnit * 11
            text: shaderPackModel.metadata.version
            horizontalAlignment: Text.AlignLeft
            color: palette.text
        }
    }
}
