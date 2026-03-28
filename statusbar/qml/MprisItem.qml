import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import NemacUI 1.0 as NemacUI
import Nemac.Mpris 1.0

Item {
    id: control
    clip: false

    readonly property int contentMargin: 22
    implicitHeight: visible ? 440 : 0
    
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
        radius: 30
        color: "#0a0a0a"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: panelBg.width
                height: panelBg.height
                radius: 30
            }
        }

        Image {
            id: bgBlurImage
            anchors.fill: parent
            source: control.artUrl ? control.artUrl : "qrc:/images/media-cover.svg"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.45
            visible: control.artUrl !== ""
        }

        FastBlur {
            anchors.fill: bgBlurImage
            source: bgBlurImage
            radius: 60
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(0,0,0, 0.5) }
                GradientStop { position: 0.5; color: Qt.rgba(0,0,0, 0.8) }
                GradientStop { position: 1.0; color: "#000000" }
            }
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: contentMargin
        spacing: 12

        Item {
            id: discSection
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            width: 210; height: 210

            // Слой Halo (мягкое свечение за диском)
            Rectangle {
                id: haloLayer
                anchors.centerIn: parent
                width: 190; height: 190
                radius: 95
                color: "transparent"
                visible: control.isPlaying

                layer.enabled: true
                layer.effect: RectangularGlow {
                    glowRadius: 35
                    spread: 0.15
                    color: Qt.rgba(NemacUI.Theme.highlightColor.r, 
                                   NemacUI.Theme.highlightColor.g, 
                                   NemacUI.Theme.highlightColor.b, 0.6)
                    cornerRadius: 100
                }
            }

            // Вращающийся диск
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
                    radius: 105
                    color: "#050505"
                    clip: true
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.15)

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: control.artUrl ? control.artUrl : "qrc:/images/media-cover.svg"
                        fillMode: Image.PreserveAspectCrop
                        
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: 210; height: 210; radius: 105 }
                        }
                    }

                    // Центральное отверстие (виниловый стиль)
                    Rectangle {
                        anchors.centerIn: parent
                        width: 36; height: 36
                        radius: 18
                        color: "#000000"
                        border.width: 4
                        border.color: "#0a0a0a"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 8; height: 8
                            radius: 4
                            color: "#1a1a1a"
                        }
                    }
                }
            }
        }

        Column {
            Layout.fillWidth: true
            Layout.topMargin: 6
            spacing: 2
            
            Label {
                text: control.title || "No Media"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 22
                font.weight: Font.DemiBold
                color: "#FFFFFF"
                elide: Text.ElideRight
                
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 4; samples: 8; color: "black"; verticalOffset: 1
                }
            }
            
            Label {
                text: control.artist || "Unknown Artist"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 15
                opacity: 0.6
                color: "#FFFFFF"
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 6

            Slider {
                id: seekSlider
                Layout.fillWidth: true
                from: 0
                to: mprisManager.metadata[Mpris.metadataToString(Mpris.Length)] || 1
                value: mprisManager.position

                background: Rectangle {
                    x: seekSlider.leftPadding
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitHeight: 4
                    width: seekSlider.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: Qt.rgba(1, 1, 1, 0.12)

                    Rectangle {
                        width: seekSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 2
                        color: NemacUI.Theme.highlightColor
                    }
                }

                handle: Rectangle {
                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitWidth: 12; implicitHeight: 12; radius: 6
                    color: "#FFFFFF"
                    antialiasing: true
                }

                onMoved: mprisManager.setPosition(Math.round(value))
            }

            RowLayout {
                Layout.fillWidth: true
                Label { text: formatTime(seekSlider.value); font.pixelSize: 10; opacity: 0.5; color: "#FFFFFF" }
                Item { Layout.fillWidth: true }
                Label { text: formatTime(seekSlider.to); font.pixelSize: 10; opacity: 0.5; color: "#FFFFFF" }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 8
            spacing: 40

            IconButton {
                implicitWidth: 34; implicitHeight: 34
                source: "qrc:/images/dark/media-skip-backward-symbolic.svg"
                onLeftButtonClicked: mprisManager.previous()
                opacity: 0.8
            }

            Rectangle {
                id: playBtn
                width: 70; height: 70
                radius: 35
                color: NemacUI.Theme.highlightColor
                
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 18; samples: 25; verticalOffset: 5
                    color: Qt.rgba(NemacUI.Theme.highlightColor.r, 
                                   NemacUI.Theme.highlightColor.g, 
                                   NemacUI.Theme.highlightColor.b, 0.4) 
                }

                Image {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: control.isPlaying ? 0 : 2
                    width: 32; height: 32
                    source: control.isPlaying ? "qrc:/images/dark/media-playback-pause-symbolic.svg" 
                                              : "qrc:/images/dark/media-playback-start-symbolic.svg"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mprisManager.playPause()
                    onPressed: playBtn.scale = 0.9
                    onReleased: playBtn.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }

            IconButton {
                implicitWidth: 34; implicitHeight: 34
                source: "qrc:/images/dark/media-skip-forward-symbolic.svg"
                onLeftButtonClicked: mprisManager.next()
                opacity: 0.8
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
