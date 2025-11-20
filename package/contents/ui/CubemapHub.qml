import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import com.github.digitalartifex.komplex as Komplex

Item
{
    property alias selectedFile: searchModel.lastSavedFile

    id: mainItem

    Komplex.CubemapSearchModel
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
            Rectangle {
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
                    property int idealCellHeight: 300
                    property int idealCellWidth: 300
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
                        id: entry

                        leftPadding: Math.floor((width - thumbnailImage.width) / 2)
                        topPadding: 10
                        rightPadding: Math.floor((width - thumbnailImage.width) / 2)
                        bottomPadding: 10
                        width: view.cellWidth

                        required property string id
                        required property string name
                        required property string description
                        required property string thumbnail
                        required property int index
                        property int itemIndex: index

                        Image
                        {
                            width: 280
                            height: 200
                            id: thumbnailImage
                            source: parent.thumbnail//"https://api.artifex.services/v1/cubemaps/thumbnail/" + parent.id
                            anchors.horizontalCenter: parent.horizontalCenter

                            MouseArea
                            {
                                z: 9000
                                anchors.fill: parent
                                onClicked: (mouse) => {
                                    view.currentIndex = entry.itemIndex
                                }
                            }

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
                        }
                        Text
                        {
                            elide: Text.ElideRight
                            topPadding: 4
                            bottomPadding: 2
                            text: "<h3>" + name + "</h3>"
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 280
                            color: palette.link
                            font.bold: true
                        }
                        Text
                        {
                            leftPadding: 8
                            rightPadding: 8
                            text: qsTr(description)
                            anchors.horizontalCenter: parent.horizontalCenter
                            elide: Text.ElideRight
                            width: 280
                            color: palette.text
                            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                            maximumLineCount: 2
                            font.italic: true
                        }
                        RowLayout
                        {
                            visible: parent.itemIndex === view.currentIndex
                            width: 280
                            Button
                            {
                                Layout.topMargin: 4
                                Layout.alignment: Qt.AlignHCenter
                                Layout.preferredHeight: 32
                                Layout.fillWidth: true
                                text: "Download"
                                
                                icon.source: "./icons/download.svg"
                                icon.name: "download-symbolic"

                                onClicked: {
                                    progressDialog.id = entry.id
                                    progressDialog.description = entry.description
                                    progressDialog.name = entry.name
                                    progressDialog.thumbnail = entry.thumbnail
                                    progressDialog.open()
                                    searchModel.download(entry.id)
                                }
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
                enabled: searchModel.previousPage !== ""
                onClicked: searchModel.back()
            }

            RowLayout
            {
                Layout.margins: 6
                Layout.fillWidth: true

                Text
                {
                    visible: searchModel.totalResults > 0
                    color: palette.text
                    text: (searchModel.currentOffset + 1) + "-" + (searchModel.resultsPerPage + searchModel.currentOffset) + " of " + searchModel.totalResults
                }

                Text
                {
                    color: palette.text
                    Layout.fillWidth: true
                    text: "Page " + (searchModel.currentOffset / searchModel.resultsPerPage) + " of " + Math.ceil(searchModel.totalResults / searchModel.resultsPerPage)
                }
            }
            Button
            {
                text: "Next"
                enabled: searchModel.nextPage !== ""
                onClicked: searchModel.next()
            }
        }
    }

    Rectangle
    {
        color: palette.base
        width: mainItem.width
        height: mainItem.height
        visible: searchModel.status === Komplex.PexelsImageSearchModel.Searching

        RowLayout
        {
            anchors.fill: parent

            BusyIndicator
            {
                Layout.alignment: Qt.AlignCenter
                Layout.preferredHeight: 128
                Layout.preferredWidth: 128
                visible: running
            }
        }
    }

    Dialog
    {
        property string name
        property string description
        property string id
        property string thumbnail

        modal: Qt.WindowModal
        width: 600
        height: 420

        anchors.centerIn: parent
        clip: true

        id: progressDialog

        ColumnLayout
        {
            anchors.fill: parent

            Image
            {
                Layout.fillHeight: true
                Layout.fillWidth: true

                fillMode: Image.PreserveAspectCrop
                source: progressDialog.thumbnail
            }

            Text
            {
                text: "Downloading Cubemap..."
                color: palette.text
            }

            ProgressBar
            {
                value: searchModel.downloadProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 6
            }
        }

        Connections
        {
            target: searchModel
            function onDownloadFinished()
            {
                progressDialog.close()
            }
        }
    }

    Dialog
    {
        width: 420
        height: 105

        id: warningDialog
        ColumnLayout
        {
            Text
            {
                id: header
                text: "Installation Error"
                font.pointSize: 14
                color: palette.text
            }
            Text
            {
                id: informative
                text: searchModel.statusMessage
                font.pointSize: 10
                color: palette.text
            }
            DialogButtonBox
            {
                Layout.alignment: Qt.AlignRight
                standardButtons: DialogButtonBox.Ok
                onAccepted: warningDialog.close()
            }
        }

        Connections
        {
            target: searchModel
            function onStatusChanged()
            {
                if(searchModel.status === Komplex.CubemapSearchModel.Error)
                {
                    warningDialog.open();
                    progressDialog.close();
                }
            }
        }
    }

    function updateSearch()
    {
        console.log(searchField.text)
        searchModel.query = searchField.text
    }
}
