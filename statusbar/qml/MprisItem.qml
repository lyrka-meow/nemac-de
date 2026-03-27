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
    implicitHeight: visible ? (mainColumn.implicitHeight + contentMargin * 2) : 0
    
    property bool isPlaying: mprisManager.playbackStatus === Mpris.Playing
    
    // Реактивные свойства для метаданных
    property string artUrl: ""
    property string title: ""
    property string artist: ""

    MprisManager {
        id: mprisManager
        
        // Слушаем изменения метаданных напрямую (фикс обложки)
        onMetadataChanged: {
            var meta = mprisManager.metadata
            var newArt = meta[Mpris.metadataToString(Mpris.ArtUrl)] || ""
            var newTitle = meta[Mpris.metadataToString(Mpris.Title)] || ""
            var newArtist = meta[Mpris.metadataToString(Mpris.Artist)] || ""
            
            // Если данные изменились - обновляем
            control.artUrl = newArt
            control.title = newTitle
            control.artist = newArtist
            
            control.visible = (newTitle !== "" || newArtist !== "")
        }
    }

    // Таймер прогресса (фикс отображения)
    Timer {
        interval: 500
        running: control.visible && control.isPlaying
        repeat: true
        onTriggered: {
            if (!seekSlider.pressed)
                seekSlider.value = mprisManager.position
        }
    }

    // --- ФОН Liquid Glass ---
    Rectangle {
        id: panelBg
        anchors.fill: parent
        radius: 28
        color: NemacUI.Theme.darkMode ? Qt.rgba(0.08, 0.08, 0.1, 0.75) : Qt.rgba(1, 1, 1, 0.65)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.15)

        // Динамический градиент (теперь полностью системный цвет)
        LinearGradient {
            anchors.fill: parent
            opacity: 0.25
            source: parent
            start: Qt.point(0, 0)
            end: Qt.point(0, parent.height)
            gradient: Gradient {
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 1.0; color: NemacUI.Theme.highlightColor }
            }
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: contentMargin
        spacing: 18

        // --- ОБЛОЖКА ---
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 190; height: 190

            DropShadow {
                anchors.fill: coverContainer
                radius: 18
                samples: 25
                color: Qt.rgba(0, 0, 0, 0.45)
                source: coverContainer
            }

            Rectangle {
                id: coverContainer
                anchors.fill: parent
                radius: 22
                clip: true
                color: "#1a1a1a"

                Image {
                    id: albumArt
                    anchors.fill: parent
                    // Добавляем проверку на пустую строку и "image://" префиксы
                    source: control.artUrl ? (control.artUrl.indexOf("file://") === 0 ? control.artUrl : control.artUrl) : "qrc:/images/media-cover.svg"
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    
                    // Плавная смена (фикс визуального бага)
                    Behavior on source { 
                        SequentialAnimation {
                            NumberAnimation { target: albumArt; property: "opacity"; to: 0.5; duration: 100 }
                            PropertyAction { target: albumArt; property: "opacity"; value: 1.0 }
                        }
                    }
                }
            }
        }

        // --- ТЕКСТ ---
        Column {
            Layout.fillWidth: true
            spacing: 4
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
                font.pixelSize: 15
                opacity: 0.7
                color: NemacUI.Theme.textColor
                elide: Text.ElideRight
            }
        }

        // --- ПРОГРЕСС (Liquid) ---
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
                    implicitHeight: 8
                    width: seekSlider.availableWidth
                    height: implicitHeight
                    radius: 4
                    color: Qt.rgba(NemacUI.Theme.textColor.r, NemacUI.Theme.textColor.g, NemacUI.Theme.textColor.b, 0.1)

                    Rectangle {
                        width: seekSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 4
                        color: NemacUI.Theme.highlightColor
                        
                        layer.enabled: true
                        layer.effect: Glow {
                            radius: 6; samples: 12
                            color: NemacUI.Theme.highlightColor
                        }
                    }
                }

                handle: Rectangle {
                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitWidth: 16; implicitHeight: 16; radius: 8
                    color: "white"
                    border.color: NemacUI.Theme.highlightColor
                    border.width: 3
                    scale: seekSlider.pressed ? 1.2 : 1.0
                    Behavior on scale { NumberAnimation { duration: 100 } }
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

        // --- КНОПКИ УПРАВЛЕНИЯ ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 40

            IconButton {
                implicitWidth: 38; implicitHeight: 38
                source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/media-skip-backward-symbolic.svg"
                onLeftButtonClicked: mprisManager.previous()
            }

            // Кнопка Play/Pause (ФИКС ТЕНИ)
            Rectangle {
                id: playBtn
                width: 64; height: 64
                radius: 32
                color: NemacUI.Theme.highlightColor
                
                // Тень теперь использует правильный системный цвет (rgba фикс)
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 14; samples: 25; verticalOffset: 5
                    color: Qt.rgba(NemacUI.Theme.highlightColor.r, 
                                   NemacUI.Theme.highlightColor.g, 
                                   NemacUI.Theme.highlightColor.b, 0.4) 
                }

                Image {
                    anchors.centerIn: parent
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
