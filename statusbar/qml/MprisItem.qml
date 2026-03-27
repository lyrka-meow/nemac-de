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
    implicitHeight: visible ? (mainColumn.implicitHeight + contentMargin * 2) : 0
    
    // Данные MPRIS
    property bool isPlaying: mprisManager.playbackStatus === Mpris.Playing
    property var metadata: mprisManager.metadata
    property string artUrl: metadata[Mpris.metadataToString(Mpris.ArtUrl)] || ""
    property string title: metadata[Mpris.metadataToString(Mpris.Title)] || "No Media Playing"
    property string artist: metadata[Mpris.metadataToString(Mpris.Artist)] || "Unknown Artist"
    
    property real trackLengthUs: {
        let len = metadata[Mpris.metadataToString(Mpris.Length)]
        return len > 0 ? Number(len) : 1
    }

    MprisManager {
        id: mprisManager
        onMetadataChanged: control.visible = (title !== "" || artist !== "")
    }

    // Постоянное обновление позиции (чтобы прогресс не стоял на месте)
    Timer {
        interval: 500
        running: control.visible && control.isPlaying
        repeat: true
        onTriggered: seekSlider.value = mprisManager.position
    }

    // --- ФОНОВАЯ ПАНЕЛЬ (Liquid Glass) ---
    Rectangle {
        id: panelBg
        anchors.fill: parent
        radius: 24
        color: NemacUI.Theme.darkMode ? Qt.rgba(0.1, 0.1, 0.12, 0.7) : Qt.rgba(1, 1, 1, 0.6)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.1)

        // Мягкое свечение снизу (эффект глубины)
        LinearGradient {
            anchors.fill: parent
            opacity: 0.3
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
        spacing: 15

        // --- БЛОК 1: ОБЛОЖКА ---
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 180; height: 180

            // Тень под обложкой
            DropShadow {
                anchors.fill: coverContainer
                radius: 20
                samples: 25
                color: Qt.rgba(0, 0, 0, 0.4)
                source: coverContainer
            }

            Rectangle {
                id: coverContainer
                anchors.fill: parent
                radius: 20
                clip: true
                color: "#222"

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: control.artUrl || "qrc:/images/media-cover.svg"
                    fillMode: Image.PreserveAspectCrop
                    
                    // Плавная анимация смены картинки
                    Behavior on source { 
                        NumberAnimation { duration: 300 } 
                    }
                }
            }
        }

        // --- БЛОК 2: ТЕКСТ (Центрирование и Иерархия) ---
        Column {
            Layout.fillWidth: true
            spacing: 4
            Label {
                text: control.title
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 20
                font.weight: Font.DemiBold
                color: NemacUI.Theme.textColor
                elide: Text.ElideRight
            }
            Label {
                text: control.artist
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 14
                opacity: 0.6
                color: NemacUI.Theme.textColor
                elide: Text.ElideRight
            }
        }

        // --- БЛОК 3: PROGRESS BAR (Liquid Style) ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 5

            Slider {
                id: seekSlider
                Layout.fillWidth: true
                from: 0
                to: control.trackLengthUs
                value: mprisManager.position

                background: Rectangle {
                    x: seekSlider.leftPadding
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 8 // Толще для стиля Liquid
                    width: seekSlider.availableWidth
                    height: implicitHeight
                    radius: 4
                    color: Qt.rgba(NemacUI.Theme.textColor.r, NemacUI.Theme.textColor.g, NemacUI.Theme.textColor.b, 0.1)

                    Rectangle {
                        width: seekSlider.visualPosition * parent.width
                        height: parent.height
                        radius: 4
                        color: NemacUI.Theme.highlightColor
                        
                        // Свечение активной части
                        layer.enabled: true
                        layer.effect: Glow {
                            radius: 8
                            samples: 15
                            color: NemacUI.Theme.highlightColor
                            spread: 0.2
                        }
                    }
                }

                handle: Rectangle {
                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitWidth: 16
                    implicitHeight: 16
                    radius: 8
                    color: "white"
                    border.color: NemacUI.Theme.highlightColor
                    border.width: 3
                    visible: seekSlider.hovered || seekSlider.pressed
                }

                onMoved: mprisManager.setPosition(Math.round(value))
            }

            // Тайминги
            RowLayout {
                Layout.fillWidth: true
                Label { 
                    text: formatTime(seekSlider.value)
                    font.pixelSize: 11; opacity: 0.5; color: NemacUI.Theme.textColor 
                }
                Item { Layout.fillWidth: true }
                Label { 
                    text: formatTime(control.trackLengthUs)
                    font.pixelSize: 11; opacity: 0.5; color: NemacUI.Theme.textColor 
                }
            }
        }

        // --- БЛОК 4: УПРАВЛЕНИЕ ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: 30

            IconButton {
                implicitWidth: 36; implicitHeight: 36
                source: "qrc:/images/dark/media-skip-backward-symbolic.svg"
                onLeftButtonClicked: mprisManager.previous()
            }

            // Play/Pause - Главная кнопка
            Rectangle {
                width: 58; height: 58
                radius: 29
                color: NemacUI.Theme.highlightColor
                
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 12; samples: 20; verticalOffset: 4
                    color: Qt.rgba(NemacUI.Theme.highlightColor.r, 0, 0, 0.3)
                }

                Image {
                    anchors.centerIn: parent
                    width: 26; height: 26
                    source: control.isPlaying ? "qrc:/images/dark/media-playback-pause-symbolic.svg" 
                                              : "qrc:/images/dark/media-playback-start-symbolic.svg"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mprisManager.playPause()
                    onPressed: parent.scale = 0.9
                    onReleased: parent.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 100 } }
            }

            IconButton {
                implicitWidth: 36; implicitHeight: 36
                source: "qrc:/images/dark/media-skip-forward-symbolic.svg"
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
