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

import QtQuick 2.4
import QtQuick.Controls 2.4
import QtQuick.Layouts 1.3
import QtGraphicalEffects 1.0
import NemacUI 1.0 as NemacUI
import Nemac.Settings 1.0
import Nemac.NetworkManagement 1.0 as NM

Item {
    implicitWidth: 230

    property int itemRadiusV: 8

    property alias view: listView
    property alias model: listModel
    property alias currentIndex: listView.currentIndex

    Rectangle {
        anchors.fill: parent
        color: NemacUI.Theme.darkMode ? Qt.lighter(NemacUI.Theme.backgroundColor, 1.5)
                                     : Qt.darker(NemacUI.Theme.backgroundColor, 1.05)
        opacity: rootWindow.compositing ? 0.7 : 1.0

        Behavior on color {
            ColorAnimation {
                duration: 250
                easing.type: Easing.Linear
            }
        }
    }

    ListModel {
        id: listModel

        ListElement {
            title: qsTr("WLAN")
            name: "wlan"
            page: "qrc:/qml/WLAN/Main.qml"
            iconSource: "wlan.svg"
            iconColor: "#0067FF"
            category: qsTr("Network and connection")
        }

        ListElement {
            title: qsTr("Ethernet")
            name: "ethernet"
            page: "qrc:/qml/Wired/Main.qml"
            iconSource: "network.svg"
            iconColor: "#0067FF"
            category: qsTr("Network and connection")
        }

//        ListElement {
//            title: qsTr("Hotspot")
//            name: "hotspot"
//            page: "qrc:/qml/Hotspot/Main.qml"
//            iconSource: "hotspot.svg"
//            iconColor: "#0067FF"
//            category: qsTr("Network and connection")
//        }

        ListElement {
            title: qsTr("Bluetooth")
            name: "bluetooth"
            page: "qrc:/qml/Bluetooth/Main.qml"
            iconSource: "bluetooth.svg"
            iconColor: "#0067FF"
            category: qsTr("Network and connection")
        }

//        ListElement {
//            title: qsTr("VPN")
//            name: "vpn"
//            page: "qrc:/qml/VPN/Main.qml"
//            iconSource: "bluetooth.svg"
//            iconColor: "#0067FF"
//            category: qsTr("Network and connection")
//        }

        ListElement {
            title: qsTr("Proxy")
            name: "proxy"
            page: "qrc:/qml/Proxy/Main.qml"
            iconSource: "proxy.svg"
            iconColor: "#0067FF"
            category: qsTr("Network and connection")
        }

        ListElement {
            title: qsTr("Display")
            name: "display"
            page: "qrc:/qml/Display/Main.qml"
            iconSource: "display.svg"
            iconColor: "#0087ED"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Appearance")
            name: "appearance"
            page: "qrc:/qml/Appearance/Main.qml"
            iconSource: "appearance.svg"
            iconColor: "#03B4CB"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Fonts")
            name: "fonts"
            page: "qrc:/qml/Fonts/Main.qml"
            iconSource: "fonts.svg"
            iconColor: "#FFBF36"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Background")
            name: "background"
            page: "qrc:/qml/Wallpaper/Main.qml"
            iconSource: "wallpaper.svg"
            iconColor: "#34B4A7"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("Dock")
            name: "dock"
            page: "qrc:/qml/Dock/Main.qml"
            iconSource: "dock.svg"
            iconColor: "#8585FC"
            category: qsTr("Display and appearance")
        }

        ListElement {
            title: qsTr("User")
            name: "accounts"
            page: "qrc:/qml/User/Main.qml"
            iconSource: "accounts.svg"
            iconColor: "#DA7C43"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Notifications")
            name: "notifications"
            page: "qrc:/qml/Notification/Main.qml"
            iconSource: "notifications.svg"
            iconColor: "#F16884"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Sound")
            name: "sound"
            page: "qrc:/qml/Sound/Main.qml"
            iconSource: "sound.svg"
            iconColor: "#F16884"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Mouse")
            name: "mouse"
            page: "qrc:/qml/Cursor/Main.qml"
            iconSource: "cursor.svg"
            iconColor: "#3385FF"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Touchpad")
            name: "touchpad"
            page: "qrc:/qml/Touchpad/Main.qml"
            iconSource: "touchpad.svg"
            iconColor: "#999999"
            category: qsTr("System")
        }

//        ListElement {
//            title: qsTr("Application")
//            name: "application"
//            page: "qrc:/qml/Application/Main.qml"
//            iconSource: "accounts.svg"
//            iconColor: "#DA7C43"
//            category: qsTr("System")
//        }

        ListElement {
            title: qsTr("Date & Time")
            name: "datetime"
            page: "qrc:/qml/DateTime/Main.qml"
            iconSource: "datetime.svg"
            iconColor: "#418CFF"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Default Applications")
            name: "datetime"
            page: "qrc:/qml/DefaultApp/Main.qml"
            iconSource: "defaultapps.svg"
            iconColor: "#418CFF"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Language")
            name: "language"
            page: "qrc:/qml/LanguagePage.qml"
            iconSource: "language.svg"
            iconColor: "#20A7FF"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Battery")
            name: "battery"
            page: "qrc:/qml/Battery/Main.qml"
            iconSource: "battery.svg"
            iconColor: "#2EC347"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("Power")
            name: "power"
            page: "qrc:/qml/Power/Main.qml"
            iconColor: "#FE8433"
            iconSource: "power.svg"
            category: qsTr("System")
        }

        ListElement {
            title: qsTr("About")
            name: "about"
            page: "qrc:/qml/About/Main.qml"
            iconSource: "about.svg"
            iconColor: "#24A7FD"
            category: qsTr("System")
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 0
        spacing: 0

        Label {
            text: rootWindow.title
            color: rootWindow.active ? NemacUI.Theme.textColor : NemacUI.Theme.disabledTextColor
            Layout.preferredHeight: rootWindow.header.height
            leftPadding: NemacUI.Units.largeSpacing + NemacUI.Units.smallSpacing
            rightPadding: NemacUI.Units.largeSpacing + NemacUI.Units.smallSpacing
            topPadding: NemacUI.Units.smallSpacing
            bottomPadding: 0
            font.pointSize: 13
        }

        ListView {
            id: listView
            Layout.fillHeight: true
            Layout.fillWidth: true
            clip: true
            model: listModel

            spacing: NemacUI.Units.smallSpacing
            leftMargin: NemacUI.Units.largeSpacing
            rightMargin: NemacUI.Units.largeSpacing
            topMargin: 0
            bottomMargin: NemacUI.Units.largeSpacing

            ScrollBar.vertical: ScrollBar {}

            highlightFollowsCurrentItem: true
            highlightMoveDuration: 0
            highlightResizeDuration : 0
            highlight: Rectangle {
                radius: NemacUI.Theme.mediumRadius
                color: Qt.rgba(NemacUI.Theme.textColor.r,
                               NemacUI.Theme.textColor.g,
                               NemacUI.Theme.textColor.b, 0.05)
                smooth: true
            }

            section.property: "category"
            section.delegate: Item {
                width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                height: NemacUI.Units.fontMetrics.height + NemacUI.Units.largeSpacing + NemacUI.Units.smallSpacing

                Text {
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.leftMargin: Qt.application.layoutDirection === Qt.RightToLeft ? 0 : NemacUI.Units.smallSpacing
                    anchors.rightMargin: NemacUI.Units.smallSpacing
                    anchors.topMargin: NemacUI.Units.largeSpacing
                    anchors.bottomMargin: NemacUI.Units.smallSpacing
                    color: NemacUI.Theme.disabledTextColor
                    font.pointSize: 8
                    text: section
                }
            }

            NemacUI.WheelHandler {
                target: listView
            }

            delegate: Item {
                id: item
                width: ListView.view.width - ListView.view.leftMargin - ListView.view.rightMargin
                height: 35

                property bool isCurrent: listView.currentIndex === index

                Rectangle {
                    anchors.fill: parent

                    MouseArea {
                        id: mouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        onClicked: listView.currentIndex = index
                    }

                    radius: NemacUI.Theme.mediumRadius
                    color: mouseArea.pressed ? Qt.rgba(NemacUI.Theme.textColor.r,
                                                       NemacUI.Theme.textColor.g,
                                                       NemacUI.Theme.textColor.b, NemacUI.Theme.darkMode ? 0.05 : 0.1) :
                           mouseArea.containsMouse || isCurrent ? Qt.rgba(NemacUI.Theme.textColor.r,
                                                                          NemacUI.Theme.textColor.g,
                                                                          NemacUI.Theme.textColor.b, NemacUI.Theme.darkMode ? 0.1 : 0.05) :
                                                                  "transparent"

                    smooth: true
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: NemacUI.Units.smallSpacing
                    spacing: NemacUI.Units.smallSpacing

                    Rectangle {
                        id: iconRect
                        width: 24
                        height: 24
                        Layout.alignment: Qt.AlignVCenter
                        radius: 6
                        color: model.iconColor

                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Qt.lighter(model.iconColor, 1.15) }
                            GradientStop { position: 1.0; color: model.iconColor }
                        }

                        Image {
                            id: icon
                            anchors.centerIn: parent
                            width: 16
                            height: width
                            source: "qrc:/images/sidebar/dark/" + model.iconSource
                            sourceSize: Qt.size(width, height)
                            Layout.alignment: Qt.AlignVCenter
                            antialiasing: false
                            smooth: false
                        }
                    }

                    Label {
                        id: itemTitle
                        text: model.title
                        color: NemacUI.Theme.darkMode ? NemacUI.Theme.textColor : "#363636"
                        font.pointSize: 8
                    }

                    Item {
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }

    function removeItem(name) {
        for (var i = 0; i < listModel.count; ++i) {
            if (name === listModel.get(i).name) {
                listModel.remove(i)
                break
            }
        }
    }

    Battery {
        id: _battery

        Component.onCompleted: {
            if (!_battery.available)
                removeItem("battery")
        }
    }

    NM.EnabledConnections {
        id: nmEnabledConnections

        Component.onCompleted: {
            if (!nmEnabledConnections.wirelessHwEnabled)
                removeItem("wlan")
        }
    }

    Touchpad {
        id: _touchPad

        Component.onCompleted: {
            if (!_touchPad.available)
                removeItem("touchpad")
        }
    }
}
