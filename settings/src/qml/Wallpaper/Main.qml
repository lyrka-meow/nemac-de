/*
 * Copyright (C) 2021 NemacDE Team.
 *
 * Author:     revenmartin <revenmartin@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0
import Nemac.Settings 1.0
import NemacUI 1.0 as NemacUI

import "../"

ItemPage {
    headerTitle: qsTr("Background")

    Background {
        id: background
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: NemacUI.Units.largeSpacing

            RoundedItem {
                RowLayout {
                    spacing: NemacUI.Units.largeSpacing * 2

                    Label {
                        text: qsTr("Background type")
                        leftPadding: NemacUI.Units.smallSpacing
                    }

                    TabBar {
                        Layout.fillWidth: true

                        onCurrentIndexChanged: {
                            background.backgroundType = currentIndex
                        }

                        Component.onCompleted: {
                            currentIndex = background.backgroundType
                        }

                        TabButton {
                            text: qsTr("Picture")
                        }

                        TabButton {
                            text: qsTr("Color")
                        }
                    }
                }

                GridView {
                    id: _view

                    property int rowCount: _view.width / itemWidth

                    Layout.fillWidth: true
                    implicitHeight: Math.ceil(_view.count / rowCount) * cellHeight + NemacUI.Units.largeSpacing

                    visible: background.backgroundType === 0

                    clip: true
                    model: background.backgrounds
                    currentIndex: -1
                    interactive: false

                    cellHeight: itemHeight
                    cellWidth: calcExtraSpacing(itemWidth, _view.width) + itemWidth

                    property int itemWidth: 180
                    property int itemHeight: 127

                    delegate: Item {
                        id: item

                        property bool isSelected: modelData === background.currentBackgroundPath

                        width: GridView.view.cellWidth
                        height: GridView.view.cellHeight
                        scale: 1.0

                        Behavior on scale {
                            NumberAnimation {
                                duration: 200
                                easing.type: Easing.OutSine
                            }
                        }

                        // Preload background
                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: NemacUI.Units.largeSpacing
                            radius: NemacUI.Theme.bigRadius + NemacUI.Units.smallSpacing / 2
                            color: NemacUI.Theme.backgroundColor
                            visible: _image.status !== Image.Ready
                        }

                        // Preload image
                        Image {
                            anchors.centerIn: parent
                            width: 32
                            height: width
                            sourceSize: Qt.size(width, height)
                            source: NemacUI.Theme.darkMode ? "qrc:/images/dark/picture.svg"
                                                          : "qrc:/images/light/picture.svg"
                            visible: _image.status !== Image.Ready
                        }

                        Rectangle {
                            anchors.fill: parent
                            anchors.margins: NemacUI.Units.smallSpacing
                            color: "transparent"
                            radius: NemacUI.Theme.bigRadius + NemacUI.Units.smallSpacing / 2

                            border.color: NemacUI.Theme.highlightColor
                            border.width: _image.status == Image.Ready & isSelected ? 3 : 0

                            Image {
                                id: _image
                                anchors.fill: parent
                                anchors.margins: NemacUI.Units.smallSpacing
                                source: "file://" + modelData
                                sourceSize: Qt.size(width, height)
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                mipmap: true
                                cache: true
                                smooth: true
                                opacity: 1.0

                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 100
                                        easing.type: Easing.InOutCubic
                                    }
                                }

                                layer.enabled: true
                                layer.effect: OpacityMask {
                                    maskSource: Item {
                                        width: _image.width
                                        height: _image.height

                                        Rectangle {
                                            anchors.fill: parent
                                            radius: NemacUI.Theme.bigRadius
                                        }
                                    }
                                }
                            }

                            MouseArea {
                                anchors.fill: parent
                                acceptedButtons: Qt.LeftButton
                                hoverEnabled: true

                                onClicked: {
                                    background.setBackground(modelData)
                                }

                                onEntered: function() {
                                    _image.opacity = 0.7
                                }
                                onExited: function() {
                                    _image.opacity = 1.0
                                }

                                onPressedChanged: item.scale = pressed ? 0.97 : 1.0
                            }
                        }
                    }

                    function calcExtraSpacing(cellSize, containerSize) {
                        var availableColumns = Math.floor(containerSize / cellSize)
                        var extraSpacing = 0
                        if (availableColumns > 0) {
                            var allColumnSize = availableColumns * cellSize
                            var extraSpace = Math.max(containerSize - allColumnSize, 0)
                            extraSpacing = extraSpace / availableColumns
                        }
                        return Math.floor(extraSpacing)
                    }
                }

                Item {
                    visible: background.backgroundType === 1
                    height: NemacUI.Units.smallSpacing
                }

                Loader {
                    Layout.fillWidth: true
                    height: item.height
                    visible: background.backgroundType === 1
                    sourceComponent: colorView
                }
            }

//            DesktopPreview {
//                Layout.alignment: Qt.AlignHCenter
//                width: 500
//                height: 300
//            }

            Item {
                height: NemacUI.Units.largeSpacing
            }
        }
    }

    Component {
        id: colorView

        GridView {
            id: _colorView
            Layout.fillWidth: true

            property int rowCount: _colorView.width / cellWidth

            implicitHeight: Math.ceil(_colorView.count / _colorView.rowCount) * cellHeight + NemacUI.Units.largeSpacing

            cellWidth: 50
            cellHeight: 50

            interactive: false
            model: ListModel {}

            property var itemSize: 32

            Component.onCompleted: {
                model.append({"bgColor": "#2B8ADA"})
                model.append({"bgColor": "#4DA4ED"})
                model.append({"bgColor": "#B7E786"})
                model.append({"bgColor": "#F2BB73"})
                model.append({"bgColor": "#EE72EB"})
                model.append({"bgColor": "#F0905A"})
                model.append({"bgColor": "#595959"})
                model.append({"bgColor": "#000000"})
            }

            delegate: Rectangle {
                property bool checked: Qt.colorEqual(background.backgroundColor, bgColor)
                property color currentColor: bgColor

                width: _colorView.itemSize + NemacUI.Units.largeSpacing
                height: width
                color: "transparent"
                radius: width / 2
                border.color: _mouseArea.pressed ? Qt.rgba(currentColor.r,
                                                           currentColor.g,
                                                           currentColor.b, 0.6)
                                                 : Qt.rgba(currentColor.r,
                                                           currentColor.g,
                                                           currentColor.b, 0.4)
                border.width: checked ? 3 : _mouseArea.containsMouse ? 2 : 0

                MouseArea {
                    id: _mouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: background.backgroundColor = bgColor
                }

                Rectangle {
                    width: 32
                    height: width
                    anchors.centerIn: parent
                    color: currentColor
                    radius: width / 2
                }
            }
        }
    }
}
