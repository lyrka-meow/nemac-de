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
        color: NemacUI.Theme.darkMode ? "#121212" : "#FFFFFF"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.08)
        
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
            opacity: 0.5
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
                GradientStop { position: 0.0; color: Qt.rgba(0,0,0, 0.4) }
                GradientStop { position: 0.6; color: Qt.rgba(0,0,0, 0.7) }
                GradientStop { position: 1.0; color: NemacUI.Theme.darkMode ? "#121212" : "#f5f5f5" }
            }
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: contentMargin
        spacing: 14

        Item {
            id: discSection
            Layout.alignment: Qt.AlignHCenter
            Layout.topMargin: 8
            width: 200; height: 200

            DropShadow {
                anchors.fill: discRotationContainer
                horizontalOffset: 0
                verticalOffset: 0
                radius: 30
                samples: 40
                color: Qt.rgba(NemacUI.Theme.highlightColor.r, 
                               NemacUI.Theme.highlightColor.g, 
                               NemacUI.Theme.highlightColor.b, 0.5)
                source: discRotationContainer
                visible: control.isPlaying
            }

            Item {
                id: discRotationContainer
                anchors.fill: parent

                RotationAnimation on rotation {
                    id: discAnimation
                    from: 0; to: 360; duration: 25000
                    loops: Animation.Infinite
                    running: control.isPlaying
                }

                Rectangle {
                    id: discImgContainer
                    anchors.fill: parent
                    radius: 100
                    color: "#080808"
                    clip: true
                    border.width: 1
                    border.color: Qt.rgba(1, 1, 1, 0.1)

                    Image {
                        id: albumArt
                        anchors.fill: parent
                        source: control.artUrl ? control.artUrl : "qrc:/images/media-cover.svg"
                        fillMode: Image.PreserveAspectCrop
                        opacity: 0.95
                        
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: 200; height: 200; radius: 100 }
                        }
                    }

                    Rectangle {
                        anchors.centerIn: parent
                        width: 34; height: 34
                        radius: 17
                        color: "#000000"
                        
                        Rectangle {
                            anchors.centerIn: parent
                            width: 10; height: 10
                            radius: 5
                            color: "#1a1a1a"
                        }
                    }
                }
            }
        }

        Column {
            Layout.fillWidth: true
            Layout.topMargin: 4
            spacing: 4
            Label {
                text: control.title || "No Media"
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 24
                font.weight: Font.Bold
                color: "#FFFFFF"
                elide: Text.ElideRight
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
                    color: Qt.rgba(1, 1, 1, 0.1)

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
                Label { text: formatTime(seekSlider.value); font.pixelSize: 11; opacity: 0.5; color: "#FFFFFF" }
                Item { Layout.fillWidth: true }
                Label { text: formatTime(seekSlider.to); font.pixelSize: 11; opacity: 0.5; color: "#FFFFFF" }
            }
        }

        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            Layout.bottomMargin: 4
            spacing: 45

            IconButton {
                implicitWidth: 36; implicitHeight: 36
                source: "qrc:/images/dark/media-skip-backward-symbolic.svg"
                opacity: mouseArea_back.containsMouse ? 1.0 : 0.7
                onLeftButtonClicked: mprisManager.previous()
                MouseArea { id: mouseArea_back; anchors.fill: parent; hoverEnabled: true; onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0 }
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }

            Rectangle {
                id: playBtn
                width: 72; height: 72
                radius: 36
                color: NemacUI.Theme.highlightColor
                
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 20; samples: 30; verticalOffset: 6
                    color: Qt.rgba(NemacUI.Theme.highlightColor.r, 
                                   NemacUI.Theme.highlightColor.g, 
                                   NemacUI.Theme.highlightColor.b, 0.45) 
                }

                Image {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: control.isPlaying ? 0 : 3
                    width: 30; height: 30
                    source: control.isPlaying ? "qrc:/images/dark/media-playback-pause-symbolic.svg" 
                                              : "qrc:/images/dark/media-playback-start-symbolic.svg"
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: mprisManager.playPause()
                    onPressed: playBtn.scale = 0.88
                    onReleased: playBtn.scale = 1.05
                    onEntered: playBtn.scale = 1.05
                    onExited: playBtn.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }
            }

            IconButton {
                implicitWidth: 36; implicitHeight: 36
                source: "qrc:/images/dark/media-skip-forward-symbolic.svg"
                opacity: mouseArea_next.containsMouse ? 1.0 : 0.7
                onLeftButtonClicked: mprisManager.next()
                MouseArea { id: mouseArea_next; anchors.fill: parent; hoverEnabled: true; onEntered: parent.scale = 1.1; onExited: parent.scale = 1.0 }
                Behavior on opacity { NumberAnimation { duration: 200 } }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
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
