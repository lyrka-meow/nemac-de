import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import NemacUI 1.0 as NemacUI
import Nemac.Mpris 1.0

Item {
    id: control
    clip: false

    readonly property int contentMargin: 20
    implicitHeight: visible ? 210 : 0
    
    property bool isPlaying: mprisManager.playbackStatus === Mpris.Playing
    
    property string artUrl: ""
    property string title: ""
    property string artist: ""

    MprisManager {
        id: mprisManager
        
        onMetadataChanged: {
            var meta = mprisManager.metadata
            var newArt = meta[Mpris.metadataToString(Mpris.ArtUrl)] || ""
            var newTitle = meta[Mpris.metadataToString(Mpris.Title)] || ""
            var newArtist = meta[Mpris.metadataToString(Mpris.Artist)] || ""
            
            control.artUrl = newArt
            control.title = newTitle
            control.artist = newArtist
            
            control.visible = (newTitle !== "" || newArtist !== "")
        }
    }

    Timer {
        interval: 500
        running: control.visible && control.isPlaying
        repeat: true
        onTriggered: {
            if (!seekSlider.pressed)
                seekSlider.value = mprisManager.position
        }
    }

    Rectangle {
        id: panelBg
        anchors.fill: parent
        radius: 24
        color: "#0d0d0d"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: panelBg.width
                height: panelBg.height
                radius: 24
            }
        }

        Image {
            id: bgBlurImage
            anchors.fill: parent
            source: control.artUrl ? control.artUrl : "qrc:/images/media-cover.svg"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.4
            visible: control.artUrl !== ""
        }

        FastBlur {
            anchors.fill: bgBlurImage
            source: bgBlurImage
            radius: 50
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0,0,0, 0.4) }
                GradientStop { position: 1.0; color: "#000000" }
            }
        }
    }

    RowLayout {
        id: mainRow
        anchors.fill: parent
        anchors.margins: contentMargin
        spacing: 20

        Item {
            id: discSection
            Layout.preferredWidth: 150
            Layout.preferredHeight: 150
            Layout.alignment: Qt.AlignVCenter

            Rectangle {
                id: haloLayer
                anchors.centerIn: parent
                width: 130; height: 130
                radius: 65
                color: "transparent"
                visible: control.isPlaying

                layer.enabled: true
                layer.effect: RectangularGlow {
                    glowRadius: 25
                    spread: 0.2
                    color: Qt.rgba(NemacUI.Theme.highlightColor.r, 
                                   NemacUI.Theme.highlightColor.g, 
                                   NemacUI.Theme.highlightColor.b, 0.5)
                    cornerRadius: 80
                }
            }

            Item {
                id: rotatingDisc
                anchors.fill: parent

                RotationAnimation on rotation {
                    from: 0; to: 360; duration: 25000
                    loops: Animation.Infinite
                    running: control.isPlaying
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 75
                    color: "#050505"
                    clip: true
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.1)

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: control.artUrl ? control.artUrl : "qrc:/images/media-cover.svg"
                        fillMode: Image.PreserveAspectCrop
                        
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: 150; height: 150; radius: 75 }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 28; height: 28
                        radius: 14
                        color: "#000000"
                        border.width: 3
                        border.color: "#0a0a0a"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 6; height: 6
                            radius: 3
                            color: "#1a1a1a"
                        }
                    }
                }
            }
        }

        ColumnLayout {
            id: infoSection
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            Column {
                Layout.fillWidth: true
                spacing: 2
                Label {
                    text: control.title || "No Media"
                    width: parent.width
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                    color: "#FFFFFF"
                    elide: Text.ElideRight
                }
                Label {
                    text: control.artist || "Unknown Artist"
                    width: parent.width
                    font.pixelSize: 13
                    opacity: 0.6
                    color: "#FFFFFF"
                    elide: Text.ElideRight
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                Slider {
                    id: seekSlider
                    Layout.fillWidth: true
                    from: 0
                    to: mprisManager.metadata[Mpris.metadataToString(Mpris.Length)] || 1
                    value: mprisManager.position

                    background: Rectangle {
                        x: seekSlider.leftPadding
                        y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                        implicitHeight: 3
                        width: seekSlider.availableWidth
                        height: implicitHeight
                        radius: 1.5
                        color: Qt.rgba(1, 1, 1, 0.1)

                        Rectangle {
                            width: seekSlider.visualPosition * parent.width
                            height: parent.height
                            radius: 1.5
                            color: NemacUI.Theme.highlightColor
                        }
                    }

                    handle: Rectangle {
                        x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                        y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                        implicitWidth: 10; implicitHeight: 10; radius: 5
                        color: "#FFFFFF"
                    }

                    onMoved: mprisManager.setPosition(Math.round(value))
                }

                RowLayout {
                    Layout.fillWidth: true
                    Label { text: formatTime(seekSlider.value); font.pixelSize: 9; opacity: 0.4; color: "#FFFFFF" }
                    Item { Layout.fillWidth: true }
                    Label { text: formatTime(seekSlider.to); font.pixelSize: 9; opacity: 0.4; color: "#FFFFFF" }
                }
            }

            RowLayout {
                Layout.alignment: Qt.AlignLeft
                spacing: 25

                IconButton {
                    implicitWidth: 28; implicitHeight: 28
                    source: "qrc:/images/dark/media-skip-backward-symbolic.svg"
                    onLeftButtonClicked: mprisManager.previous()
                    opacity: 0.7
                }

                Rectangle {
                    id: playBtn
                    width: 50; height: 50
                    radius: 25
                    color: NemacUI.Theme.highlightColor
                    
                    layer.enabled: true
                    layer.effect: DropShadow {
                        radius: 12; samples: 20; verticalOffset: 3
                        color: Qt.rgba(NemacUI.Theme.highlightColor.r, 
                                       NemacUI.Theme.highlightColor.g, 
                                       NemacUI.Theme.highlightColor.b, 0.3) 
                    }

                    Image {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: control.isPlaying ? 0 : 2
                        width: 22; height: 22
                        source: control.isPlaying ? "qrc:/images/dark/media-playback-pause-symbolic.svg" 
                                                  : "qrc:/images/dark/media-playback-start-symbolic.svg"
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: mprisManager.playPause()
                        onPressed: playBtn.scale = 0.9
                        onReleased: playBtn.scale = 1.0
                    }
                }

                IconButton {
                    implicitWidth: 28; implicitHeight: 28
                    source: "qrc:/images/dark/media-skip-forward-symbolic.svg"
                    onLeftButtonClicked: mprisManager.next()
                    opacity: 0.7
                }
            }
        }
    }

    function formatTime(us) {
        var sec = Math.floor(Number(us) / 1000000)
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }
}
