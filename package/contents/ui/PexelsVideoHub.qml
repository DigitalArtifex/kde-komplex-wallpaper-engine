import QtQuick
import QtQuick.Controls
import QtQuick.Dialogs
import QtQuick.Layouts
import QtMultimedia

import Komplex.Pexels.Video as Pexels

Item
{
    property alias selectedFile: searchModel.lastSavedFile

    id: mainItem
    anchors.fill: parent

    Pexels.SearchModel
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
                    property int idealCellHeight: 220
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
                        property int originalHeight: videoHeight
                        property int originalWidth: videoWidth
                        property int videoId: id
                        property string author: user
                        property string authorUrl: userUrl
                        property string videoUrl: videoUrl
                        property string thumbnailUrl: thumbnail

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

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: (mouse) =>
                                {
                                    view.currentIndex = parent.parent.itemIndex
                                    searchModel.currentIndex = view.currentIndex
                                }
                            }
                        }

                        Text
                        {
                            property string externalLink: authorUrl

                            elide: Text.ElideRight
                            topPadding: 4
                            bottomPadding: 2
                            text: "<h3>" + author + "</h3>"
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 280
                            color: palette.link

                            MouseArea
                            {
                                anchors.fill: parent
                                onClicked: (mouse) =>
                                {
                                    Qt.openUrlExternally(parent.externalLink)
                                }
                                cursorShape: Qt.PointingHandCursor
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
                                    downloadDialog.user = entry.author
                                    downloadDialog.userUrl = entry.authorUrl
                                    downloadDialog.thumbnail = entry.thumbnailUrl
                                    downloadDialog.id = entry.videoId
                                    downloadDialog.open()
                                    searchModel.videoModel.update()
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
                    color: palette.text
                    text: "Videos provided by Pexels"
                    font.bold: true

                    onLinkActivated: (link) => Qt.openUrlExternally(link)

                    MouseArea
                    {
                        anchors.fill: parent
                        onClicked: (mouse) =>
                        {
                            Qt.openUrlExternally("https://www.pexels.com")
                        }
                        cursorShape: Qt.PointingHandCursor
                    }
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
        anchors.fill: parent
        visible: searchModel.status === Pexels.SearchModel.Searching

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
        property string user
        property string userUrl
        property string thumbnail
        property string preview
        property int id

        id: downloadDialog
        modal: Qt.WindowModal
        width: 600
        height: 440

        anchors.centerIn: parent
        clip: true

        ColumnLayout
        {
            anchors.fill: parent

            Text
            {
                property string externalLink: downloadDialog.userUrl

                elide: Text.ElideRight
                text: "<h3>" + downloadDialog.user + "</h3>"
                width: 280
                color: palette.link

                MouseArea
                {
                    anchors.fill: parent
                    onClicked: (mouse) =>
                    {
                        Qt.openUrlExternally(parent.externalLink)
                    }
                    cursorShape: Qt.PointingHandCursor
                }
            }

            Rectangle
            {
                Layout.fillWidth: true
                Layout.preferredHeight: 300
                color: "black"
                ColumnLayout
                {
                    anchors.fill: parent
                    spacing: 0

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
                        Layout.preferredWidth: 500
                        Layout.preferredHeight: 281
                        Layout.alignment: Qt.AlignHCenter
                        fillMode: VideoOutput.PreserveAspectCrop
                        smooth: true

                        onHeightChanged: this.sizeChanged()

                        MediaPlayer
                        {
                            id: mediaPlayer
                            videoOutput: videoOutput
                            source: Qt.resolvedUrl(downloadSelector.currentValue ? downloadSelector.currentValue : "")

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
                                if(mediaPlayer.source !== "")
                                    mediaPlayer.play()
                                else
                                    mediaPlayer.stop()
                            }
                        }

                        function start() { mediaPlayer.play() }
                        function stop() { mediaPlayer.stop() }
                        function seek(position) { mediaPlayer.setPosition(position); }

                        Image
                        {
                            visible: !mediaPlayer.playing
                            anchors.fill: parent

                            fillMode: Image.PreserveAspectFill
                            source: downloadDialog.thumbnail
                        }
                    }

                    Rectangle
                    {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 18
                        color: palette.alternateBase
                        RowLayout
                        {
                            anchors.fill: parent
                            spacing: 0

                            ProgressBar
                            {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                from: 0
                                to: mediaPlayer.duration
                                value: mediaPlayer.position
                            }
                            Button
                            {
                                Layout.preferredHeight: 18
                                Layout.preferredWidth: 18
                                icon.name: mediaPlayer.playing ? "stop-symbolic" : "play-symbolic"
                                icon.height: 16
                                icon.width: 16
                                onClicked: () =>
                                {
                                    if(mediaPlayer.playing)
                                        mediaPlayer.stop()
                                    else
                                        mediaPlayer.play()
                                }
                            }
                        }
                    }
                }
            }

            Text
            {
                text: qsTr("Download Options")
                color: palette.text
                font.bold: true
                Layout.fillHeight: true
                verticalAlignment: Text.AlignBottom
            }

            RowLayout
            {
                Layout.fillWidth: true
                Layout.preferredHeight: downloadSelector.height
                ComboBox
                {
                    id: downloadSelector
                    Layout.fillWidth: true
                    model: searchModel.videoModel
                    textRole: "text"
                    valueRole: "url"
                }

                Button
                {
                    enabled: downloadSelector.currentIndex >= 0
                    Layout.preferredHeight: downloadSelector.height
                    Layout.preferredWidth: downloadSelector.height
                    icon.name: "image-symbolic"

                    id: downloadButton

                    onClicked: () =>
                    {
                        downloadDialog.close();
                        progressDialog.thumbnail = downloadDialog.thumbnail
                        progressDialog.author = downloadDialog.user
                        progressDialog.open()
                        searchModel.videoModel.download(downloadSelector.currentIndex)
                    }
                }
            }
        }

        Connections
        {
            target: searchModel.videoModel
            function onStatusChanged()
            {
                if(searchModel.videoModel.status === 0)
                    downloadSelector.currentIndex = 0
            }
        }

        onClosed: () =>
        {
            mediaPlayer.stop()
        }

        Rectangle
        {
            color: palette.base
            anchors.fill: parent
            visible: searchModel.videoModel.status === 1

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
    }

    Dialog
    {
        property string author
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
                text: "Downloading Video..."
                color: palette.text
            }

            ProgressBar
            {
                value: searchModel.videoModel.downloadProgress
                Layout.fillWidth: true
                Layout.preferredHeight: 6
            }
        }

        Connections
        {
            target: searchModel.videoModel
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
