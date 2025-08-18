import QtQuick

Item
{
    property alias sourceItem: source.sourceItem
    property alias format: source.format
    property alias hideSource: source.hideSource
    property alias live: source.live
    property alias mipmap: source.mipmap
    property alias recursive: source.recursive
    property alias samples: source.samples
    property alias sourceRect: source.sourceRect
    property alias textureMirroring: source.textureMirroring
    property alias textureSize: source.textureSize
    property alias wrapMode: source.wrapMode

    anchors.fill: parent

    ShaderEffectSource
    {
        anchors.fill: parent
        id: source
    }
}