import QtQuick 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtGraphicalEffects 1.0

import Nemac.StatusBar 1.0
import NemacUI 1.0 as NemacUI

ListView {
    id: trayView

    // Настройки ориентации
    orientation: Qt.Horizontal
    layoutDirection: Qt.RightToLeft
    interactive: false
    clip: false // Разрешаем свечению/тени выходить за границы
    spacing: NemacUI.Units.smallSpacing / 2

    // Свойства размеров
    property real itemWidth: rootItem.iconSize + NemacUI.Units.largeSpacing
    
    Layout.fillHeight: true
    // Завет 3: Автоматический расчет ширины на основе содержимого
    implicitWidth: contentWidth > 0 ? contentWidth : 0
    Layout.preferredWidth: implicitWidth

    model: SystemTrayModel {
        id: trayModel
    }

    // --- АНИМАЦИИ (Liquid Glass Style) ---
    
    // Плавное перемещение иконок при добавлении/удалении
    moveDisplaced: Transition {
        NumberAnimation {
            properties: "x, y"
            duration: 300
            easing.type: Easing.OutBack // Мягкий "отскок"
        }
    }

    // Появление новой иконки
    add: Transition {
        NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 400 }
        NumberAnimation { property: "scale"; from: 0.3; to: 1; duration: 400; easing.type: Easing.OutBack }
    }

    // Исчезновение иконки
    remove: Transition {
        NumberAnimation { property: "opacity"; to: 0; duration: 200 }
        NumberAnimation { property: "scale"; to: 0; duration: 200 }
    }

    delegate: StandardItem {
        id: _trayItem

        property bool darkMode: rootItem.darkMode
        property int dragItemIndex: index
        property bool dragStarted: false

        width: trayView.itemWidth
        height: trayView.height
        animationEnabled: true

        // Обновление иконки при смене темы
        onDarkModeChanged: updateTimer.restart()

        // --- ЛОГИКА DRAG & DROP ---
        Drag.active: _trayItem.mouseArea.drag.active
        Drag.dragType: Drag.Automatic
        Drag.supportedActions: Qt.MoveAction
        Drag.hotSpot.x: iconContainer.width / 2
        Drag.hotSpot.y: iconContainer.height / 2

        Drag.onDragStarted: dragStarted = true
        Drag.onDragFinished: dragStarted = false

        onPositionChanged: {
            if (_trayItem.mouseArea.pressed) {
                _trayItem.mouseArea.drag.target = iconContainer
                iconContainer.grabToImage(function(result) {
                    _trayItem.Drag.imageSource = result.url
                })
            } else {
                _trayItem.mouseArea.drag.target = null
            }
        }

        onReleased: _trayItem.mouseArea.drag.target = null

        DropArea {
            anchors.fill: parent
            enabled: true
            onEntered: {
                if (drag.source)
                    trayModel.move(drag.source.dragItemIndex, _trayItem.dragItemIndex)
            }
        }

        // --- ВИЗУАЛЬНАЯ ЧАСТЬ ИКОНКИ ---
        Item {
            id: iconContainer
            anchors.fill: parent
            opacity: dragStarted ? 0 : 1

            // Если иконка символическая (нужно перекрасить в цвет текста)
            ColorOverlay {
                id: iconOverlay
                anchors.centerIn: parent
                width: rootItem.iconSize
                height: width
                source: iconItem
                color: rootItem.textColor
                opacity: rootItem.darkMode ? 1 : 0.8
                visible: model.canColorOverlay && iconItem.status === Image.Ready
            }

            // Сама иконка
            NemacUI.IconItem {
                id: iconItem
                anchors.centerIn: parent
                width: rootItem.iconSize
                height: width
                // Завет 3: Проверка на существование имени иконки
                source: model.iconName ? model.iconName : (model.icon ? model.icon : "")
                antialiasing: true
                smooth: true
                // Скрываем, если работает ColorOverlay (чтобы не было дублей)
                visible: !iconOverlay.visible
            }
        }

        // --- ВЗАИМОДЕЙСТВИЕ ---
        onClicked: {
            var pos = trayModel.popupPosition(_trayItem, mouse.x, mouse.y)
            
            // Завет 4: Стандартное поведение кнопок мыши
            if (mouse.button === Qt.LeftButton) {
                trayModel.leftButtonClick(model.id, pos.x, pos.y)
            } else if (mouse.button === Qt.RightButton) {
                trayModel.rightButtonClick(model.id, _trayItem, pos.x, pos.y)
            } else if (mouse.button === Qt.MiddleButton) {
                trayModel.middleButtonClick(model.id, pos.x, pos.y)
            }
        }

        // Тултип (всплывающая подсказка)
        popupText: model.toolTip ? model.toolTip : (model.title ? model.title : "")

        Timer {
            id: updateTimer
            interval: 50
            onTriggered: iconItem.updateIcon()
        }
    }
}
