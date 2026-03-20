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

import NemacUI 1.0 as NemacUI
import Nemac.Settings 1.0 as Settings

ItemPage {
    headerTitle: qsTr("Language")

    Settings.Language {
        id: language
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.topMargin: NemacUI.Units.smallSpacing

        ListView {
            id: listView

            NemacUI.WheelHandler {
                target: listView
            }

            Layout.fillWidth: true
            Layout.fillHeight: true

            model: language.languages
            clip: true

            topMargin: NemacUI.Units.largeSpacing
            leftMargin: NemacUI.Units.largeSpacing * 2
            rightMargin: NemacUI.Units.largeSpacing * 2
            bottomMargin: NemacUI.Units.largeSpacing
            spacing: NemacUI.Units.largeSpacing

            currentIndex: language.currentLanguage

            ScrollBar.vertical: ScrollBar {
                bottomPadding: NemacUI.Theme.smallRadius
            }

            highlightFollowsCurrentItem: true
            highlightMoveDuration: 0
            highlightResizeDuration : 0
            highlight: Rectangle {
                color: NemacUI.Theme.highlightColor
                radius: NemacUI.Theme.smallRadius
            }

            delegate: MouseArea {
                property bool isSelected: index == listView.currentIndex

                id: item
                width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                height: 36
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton

                onClicked: {
                    language.setCurrentLanguage(index)
                }

                Rectangle {
                    anchors.fill: parent
                    color: isSelected ? "transparent" : item.containsMouse ? NemacUI.Theme.disabledTextColor : "transparent"
                    opacity: isSelected ? 1 : 0.1
                    radius: NemacUI.Theme.smallRadius
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: NemacUI.Units.smallSpacing
                    anchors.rightMargin: NemacUI.Units.largeSpacing

                    Label {
                        color: isSelected ? NemacUI.Theme.highlightedTextColor : NemacUI.Theme.textColor
                        text: modelData
                        Layout.alignment: Qt.AlignVCenter
                    }

                    Item {
                        Layout.fillWidth: true
                    }

                    Image {
                        width: item.height * 0.45
                        height: width
                        sourceSize: Qt.size(width, height)
                        source: "qrc:/images/dark/checked.svg"
                        visible: isSelected
                        smooth: false
                    }
                }
            }
        }
    }
}
