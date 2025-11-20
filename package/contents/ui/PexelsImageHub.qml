import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts

import com.github.digitalartifex.komplex as Komplex

Item
{
    property alias selectedFile: searchModel.lastSavedFile

    id: mainItem

    Komplex.PexelsImageSearchModel
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
                        property int itemIndex: index
                        property int originalHeight: imageHeight
                        property int originalWidth: imageWidth
                        property int imageId: id
                        property string author: photographer
                        property string authorUrl: photographerUrl
                        property string imageUrl: original
                        property string thumbnailUrl: thumbnail
                        property string altText: alt
                        property string largeThumbnail: large

                        id: entry

                        leftPadding: Math.floor((width - thumbnailImage.width) / 2)
                        topPadding: 10
                        rightPadding: Math.floor((width - thumbnailImage.width) / 2)
                        bottomPadding: 10
                        width: view.cellWidth

                        Image
                        {
                            width: 280
                            height: 200
                            id: thumbnailImage
                            source: thumbnail
                            anchors.horizontalCenter: parent.horizontalCenter
                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: (mouse) => {
                                    view.currentIndex = parent.parent.itemIndex
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
                        }
                        Text
                        {
                            property string externalLink: photographerUrl

                            elide: Text.ElideRight
                            topPadding: 4
                            bottomPadding: 2
                            text: "<h3>" + photographer + "</h3>"
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 280
                            color: palette.link
                            font.bold: true

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: (mouse) => {
                                    Qt.openUrlExternally(parent.externalLink)
                                }
                            }
                        }
                        Text
                        {
                            leftPadding: 8
                            rightPadding: 8
                            text: qsTr(alt)
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
                                text: "Download & Preview"
                                
                                icon.source: "./icons/download.svg"
                                icon.name: "download-symbolic"

                                onClicked: {
                                    downloadDialog.imageHeight = entry.originalHeight
                                    downloadDialog.imageWidth = entry.originalWidth
                                    downloadDialog.photographer = entry.author
                                    downloadDialog.photographerUrl = entry.authorUrl
                                    downloadDialog.alt = entry.altText
                                    downloadDialog.thumbnail = entry.largeThumbnail
                                    downloadDialog.imageUrl = entry.imageUrl
                                    downloadDialog.id = entry.imageId
                                    downloadDialog.open()
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
                    color: palette.link
                    text: "<a href=\"https://www.pexels.com\">Photos provided by Pexels</a>"
                    font.bold: true

                    onLinkActivated: (link) => Qt.openUrlExternally(link)
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
        property string photographer
        property string photographerUrl
        property string imageUrl
        property string thumbnail
        property string alt
        property int imageHeight
        property int imageWidth
        property int id

        id: downloadDialog
        modal: Qt.WindowModal
        width: 600
        height: 420

        anchors.centerIn: parent
        clip: true

        ColumnLayout
        {
            anchors.fill: parent

            Text
            {
                property string externalLink: downloadDialog.photographerUrl

                elide: Text.ElideRight
                topPadding: 4
                bottomPadding: 2
                text: "<h3>" + downloadDialog.photographer + "</h3>"
                width: 280
                color: palette.link
                font.bold: true

                MouseArea
                {
                    anchors.fill: parent
                    onClicked: (mouse) => {
                        Qt.openUrlExternally(parent.externalLink)
                    }
                }
            }

            Image
            {
                Layout.fillHeight: true
                Layout.fillWidth: true

                fillMode: Image.PreserveAspectCrop
                source: downloadDialog.thumbnail
            }

            Text
            {
                Layout.fillWidth: true
                leftPadding: 8
                rightPadding: 8
                text: qsTr(downloadDialog.alt)
                elide: Text.ElideRight
                width: 280
                color: palette.text
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                maximumLineCount: 4
                font.italic: true
            }

            Button
            {
                Layout.fillWidth: true
                text: "Download (" + downloadDialog.imageWidth + "x" + downloadDialog.imageHeight + ")"
                icon.source: "./icons/download.svg"
                icon.name: "download-symbolic"
                hoverEnabled: true
                ToolTip.text: "Download"
                ToolTip.visible: hovered

                onClicked: () =>
                {
                    downloadDialog.close();
                    progressDialog.thumbnail = downloadDialog.thumbnail
                    progressDialog.photographer = downloadDialog.photographer
                    progressDialog.open()
                    searchModel.download(downloadDialog.imageUrl, downloadDialog.id)
                }
            }
        }
    }

    Dialog
    {
        property string photographer
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
                source: downloadDialog.thumbnail
            }

            Text
            {
                text: "Downloading Photo..."
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

    function updateSearch()
    {
        console.log(searchField.text)
        searchModel.query = searchField.text
    }

}
