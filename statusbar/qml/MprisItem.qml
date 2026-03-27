/*
 * Updated MprisItem.qml
 * Focus: Premium UI, Smooth Animations, Dynamic Visuals
 */

import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import NemacUI 1.0 as NemacUI
import Nemac.Mpris 1.0

Item {
    id: control
    clip: true

    readonly property int contentMargin: NemacUI.Units.largeSpacing * 1.5
    implicitHeight: visible ? (mainLayout.implicitHeight + contentMargin * 2) : 0
    
    // Состояния плеера
    property bool available: mprisManager.availableServices.length > 0
    property bool isPlaying: currentService && mprisManager.playbackStatus === Mpris.Playing
    property alias currentService: mprisManager.currentService
    
    // Теги метаданных
    property var metadata: mprisManager.metadata
    property string artUrl: metadata[Mpris.metadataToString(Mpris.ArtUrl)] || ""
    property string title: metadata[Mpris.metadataToString(Mpris.Title)] || "Unknown Title"
    property string artist: metadata[Mpris.metadataToString(Mpris.Artist)] || "Unknown Artist"
    
    property real trackLengthUs: {
        let len = metadata[Mpris.metadataToString(Mpris.Length)]
        return len > 0 ? Number(len) : 1
    }

    MprisManager {
        id: mprisManager
        onMetadataChanged: control.updateVisibility()
    }

    function updateVisibility() {
        control.visible = (title !== "" || artist !== "")
    }

    function formatTime(us) {
        var sec = Math.floor(Number(us) / 1000000)
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    // --- ФОНОВАЯ КАРТОЧКА ---
    Rectangle {
        id: cardBase
        anchors.fill: parent
        radius: NemacUI.Theme.bigRadius
        color: NemacUI.Theme.darkMode ? Qt.rgba(0.15, 0.15, 0.18, 0.8) : Qt.rgba(1, 1, 1, 0.9)
        border.color: Qt.rgba(1, 1, 1, 0.1)
        border.width: 1

        // Размытый фон из обложки (создает эффект глубины)
        Image {
            id: blurredArt
            anchors.fill: parent
            source: control.artUrl
            fillMode: Image.PreserveAspectCrop
            opacity: 0.15
            visible: status === Image.Ready
            layer.enabled: true
            layer.effect: FastBlur {
                radius: 64
                transparentBorder: true
            }
        }
    }

    ColumnLayout {
        id: mainLayout
        anchors.fill: parent
        anchors.margins: contentMargin
        spacing: NemacUI.Units.largeSpacing

        // --- ВЕРХНИЙ БЛОК: ОБЛОЖКА И ИНФО ---
        RowLayout {
            Layout.fillWidth: true
            spacing: NemacUI.Units.largeSpacing * 1.5

            // Обложка с мягкой тенью
            Item {
                width: 100; height: 100
                
                DropShadow {
                    anchors.fill: artContainer
                    horizontalOffset: 0; verticalOffset: 6
                    radius: 12; samples: 25
                    color: Qt.rgba(0, 0, 0, 0.3)
                    source: artContainer
                }

                Rectangle {
                    id: artContainer
                    anchors.fill: parent
                    radius: NemacUI.Theme.smallRadius
                    color: NemacUI.Theme.darkMode ? "#2a2a2e" : "#e8e8ec"

                    Image {
                        id: mainArt
                        anchors.fill: parent
                        source: control.artUrl || "qrc:/images/media-cover.svg"
                        fillMode: Image.PreserveAspectCrop
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle { width: 100; height: 100; radius: 10 }
                        }
                        
                        // Плавная смена обложки
                        Behavior on source { 
                            SequentialAnimation {
                                NumberAnimation { target: mainArt; property: "opacity"; to: 0; duration: 150 }
                                PropertyAction { }
                                NumberAnimation { target: mainArt; property: "opacity"; to: 1; duration: 250 }
                            }
                        }
                    }
                }
            }

            // Текстовый блок
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Label {
                    text: control.title
                    font.pixelSize: 18
                    font.bold: true
                    color: NemacUI.Theme.textColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    wrapMode: Text.WordWrap
                }

                Label {
                    text: control.artist
                    font.pixelSize: 14
                    opacity: 0.7
                    color: NemacUI.Theme.textColor
                    Layout.fillWidth: true
                    elide: Text.ElideRight
                }
            }
        }

        // --- БЛОК ПРОГРЕССА ---
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Slider {
                id: seekSlider
                Layout.fillWidth: true
                from: 0
                to: control.trackLengthUs
                value: mprisManager.position
                
                // Кастомный стиль слайдера (тонкий и изящный)
                background: Rectangle {
                    x: seekSlider.leftPadding
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitWidth: 200
                    implicitHeight: 4
                    width: seekSlider.availableWidth
                    height: implicitHeight
                    radius: 2
                    color: Qt.rgba(NemacUI.Theme.textColor.r, NemacUI.Theme.textColor.g, NemacUI.Theme.textColor.b, 0.1)

                    Rectangle {
                        width: seekSlider.visualPosition * parent.width
                        height: parent.height
                        color: NemacUI.Theme.highlightColor
                        radius: 2
                    }
                }

                handle: Rectangle {
                    x: seekSlider.leftPadding + seekSlider.visualPosition * (seekSlider.availableWidth - width)
                    y: seekSlider.topPadding + seekSlider.availableHeight / 2 - height / 2
                    implicitWidth: 12
                    implicitHeight: 12
                    radius: 6
                    color: "white"
                    border.color: NemacUI.Theme.highlightColor
                    border.width: 2
                    scale: seekSlider.pressed ? 1.3 : (seekSlider.hovered ? 1.1 : 0) // Появляется только при наведении
                    Behavior on scale { NumberAnimation { duration: 150 } }
                }

                onMoved: mprisManager.setPosition(Math.round(value))
            }

            RowLayout {
                Layout.fillWidth: true
                Label {
                    text: formatTime(seekSlider.value)
                    font.pixelSize: 10; opacity: 0.5
                    color: NemacUI.Theme.textColor
                }
                Item { Layout.fillWidth: true }
                Label {
                    text: formatTime(control.trackLengthUs)
                    font.pixelSize: 10; opacity: 0.5
                    color: NemacUI.Theme.textColor
                }
            }
        }

        // --- УПРАВЛЕНИЕ ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: NemacUI.Units.largeSpacing * 2

            IconButton {
                implicitWidth: 32; implicitHeight: 32
                source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/media-skip-backward-symbolic.svg"
                onLeftButtonClicked: mprisManager.previous()
                opacity: mprisManager.canGoPrevious ? 1 : 0.3
            }

            // Центральная кнопка Play/Pause
            Rectangle {
                width: 52; height: 52
                radius: 26
                color: NemacUI.Theme.highlightColor
                
                layer.enabled: true
                layer.effect: DropShadow {
                    radius: 8; samples: 17; color: Qt.rgba(NemacUI.Theme.highlightColor.r, 0, 0, 0.4)
                    verticalOffset: 4
                }

                Image {
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: control.isPlaying ? 0 : 2 // Визуальная центровка иконки Play
                    width: 24; height: 24
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
                implicitWidth: 32; implicitHeight: 32
                source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/media-skip-forward-symbolic.svg"
                onLeftButtonClicked: mprisManager.next()
                opacity: mprisManager.canGoNext ? 1 : 0.3
            }
        }
    }
}
