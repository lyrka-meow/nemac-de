import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0
import NemacUI 1.0 as NemacUI
import Nemac.Mpris 1.0

Item {
    id: control
    clip: false // Разрешаем свечению выходить за границы

    readonly property int contentMargin: NemacUI.Units.largeSpacing * 2
    implicitHeight: visible ? (mainColumn.implicitHeight + contentMargin * 2) : 0
    
    property bool isPlaying: mprisManager.playbackStatus === Mpris.Playing
    property var metadata: mprisManager.metadata
    property string artUrl: metadata[Mpris.metadataToString(Mpris.ArtUrl)] || ""
    property string title: metadata[Mpris.metadataToString(Mpris.Title)] || "Unknown"
    property string artist: metadata[Mpris.metadataToString(Mpris.Artist)] || "Unknown"
    property real trackLengthUs: {
        let len = metadata[Mpris.metadataToString(Mpris.Length)]
        return len > 0 ? Number(len) : 1
    }

    MprisManager {
        id: mprisManager
        onMetadataChanged: control.visible = (title !== "" || artist !== "")
    }

    // ТАЙМЕР ДЛЯ ПЛАВНОГО ПРОГРЕССА (Завет производительности: 30fps достаточно)
    Timer {
        id: progressUpdater
        interval: 100
        running: control.visible && control.isPlaying
        repeat: true
        onTriggered: {
            if (!seekSlider.pressed) {
                seekSlider.value = mprisManager.position
            }
        }
    }

    // --- ОСНОВНОЙ КОНТЕЙНЕР (Liquid Glass) ---
    Rectangle {
        id: glassBackground
        anchors.fill: parent
        radius: NemacUI.Theme.bigRadius * 1.5
        color: NemacUI.Theme.darkMode ? Qt.rgba(0.05, 0.05, 0.08, 0.6) : Qt.rgba(1, 1, 1, 0.4)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.15)

        // Мягкое внутреннее свечение акцентным цветом
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: "transparent"
            border.width: 2
            border.color: NemacUI.Theme.highlightColor
            opacity: control.isPlaying ? 0.15 : 0.05
            
            Behavior on opacity { NumberAnimation { duration: 1000 } }
        }
    }

    ColumnLayout {
        id: mainColumn
        anchors.fill: parent
        anchors.margins: contentMargin
        spacing: NemacUI.Units.largeSpacing

        // --- БЛОК 1: АНИМИРОВАННАЯ ОБЛОЖКА ---
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: 160; height: 160

            // Пульсирующий ореол (Liquid Aura)
            Rectangle {
                id: aura
                anchors.centerIn: parent
                width: 140; height: 140
                radius: 70
                color: NemacUI.Theme.highlightColor
                opacity: control.isPlaying ? 0.3 : 0.1
                scale: control.isPlaying ? 1.2 : 1.0

                Behavior on scale {
                    NumberAnimation { 
                        duration: 1500; 
                        easing.type: Easing.InOutSine 
                        loops: control.isPlaying ? Animation.Infinite : 1
                    }
                }
                layer.enabled: true
                layer.effect: FastBlur { radius: 48 }
            }

            // Сама обложка в стеклянной рамке
            Rectangle {
                id: artFrame
                anchors.centerIn: parent
                width: 130; height: 130
                radius: 65
                color: "#111"
                clip: true
                border.width: 3
                border.color: Qt.rgba(1, 1, 1, 0.2)

                Image {
                    id: albumArt
                    anchors.fill: parent
                    source: control.artUrl || "qrc:/images/media-cover.svg"
                    fillMode: Image.PreserveAspectCrop
                }

                // Глянец поверх картинки (Liquid Effect)
                Rectangle {
                    anchors.fill: parent
                    radius: 65
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.2) }
                        GradientStop { position: 0.5; color: "transparent" }
                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.2) }
                    }
                }
            }
        }

        // --- БЛОК 2: ТЕКСТ ---
        Column {
            Layout.fillWidth: true
            spacing: 2
            Label {
                text: control.title
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 18; font.bold: true
                color: NemacUI.Theme.textColor
                elide: Text.ElideRight
            }
            Label {
                text: control.artist
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: 13; opacity: 0.6
                color: NemacUI.Theme.textColor
                elide: Text.ElideRight
            }
        }

        // --- БЛОК 3: LIQUID PROGRESS BAR ---
        Item {
            Layout.fillWidth: true
            height: 30

            // Кастомная отрисовка "жидкой" полосы
            Canvas {
                id: liquidWave
                anchors.fill: parent
                antialiasing: true
                
                property real progress: seekSlider.visualPosition
                onProgressChanged: requestPaint()

                onPaint: {
                    var ctx = getContext("2d");
                    ctx.reset();
                    
                    var w = width;
                    var h = height;
                    var midY = h / 2;
                    var fillWidth = w * progress;

                    // 1. Рисуем "подложку" (пустая трасса)
                    ctx.beginPath();
                    ctx.strokeStyle = Qt.rgba(NemacUI.Theme.textColor.r, NemacUI.Theme.textColor.g, NemacUI.Theme.textColor.b, 0.1);
                    ctx.lineWidth = 4;
                    ctx.lineCap = "round";
                    ctx.moveTo(0, midY);
                    ctx.lineTo(w, midY);
                    ctx.stroke();

                    // 2. Рисуем заполнение с эффектом волны на конце
                    if (fillWidth > 0) {
                        ctx.beginPath();
                        ctx.strokeStyle = NemacUI.Theme.highlightColor;
                        ctx.lineWidth = 6;
                        ctx.moveTo(0, midY);
                        
                        // Основная линия
                        ctx.lineTo(fillWidth, midY);
                        ctx.stroke();

                        // "Капля" на конце прогресса
                        ctx.beginPath();
                        ctx.fillStyle = NemacUI.Theme.highlightColor;
                        ctx.ellipse(fillWidth - 6, midY - 6, 12, 12);
                        ctx.fill();
                    }
                }
            }

            Slider {
                id: seekSlider
                anchors.fill: parent
                from: 0
                to: control.trackLengthUs
                opacity: 0 // Скрываем стандартный вид, оставляем только логику мыши
                onMoved: mprisManager.setPosition(Math.round(value))
            }
            
            // Время
            Row {
                anchors.bottom: parent.bottom
                anchors.left: parent.left; anchors.right: parent.right
                Label { 
                    text: formatTime(seekSlider.value)
                    font.pixelSize: 10; opacity: 0.5; color: NemacUI.Theme.textColor 
                }
                Item { width: parent.width - 80 } // Простой спейсер
                Label { 
                    text: formatTime(control.trackLengthUs)
                    font.pixelSize: 10; opacity: 0.5; color: NemacUI.Theme.textColor; horizontalAlignment: Text.AlignRight
                    width: 40
                }
            }
        }

        // --- БЛОК 4: УПРАВЛЕНИЕ ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: NemacUI.Units.largeSpacing * 2

            IconButton {
                source: "qrc:/images/dark/media-skip-backward-symbolic.svg"
                onLeftButtonClicked: mprisManager.previous()
                opacity: mprisManager.canGoPrevious ? 0.8 : 0.2
            }

            // Главная кнопка в стиле Liquid Glass
            Rectangle {
                width: 54; height: 54
                radius: 27
                color: NemacUI.Theme.highlightColor
                
                layer.enabled: true
                layer.effect: DropShadow {
                    transparentBorder: true
                    radius: 12; samples: 20
                    color: Qt.rgba(NemacUI.Theme.highlightColor.r, 0, 0, 0.4)
                }

                Image {
                    anchors.centerIn: parent
                    width: 24; height: 24
                    source: control.isPlaying ? "qrc:/images/dark/media-playback-pause-symbolic.svg" 
                                              : "qrc:/images/dark/media-playback-start-symbolic.svg"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: mprisManager.playPause()
                    onPressed: parent.scale = 0.85
                    onReleased: parent.scale = 1.0
                }
                Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            }

            IconButton {
                source: "qrc:/images/dark/media-skip-forward-symbolic.svg"
                onLeftButtonClicked: mprisManager.next()
                opacity: mprisManager.canGoNext ? 0.8 : 0.2
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
