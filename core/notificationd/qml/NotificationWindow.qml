/*
 * Copyright (C) 2021 NemacDE Team.
 *
 * Author:     Reion Wong <reion@nemacde.com>
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
import QtQml 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12
import QtGraphicalEffects 1.0
import NemacUI 1.0 as NemacUI
import Nemac.Notification 1.0

Item {
    id: control

    visible: true

    Rectangle {
        id: _background
        anchors.fill: parent
        color: NemacUI.Theme.secondBackgroundColor
        radius: NotificationDialog.width * 0.05
        opacity: 0.7

        border.width: 1 / NemacUI.Units.devicePixelRatio
        border.pixelAligned: Screen.devicePixelRatio > 1 ? false : true
        border.color: NemacUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.1)
                                            : Qt.rgba(0, 0, 0, 0.05)
    }

    readonly property rect screenRect: {
        let rect = Qt.rect(screen.screenGeometry.x + screen.availableScreenRect.x,
                           screen.screenGeometry.y + screen.availableScreenRect.y,
                           screen.availableScreenRect.width,
                           screen.availableScreenRect.height)
        return rect
    }

    onScreenRectChanged: {
        NotificationDialog.width = 350
        NotificationDialog.height = screenRect.height - NemacUI.Units.smallSpacing * 3
        NotificationDialog.x = screenRect.x + screenRect.width - NotificationDialog.width - NemacUI.Units.smallSpacing * 1.5
        NotificationDialog.y = screenRect.y + NemacUI.Units.smallSpacing * 1.5
    }

    ScreenHelper {
        id: screen
    }

    NemacUI.WindowHelper {
        id: windowHelper
    }

    NemacUI.WindowShadow {
        view: NotificationDialog
        radius: _background.radius
    }

    NemacUI.WindowBlur {
        view: NotificationDialog
        geometry: Qt.rect(NotificationDialog.x,
                          NotificationDialog.y,
                          NotificationDialog.width,
                          NotificationDialog.height)
        windowRadius: _background.radius
        enabled: true
    }

    NumberAnimation {
        id: scrollToTopAni
        target: _view
        from: 0
        to: 0
        property: "contentY"
        duration: 200
        easing.type: Easing.OutSine
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: NemacUI.Units.largeSpacing
        anchors.bottomMargin: NemacUI.Units.largeSpacing
        spacing: NemacUI.Units.largeSpacing

        RowLayout {
            Layout.leftMargin: NemacUI.Units.largeSpacing
            Layout.rightMargin: NemacUI.Units.largeSpacing

            Label {
                text: qsTr("Notification Center")
                Layout.fillWidth: true
                elide: Text.ElideRight
                leftPadding: NemacUI.Units.smallSpacing
                color: NemacUI.Theme.textColor
                font.pointSize: 15

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if (_view.contentY === 0)
                            return

                        scrollToTopAni.from = _view.contentY
                        scrollToTopAni.to = 0
                        scrollToTopAni.restart()
                    }
                }
            }

            IconButton {
                visible: _view.count > 0
                Layout.preferredHeight: 30
                Layout.preferredWidth: 30
                source: NemacUI.Theme.darkMode ? "qrc:/images/dark/clear.svg"
                                              : "qrc:/images/light/clear.svg"
                onLeftButtonClicked: historyModel.clearAll()
            }
        }

        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true

            ListView {
                id: _view
                anchors.fill: parent
                model: historyModel
                spacing: NemacUI.Units.largeSpacing
                highlightFollowsCurrentItem: true
                clip: true

                leftMargin: NemacUI.Units.largeSpacing
                rightMargin: NemacUI.Units.largeSpacing

                ScrollBar.vertical: ScrollBar {}

                Label {
                    anchors.centerIn: parent
                    text: qsTr("No notifications")
                    color: NemacUI.Theme.disabledTextColor
                    font.pointSize: 15
                    visible: _view.count === 0
                }

                removeDisplaced: Transition {
                    NumberAnimation { properties: "x, y"; duration: 250 }
                }

                delegate: Item {
                    width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                    height: 70

                    Rectangle {
                        anchors.fill: parent
                        color: NemacUI.Theme.darkMode ? "white"
                                                     : "black"
                        radius: NemacUI.Theme.bigRadius
                        opacity: NemacUI.Theme.darkMode ? 0.1
                                                       : 0.03
                    }

                    MouseArea {
                        id: _itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        z: 999
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: NemacUI.Units.largeSpacing
                        anchors.leftMargin: NemacUI.Units.smallSpacing * 1.5
                        anchors.rightMargin: NemacUI.Units.smallSpacing * 1.5
                        spacing: NemacUI.Units.smallSpacing

                        Image {
                            id: _icon
                            width: 48
                            height: width
                            source: model.iconName ? "image://icontheme/%1".arg(model.iconName)
                                                   : ""
                            sourceSize: Qt.size(width, height)
                            Layout.alignment: Qt.AlignVCenter
                            antialiasing: true
                            smooth: true
                            visible: status === Image.Ready
                        }

                        Image {
                            id: _defaultIcon
                            width: 48
                            height: width
                            source: "image://icontheme/preferences-desktop-notification"
                            sourceSize: Qt.size(width, height)
                            Layout.alignment: Qt.AlignVCenter
                            antialiasing: true
                            smooth: true
                            visible: !_icon.visible
                        }

                        ColumnLayout {
                            spacing: 0

                            Item {
                                Layout.fillHeight: true
                            }

                            Label {
                                text: model.summary
                                visible: text
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                rightPadding: NemacUI.Units.smallSpacing
                            }

                            RowLayout {
                                Label {
                                    id: bodyLabel
                                    text: model.body
                                    visible: text
                                    rightPadding: NemacUI.Units.smallSpacing
                                    maximumLineCount: 2
                                    elide: Text.ElideRight
                                    wrapMode: Text.Wrap
                                    Layout.fillWidth: true
                                    // Layout.fillHeight: true
                                    Layout.alignment: Qt.AlignVCenter
                                }

                                Label {
                                    text: model.created
                                    rightPadding: NemacUI.Units.smallSpacing
                                    Layout.alignment: Qt.AlignRight
                                }
                            }

                            Item {
                                Layout.fillHeight: true
                            }
                        }
                    }

                    Image {
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.topMargin: NemacUI.Units.smallSpacing / 2
                        anchors.rightMargin: NemacUI.Units.smallSpacing / 2
                        width: 24
                        height: 24
                        source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/close.svg"
                        sourceSize: Qt.size(width, height)
                        visible: _itemMouseArea.containsMouse
                        z: 9999

                        Rectangle {
                            property color hoveredColor: NemacUI.Theme.darkMode ? Qt.lighter(NemacUI.Theme.backgroundColor, 2)
                                                                               : Qt.darker(NemacUI.Theme.backgroundColor, 1.2)
                            property color pressedColor: NemacUI.Theme.darkMode ? Qt.lighter(NemacUI.Theme.backgroundColor, 1.5)
                                                                               : Qt.darker(NemacUI.Theme.backgroundColor, 1.3)

                            z: -1
                            anchors.fill: parent
                            color: "transparent"
                            radius: height / 2
                        }

                        MouseArea {
                            id: _closeBtnArea
                            anchors.fill: parent
                            // hoverEnabled: true
                            onClicked: {
                                historyModel.remove(index)
                            }
                        }
                    }
                }
            }
        }
    }
}
