import QtCore
import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtMultimedia
import QtWebView

import Komplex.ShaderToy as ShaderToy

Item
{
    id: mainItem
    anchors.fill: parent

    ShaderToy.SearchModel
    {
        id: searchModel
    }

    ColumnLayout
    {
        anchors.fill: parent

        RowLayout
        {
            Layout.fillHeight: false
            Layout.fillWidth: true
            Layout.margins: 6

            TextField
            {
                Layout.preferredHeight: 32
                Layout.fillWidth: true

                id: searchField
                placeholderText: "Search"
                onEditingFinished: mainItem.updateSearch()
                Keys.onPressed: (event) =>
                {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
                    {
                        searchField.focus = false; // Unfocus the TextField
                        event.accepted = true; // Prevent further propagation of the key event
                    }
                }
            }

            Button
            {
                Layout.preferredHeight: 32
                Layout.preferredWidth: 32

                icon.name: "search-symbolic"

                onClicked: mainItem.updateSearch()
            }
        }

        Component
        {
            id: highlight
            Rectangle
            {
                width: view.cellWidth; height: view.cellHeight
                color: palette.highlight; radius: 5
                x: view.currentItem.x
                y: view.currentItem.y
                Behavior on x { SpringAnimation { spring: 3; damping: 0.2 } }
                Behavior on y { SpringAnimation { spring: 3; damping: 0.2 } }
            }
        }

        Rectangle
        {
            Layout.fillHeight: true
            Layout.fillWidth: true
            color: palette.base
            clip: true

            RowLayout
            {
                anchors.fill: parent

                GridView
                {
                    // The standard size
                    property int idealCellHeight: 200
                    property int idealCellWidth: 250
                    cellWidth: width / Math.floor(width / idealCellWidth)
                    cellHeight: idealCellHeight

                    id: view

                    model: searchModel
                    highlight: highlight
                    highlightFollowsCurrentItem: false

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    Layout.margins: 6

                    delegate: Column
                    {
                        property int itemIndex: index
                        property string shaderThumbnail: thumbnail
                        property string shaderEmbed: embedUrl
                        property string shaderId: id
                        property string author: username
                        property string shaderDescription: model.description

                        id: entry

                        leftPadding: Math.floor((width - thumbnailImage.width) / 2)
                        topPadding: 10
                        rightPadding: Math.floor((width - thumbnailImage.width) / 2)
                        bottomPadding: 10
                        width: view.cellWidth

                        Image
                        {
                            width: 250
                            height: 140
                            id: thumbnailImage
                            source: thumbnail
                            anchors.horizontalCenter: parent.horizontalCenter

                            Rectangle
                            {
                                color: palette.base
                                anchors.fill: parent
                                visible: thumbnailImage.status === Image.Loading

                                RowLayout
                                {
                                    anchors.fill: parent

                                    BusyIndicator
                                    {
                                        Layout.alignment: Qt.AlignCenter
                                        Layout.preferredHeight: 64
                                        Layout.preferredWidth: 64
                                        visible: running
                                    }
                                }
                            }

                            Rectangle
                            {
                                color: palette.dark
                                anchors.fill: parent
                                visible: thumbnailImage.status === Image.Error

                                Text
                                {
                                    color: palette.text
                                    anchors.centerIn: parent
                                    text: qsTr("Error Loading Image")
                                }
                            }

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked:
                                    (mouse) => {
                                        view.currentIndex = parent.parent.itemIndex
                                        //searchModel.currentIndex = view.currentIndex
                                    }
                            }
                        }

                        RowLayout
                        {
                            visible: parent.itemIndex === view.currentIndex
                            width: thumbnailImage.width
                            Button
                            {
                                Layout.topMargin: 4
                                Layout.alignment: Qt.AlignRight
                                Layout.preferredHeight: 32
                                Layout.fillWidth: true
                                icon.name: "emblem-downloads"
                                text: qsTr("Preview & Download")
                                onClicked: () =>
                                {
                                    downloadDialog.open()
                                }
                            }
                        }

                        Dialog
                        {
                            id: downloadDialog
                            modal: Qt.WindowModal
                            width: 600
                            height: 440

                            parent: mainItem
                            anchors.centerIn: mainItem
                            clip: true

                            ColumnLayout
                            {
                                anchors.fill: parent

                                WebView
                                {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    id: shaderPreview
                                    Layout.preferredWidth: 500
                                    Layout.preferredHeight: 281
                                    Layout.alignment: Qt.AlignHCenter
                                    url: ""
                                }

                                Text
                                {
                                    Layout.preferredHeight: 64
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    id: shaderDescription
                                    text: model.description
                                    elide: Text.ElideRight
                                    wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                                    maximumLineCount: 3
                                    color: palette.text
                                }

                                Button
                                {
                                    Layout.fillWidth: true
                                    icon.name: "image-symbolic"

                                    id: downloadButton
                                    text: qsTr("Convert to Komplex Pack")

                                    onClicked: () =>
                                    {
                                        workingThumbnail.source = model.thumbnail
                                        searchModel.convert(model.index);
                                        downloadDialog.close();
                                    }
                                }
                            }

                            onClosed: () =>
                            {
                                shaderPreview.loadHtml(`<html><head></head><body></body></html>`)
                            }

                            onOpened: () =>
                            {
                                shaderDescription.text = model.description
                                shaderPreview.loadHtml(`<html><head></head><body style="background-color:${palette.base.toString(16)};"><center><iframe src="${model.embedUrl}?gui=true&t=10&paused=false&muted=true" width="500" height="281" frameborder="0" allowfullscreen="allowfullscreen" /></center></body></html>`)
                            }
                        }
                    }
                    populate: Transition
                    {
                        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 1000 }
                    }
                }
            }
        }

        RowLayout
        {
            Layout.margins: 6
            Layout.fillWidth: true

            Button
            {
                text: "Previous"
                enabled: searchModel.currentPage > 1
                onClicked: searchModel.previous()
            }

            RowLayout
            {
                Layout.margins: 6
                Layout.fillWidth: true

                Text
                {
                    visible: searchModel.totalResults > 0
                    color: palette.text
                    text: ((searchModel.resultsPerPage * searchModel.currentPage) - searchModel.resultsPerPage + 1) + "-" + (searchModel.resultsPerPage * searchModel.currentPage) + " of " + searchModel.totalResults
                }

                Text
                {
                    color: palette.text
                    Layout.fillWidth: true
                    text: "Page " + searchModel.currentPage + " of " + Math.ceil(searchModel.totalResults / searchModel.resultsPerPage)
                }

                Text
                {
                    color: palette.text
                    text: "Shaders provided by ShaderToy"
                    font.bold: true

                    onLinkActivated: (link) => Qt.openUrlExternally(link)

                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked: (mouse) => Qt.openUrlExternally("https://www.shadertoy.com")
                        cursorShape: Qt.PointingHandCursor
                    }
                }
            }
            Button
            {
                text: "Next"
                enabled: searchModel.currentPage <= searchModel.totalPages
                onClicked: searchModel.next()
            }
        }
    }

    Rectangle
    {
        color: palette.base
        anchors.fill: parent
        visible: searchModel.status === ShaderToy.SearchModel.Searching || searchModel.status === ShaderToy.SearchModel.Compiling

        RowLayout
        {
            anchors.fill: parent

            Image
            {
                visible: searchModel.status === ShaderToy.SearchModel.Compiling
                Layout.fillHeight: true
                Layout.fillWidth: true

                fillMode: Image.PreserveAspectCrop
                id: workingThumbnail
            }

            Text
            {
                id: stateText
                text: searchModel.statusMessage
                color: palette.text
                elide: Text.ElideRight
                visible: searchModel.status === ShaderToy.SearchModel.Compiling
            }

            ProgressBar
            {
                id: totalProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                visible: searchModel.status === ShaderToy.SearchModel.Compiling
            }

            Text
            {
                id: downloadText
                text: qsTr(searchModel.downloadText)
                color: palette.text
                elide: Text.ElideRight
                visible: searchModel.totalDownloads > 0 && searchModel.status === ShaderToy.SearchModel.Compiling
            }

            ProgressBar
            {
                id: downloadProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 6
                from: 0
                to: searchModel.totalDownloads
                value: searchModel.completedDownloads
                visible: searchModel.totalDownloads > 0 && searchModel.status === ShaderToy.SearchModel.Compiling
            }
        }

        BusyIndicator
        {
            Layout.alignment: Qt.AlignCenter
            width: 128
            height: 128
            visible: running
            anchors.centerIn: parent
        }
    }

    Rectangle
    {
        property int totalVideos: searchModel.videoSelections.length
        property int selectedVideos: 0

        anchors.fill: parent
        color: palette.base
        visible: searchModel.status === ShaderToy.SearchModel.Compiled
        enabled: visible

        id: mediaSelectionItem

        signal accepted

        ColumnLayout
        {
            anchors.fill: parent
            Text
            {
                Layout.margins: 6
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                Layout.preferredHeight: 50
                color: palette.text
                text: "<h2>Select Media</h2>";
            }

            Text
            {
                Layout.margins: 6
                Layout.alignment: Qt.AlignTop
                Layout.fillWidth: true
                color: palette.text
                text: qsTr("The shader you selected contains one or more video references. However, the videos available on ShaderToy are not likely to be desired.\n\nPlease select a new video source from your local drive or from Pexels.")
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            }

            Repeater
            {
                Layout.fillWidth: true
                Layout.margins: 6
                model: searchModel.videoSelections

                Item
                {
                    width: parent.width
                    required property string modelData

                    RowLayout
                    {
                        anchors.fill: parent

                        TextField
                        {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 35
                            id: mediaSelectionField
                            placeholderText: "Select Media Source"
                            color: palette.text
                            onEditingFinished:
                            {
                                if(text.length > 0)
                                    mediaSelectionItem.selectedVideos += 1
                                else if(mediaItem.selectedVideos > 0)
                                    mediaSelectionItem.selectedVideos -= 1
                            }
                        }

                        Button
                        {
                            icon.name: "folder-symbolic"
                            onClicked: fileDialog.open()
                        }

                        Button
                        {
                            icon.name: "network-symbolic"
                            onClicked: pexelsDialog.open()
                        }
                    }

                    FileDialog
                    {
                        id: fileDialog
                        currentFolder: StandardPaths.standardLocations(StandardPaths.HomeLocation)[0]
                        onAccepted:
                        {
                            mediaSelectionField.text = selectedFile
                            close();
                        }
                    }

                    Dialog
                    {
                        width: 640
                        height: 480
                        id: pexelsDialog

                        parent: mainItem
                        anchors.centerIn: parent

                        PexelsVideoHub
                        {
                            onSelectedFileChanged:
                            {
                                mediaSelectionField.text = selectedFile
                                mediaSelectionField.editingFinished()
                                pexelsDialog.close()
                            }
                        }
                    }

                    Connections
                    {
                        target: mediaSelectionItem
                        function onAccepted()
                        {
                            searchModel.replaceSource(view.currentIndex, modelData, mediaSelectionField.text)
                        }
                    }
                }
            }

            Rectangle
            {
                color: "transparent"
                Layout.fillHeight: true
                Layout.fillWidth: true
            }

            Button
            {
                Layout.preferredHeight: 35
                Layout.alignment: Qt.AlignRight | Qt.AlignBottom
                text: qsTr("Accept")
                enabled: mediaSelectionItem.totalVideos === mediaSelectionItem.selectedVideos

                onClicked: mediaSelectionItem.accepted()
            }
        }
    }

    MessageDialog
    {
        buttons: MessageDialog.Ok
        id: warningDialog
        text: searchModel.statusMessage

        Connections
        {
            target: searchModel
            function onStatusChanged()
            {
                console.log("Search Model Status " + searchModel.status)

                if(searchModel.status === ShaderToy.SearchModel.Error)
                {
                    warningDialog.open();
                }
            }
        }
    }

    MessageDialog
    {
        buttons: MessageDialog.Ok
        id: messageDialog
        text: searchModel.statusMessage

        Connections
        {
            target: searchModel
            function onShaderInstalled()
            {
                messageDialog.open();
            }
        }
    }

    function updateSearch()
    {
        console.log(searchField.text)
        searchModel.currentPage = 1
        searchModel.query = searchField.text
    }
}
