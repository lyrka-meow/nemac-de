/*
 * Copyright (C) 2021 NemacDE Team.
 *
 * Author:     Reion Wong <aj@nemacde.com>
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
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtGraphicalEffects 1.0

import Nemac.StatusBar 1.0
import Nemac.Audio 1.0
import NemacUI 1.0 as NemacUI

ControlCenterDialog {
    id: control

    width: 420
    height: _mainLayout.implicitHeight + NemacUI.Units.largeSpacing * 2

    property var margin: 4 * Screen.devicePixelRatio
    property point position: Qt.point(0, 0)
    property var defaultSink: paSinkModel.defaultSink

    property var defaultSinkValue: defaultSink ? defaultSink.volume / PulseAudio.NormalVolume * 100.0 : -1

    property var borderColor: windowHelper.compositing ? NemacUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.3)
                                                                  : Qt.rgba(0, 0, 0, 0.2) : NemacUI.Theme.darkMode ? Qt.rgba(255, 255, 255, 0.15)
                                                                                                                  : Qt.rgba(0, 0, 0, 0.15)

    property var volumeIconName: {
        if (defaultSinkValue <= 0)
            return "audio-volume-muted-symbolic"
        else if (defaultSinkValue <= 25)
            return "audio-volume-low-symbolic"
        else if (defaultSinkValue <= 75)
            return "audio-volume-medium-symbolic"
        else
            return "audio-volume-high-symbolic"
    }

    onWidthChanged: adjustCorrectLocation()
    onHeightChanged: adjustCorrectLocation()
    onPositionChanged: adjustCorrectLocation()

    color: "transparent"

    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    SinkModel {
        id: paSinkModel

        onDefaultSinkChanged: {
            if (!defaultSink) {
                return
            }
        }
    }

    function adjustCorrectLocation() {
        var posX = control.position.x
        var posY = control.position.y

        if (posX + control.width >= StatusBar.screenRect.x + StatusBar.screenRect.width)
            posX = StatusBar.screenRect.x + StatusBar.screenRect.width - control.width - control.margin

        posY = rootItem.y + rootItem.height + control.margin

        control.x = posX
        control.y = posY
    }

    Brightness {
        id: brightness
    }

    NemacUI.WindowBlur {
        view: control
        geometry: Qt.rect(control.x, control.y, control.width, control.height)
        windowRadius: _background.radius
        enabled: true
    }

    NemacUI.WindowShadow {
        view: control
        geometry: Qt.rect(control.x, control.y, control.width, control.height)
        radius: _background.radius
    }

    Rectangle {
        id: _background
        anchors.fill: parent
        radius: windowHelper.compositing ? NemacUI.Theme.bigRadius * 1.5 : 0
        color: NemacUI.Theme.darkMode ? "#4D4D4D" : "#F0F0F0"
        opacity: windowHelper.compositing ? NemacUI.Theme.darkMode ? 0.6 : 0.8 : 1.0
        antialiasing: true
        border.width: 1 / Screen.devicePixelRatio
        border.pixelAligned: Screen.devicePixelRatio > 1 ? false : true
        border.color: control.borderColor

        Behavior on color {
            ColorAnimation {
                duration: 200
                easing.type: Easing.Linear
            }
        }
    }

    ColumnLayout {
        id: _mainLayout
        anchors.fill: parent
        anchors.margins: NemacUI.Units.largeSpacing
        spacing: NemacUI.Units.largeSpacing

        Item {
            id: topItem
            Layout.fillWidth: true
            height: 32

            RowLayout {
                id: topItemLayout
                anchors.fill: parent
                anchors.rightMargin: NemacUI.Units.largeSpacing
                spacing: NemacUI.Units.largeSpacing

                Label {
                    leftPadding: NemacUI.Units.largeSpacing
                    text: qsTr("Control Center")
                    font.bold: true
                    font.pointSize: 14
                    Layout.fillWidth: true
                }

                IconButton {
                    id: settingsButton
                    implicitWidth: topItem.height
                    implicitHeight: topItem.height
                    Layout.alignment: Qt.AlignTop
                    source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark/" : "light/") + "settings.svg"
                    onLeftButtonClicked: {
                        control.visible = false
                        process.startDetached("nemac-settings")
                    }
                }

//                IconButton {
//                    id: shutdownButton
//                    implicitWidth: topItem.height
//                    implicitHeight: topItem.height
//                    Layout.alignment: Qt.AlignTop
//                    source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark/" : "light/") + "system-shutdown-symbolic.svg"
//                    onLeftButtonClicked: {
//                        control.visible = false
//                        process.startDetached("nemac-shutdown")
//                    }
//                }
            }
        }

        MprisItem {
            Layout.fillWidth: true
        }

        Item {
            id: brightnessItem
            Layout.fillWidth: true
            height: 40
            visible: brightness.enabled

            Rectangle {
                id: brightnessItemBg
                anchors.fill: parent
                color: "white"
                radius: NemacUI.Theme.bigRadius
                opacity: NemacUI.Theme.darkMode ? 0.2 : 0.7
            }

            RowLayout {
                anchors.fill: brightnessItemBg
                anchors.leftMargin: NemacUI.Units.largeSpacing
                anchors.rightMargin: NemacUI.Units.largeSpacing
                anchors.topMargin: NemacUI.Units.smallSpacing
                anchors.bottomMargin: NemacUI.Units.smallSpacing
                spacing: NemacUI.Units.largeSpacing

                Image {
                    height: 16
                    width: height
                    sourceSize: Qt.size(width, height)
                    source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/brightness.svg"
                    smooth: false
                    antialiasing: true
                }

                Timer {
                    id: brightnessTimer
                    interval: 100
                    repeat: false
                    onTriggered: brightness.setValue(brightnessSlider.value)
                }

                Slider {
                    id: brightnessSlider
                    from: 1
                    to: 100
                    stepSize: 1
                    value: brightness.value
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    onMoved: brightnessTimer.start()
                }

//                Label {
//                    text: brightnessSlider.value + "%"
//                    color: NemacUI.Theme.disabledTextColor
//                    Layout.preferredWidth: _fontMetrics.advanceWidth("100%")
//                }
            }
        }

        Item {
            id: volumeItem
            Layout.fillWidth: true
            height: 40
            visible: defaultSink

            Rectangle {
                id: volumeItemBg
                anchors.fill: parent
                color: "white"
                radius: NemacUI.Theme.bigRadius
                opacity: NemacUI.Theme.darkMode ? 0.2 : 0.7
            }

            RowLayout {
                anchors.fill: volumeItemBg
                anchors.leftMargin: NemacUI.Units.largeSpacing
                anchors.rightMargin: NemacUI.Units.largeSpacing
                anchors.topMargin: NemacUI.Units.smallSpacing
                anchors.bottomMargin: NemacUI.Units.smallSpacing
                spacing: NemacUI.Units.largeSpacing

                Image {
                    height: 16
                    width: height
                    sourceSize: Qt.size(width, height)
                    source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/" + control.volumeIconName + ".svg"
                    smooth: false
                    antialiasing: true
                }

                Slider {
                    id: volumeSlider

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    from: PulseAudio.MinimalVolume
                    to: PulseAudio.NormalVolume

                    stepSize: to / (to / PulseAudio.NormalVolume * 100.0)

                    value: defaultSink ? defaultSink.volume : 0

                    onValueChanged: {
                        if (!defaultSink)
                            return

                        defaultSink.volume = value
                        defaultSink.muted = (value === 0)
                    }
                }

//                Label {
//                    text: parseInt(volumeSlider.value / PulseAudio.NormalVolume * 100.0) + "%"
//                    Layout.preferredWidth: _fontMetrics.advanceWidth("100%")
//                    color: NemacUI.Theme.disabledTextColor
//                }
            }
        }

        FontMetrics {
            id: _fontMetrics
        }

        RowLayout {
            Layout.leftMargin: NemacUI.Units.smallSpacing
            Layout.rightMargin: NemacUI.Units.smallSpacing
            spacing: 0

            Label {
                id: timeLabel
                leftPadding: NemacUI.Units.smallSpacing / 2
                color: NemacUI.Theme.textColor

                Timer {
                    interval: 1000
                    repeat: true
                    running: true
                    triggeredOnStart: true
                    onTriggered: {
                        timeLabel.text = new Date().toLocaleDateString(Qt.locale(), Locale.LongFormat)
                    }
                }
            }

            Item {
                Layout.fillWidth: true
            }

            StandardItem {
                width: batteryLayout.implicitWidth + NemacUI.Units.largeSpacing
                height: batteryLayout.implicitHeight + NemacUI.Units.largeSpacing

                onClicked: {
                    control.visible = false
                    process.startDetached("nemac-settings", ["-m", "battery"])
                }

                RowLayout {
                    id: batteryLayout
                    anchors.fill: parent
                    visible: battery.available
                    spacing: 0

                    Image {
                        id: batteryIcon
                        width: 22
                        height: 16
                        sourceSize: Qt.size(width, height)
                        source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark/" : "light/") + battery.iconSource
                        asynchronous: true
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        antialiasing: true
                        smooth: false
                    }

                    Label {
                        text: battery.chargePercent + "%"
                        color: NemacUI.Theme.textColor
                        rightPadding: NemacUI.Units.smallSpacing / 2
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                    }
                }
            }
        }
    }

}
