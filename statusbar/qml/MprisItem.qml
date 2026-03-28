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
        radius: 28
        color: NemacUI.Theme.darkMode ? "#1a1a1a" : "#FFFFFF"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)
        
        layer.enabled: true
        layer.effect: OpacityMask {
            maskSource: Rectangle {
                width: panelBg.width
                height: panelBg.height
                radius: 28
            }
        }

        Image {
            id: bgBlurImage
            anchors.fill: parent
            source: control.artUrl ? control.artUrl : "qrc:/images/media-cover.svg"
            fillMode: Image.PreserveAspectCrop
            opacity: 0.35
            visible: control.artUrl !== ""
        }

        FastBlur {
            anchors.fill: bgBlurImage
            source: bgBlurImage
            radius: 40
        }

        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.7; color: Qt.rgba(0,0,0, 0.2) }
                GradientStop { position: 1.0; color: NemacUI.Theme.darkMode ? "#1a1a1a" : "#f0f0f0" }
            }
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: contentMargin
        spacing: 16

        Item {
            id: discSection
            Layout.alignment: Qt.AlignHCenter
            width: 200; height: 200

            Glow {
                anchors.fill: discRotationContainer
                radius: 25
                samples: 35
                color: Qt.rgba(NemacUI.Theme.highlightColor.r, NemacUI.Theme.highlightColor.g, NemacUI.Theme.highlightColor.b, 0.6)
                source: discRotationContainer
                visible: control.isPlaying
            }

            Item {
                id: discRotationContainer
                anchors.fill: parent

                RotationAnimation on rotation {
                    id: discAnimation
                    from: 0; to: 360; duration: 10000
                    loops: Animation.Infinite
                    running: control.isPlaying
                }

                Rectangle {
                    id: discImgContainer
                    anchors.fill: parent
                    radius: 100
                    color: "#000000"
                    clip: true

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: control.artUrl ? control.artUrl : "qrc:/images/media-cover.svg"
                        fillMode: Image.PreserveAspectCrop
                        
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: 200; height: 200; radius: 100 }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 36; height: 36
                        radius: 18
                        color: "#111111"
                        border.width: 4
                        border.color: "#000000"

                        Rectangle {
                            anchors.centerIn: parent
                            width: 8; height: 8
                            radius: 4
                            color: "#222222"
                        }
                    }
                }
            }
        }

        Column {
            Layout.fillWidth: true
            spacing: 2
            Label {
                text: control.title || "Unknown Track"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 22
                font.weight: Font.Bold
                color: NemacUI.Theme.textColor
                elide: Text.ElideRight
            }
            Label {
                text: control.artist || "Unknown Artist"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                opacity: 0.7
                color: NemacUI.Theme.textColor
                elide: Text.ElideRight
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 4

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
                Label { text: formatTime(seekSlider.value); font.pixelSize: 11; opacity: 0.5; color: NemacUI.Theme.textColor }
                Item { Layout.fillWidth: true }
                Label { text: formatTime(seekSlider.to); font.pixelSize: 11; opacity: 0.5; color: NemacUI.Theme.textColor }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 40

            IconButton {
                implicitWidth: 38; implicitHeight: 38
                source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/media-skip-backward-symbolic.svg"
                onLeftButtonClicked: mprisManager.previous()
            }

            Rectangle {
                id: playBtn
                width: 68; height: 68
                radius: 34
                color: NemacUI.Theme.highlightColor
                
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 14; samples: 25; verticalOffset: 4
                    color: Qt.rgba(NemacUI.Theme.highlightColor.r, 
                                   NemacUI.Theme.highlightColor.g, 
                                   NemacUI.Theme.highlightColor.b, 0.4) 
                }

                Image {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: control.isPlaying ? 0 : 2
                    width: 28; height: 28
                    source: control.isPlaying ? "qrc:/images/dark/media-playback-pause-symbolic.svg" 
                                              : "qrc:/images/dark/media-playback-start-symbolic.svg"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mprisManager.playPause()
                    onPressed: playBtn.scale = 0.92
                    onReleased: playBtn.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }

            IconButton {
                implicitWidth: 38; implicitHeight: 38
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
