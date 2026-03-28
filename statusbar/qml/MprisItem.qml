import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import NemacUI 1.0 as NemacUI
import Nemac.Mpris 1.0

Item {
    id: control
    clip: true

    readonly property int contentMargin: 28
    implicitHeight: visible ? 520 : 0
    
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
        radius: 32
        color: NemacUI.Theme.darkMode ? "#121212" : "#FFFFFF"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)

        Item {
            anchors.fill: parent
            clip: true
            layer.enabled: true
            layer.effect: OpacityMask {
                maskSource: Rectangle { width: panelBg.width; height: panelBg.height; radius: 32 }
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
                radius: 64
            }

            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(0,0,0, 0.3) }
                    GradientStop { position: 1.0; color: NemacUI.Theme.darkMode ? "#121212" : "#F5F5F5" }
                }
            }
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: contentMargin
        spacing: 24

        Item {
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 10
            width: 240; height: 240

            Item {
                id: discRotationContainer
                anchors.fill: parent

                RotationAnimation on rotation {
                    id: discAnimation
                    from: 0; to: 360; duration: 8000
                    loops: Animation.Infinite
                    running: control.isPlaying
                }

                RectangularGlow {
                    anchors.fill: discImgContainer
                    glowRadius: 15
                    spread: 0.2
                    color: Qt.rgba(0, 0, 0, 0.5)
                    cornerRadius: 120
                }

                Rectangle {
                    id: discImgContainer
                    anchors.fill: parent
                    radius: 120
                    color: "#000000"
                    border.width: 4
                    border.color: Qt.rgba(1, 1, 1, 0.1)

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        anchors.margins: 2
                        source: control.artUrl ? control.artUrl : "qrc:/images/media-cover.svg"
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: 236; height: 236; radius: 118 }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 40; height: 40
                        radius: 20
                        color: "#121212"
                        border.width: 3
                        border.color: "#000000"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 10; height: 10
                            radius: 5
                            color: "#252525"
                        }
                    }
                }
            }
            
            Glow {
                anchors.fill: discRotationContainer
                radius: 20
                samples: 25
                color: NemacUI.Theme.highlightColor
                source: discRotationContainer
                opacity: 0.3
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: 6
            Label {
                text: control.title || "No Media Playing"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 26
                font.weight: Font.Bold
                color: NemacUI.Theme.textColor
                elide: Text.ElideRight
            }
            Label {
                text: control.artist || "Unknown Artist"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 17
                opacity: 0.6
                color: NemacUI.Theme.textColor
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 8

            Slider {
                id: seekSlider
                Layout.fillWidth: true
                from: 0
                to: mprisManager.metadata[Mpris.metadataToString(Mpris.Length)] || 1
                value: mprisManager.position

                background: Rectangle {
                    x: seekSlider.leftPadding
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitHeight: 6
                    width: seekSlider.availableWidth
                    height: implicitHeight
                    radius: 3
                    color: Qt.rgba(NemacUI.Theme.textColor.r, NemacUI.Theme.textColor.g, NemacUI.Theme.textColor.b, 0.1)

                    Rectangle {
                        width: seekSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 3
                        color: NemacUI.Theme.highlightColor
                    }
                }

                handle: Rectangle {
                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitWidth: 14; implicitHeight: 14; radius: 7
                    color: "#FFFFFF"
                    border.color: NemacUI.Theme.highlightColor
                    border.width: 2
                }

                onMoved: mprisManager.setPosition(Math.round(value))
            }

            RowLayout {
                Layout.fillWidth: true
                Label { text: formatTime(seekSlider.value); font.pixelSize: 12; opacity: 0.5; color: NemacUI.Theme.textColor }
                Item { Layout.fillWidth: true }
                Label { text: formatTime(seekSlider.to); font.pixelSize: 12; opacity: 0.5; color: NemacUI.Theme.textColor }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 10
            spacing: 45

            IconButton {
                implicitWidth: 42; implicitHeight: 42
                source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/media-skip-backward-symbolic.svg"
                onLeftButtonClicked: mprisManager.previous()
            }

            Rectangle {
                id: playBtn
                width: 76; height: 76
                radius: 38
                color: NemacUI.Theme.highlightColor
                
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 16; samples: 32; verticalOffset: 6
                    color: Qt.rgba(NemacUI.Theme.highlightColor.r, 
                                   NemacUI.Theme.highlightColor.g, 
                                   NemacUI.Theme.highlightColor.b, 0.5) 
                }

                Image {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: control.isPlaying ? 0 : 3
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
                implicitWidth: 42; implicitHeight: 42
                source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/media-skip-forward-symbolic.svg"
                onLeftButtonClicked: mprisManager.next()
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
