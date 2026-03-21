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
import Nemac.Settings 1.0
import Nemac.Screen 1.0 as CS
import NemacUI 1.0 as NemacUI
import "../"

ItemPage {
    headerTitle: qsTr("Display")

    Appearance {
        id: appearance
    }

    Brightness {
        id: brightness
    }

    CS.Screen {
        id: screen
    }

    Timer {
        id: brightnessTimer
        interval: 100
        repeat: false

        onTriggered: {
            brightness.setValue(brightnessSlider.value)
        }
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent
            spacing: NemacUI.Units.largeSpacing * 2

            RoundedItem {
                Layout.fillWidth: true
                visible: brightness.enabled

                Label {
                    text: qsTr("Brightness")
                    color: NemacUI.Theme.disabledTextColor
                    visible: brightness.enabled
                }

                Item {
                    height: NemacUI.Units.smallSpacing / 2
                }

                RowLayout {
                    spacing: NemacUI.Units.largeSpacing

                    Image {
                        width: 16
                        height: width
                        sourceSize.width: width
                        sourceSize.height: height
                        Layout.alignment: Qt.AlignVCenter
                        source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/display-brightness-low-symbolic.svg"
                    }

                    Slider {
                        id: brightnessSlider
                        Layout.fillWidth: true
                        Layout.alignment: Qt.AlignVCenter
                        value: brightness.value
                        from: 1
                        to: 100
                        stepSize: 1
                        onMoved: brightnessTimer.start()

                        ToolTip {
                            parent: brightnessSlider.handle
                            visible: brightnessSlider.pressed
                            text: brightnessSlider.value.toFixed(0)
                        }
                    }

                    Image {
                        width: 16
                        height: width
                        sourceSize.width: width
                        sourceSize.height: height
                        Layout.alignment: Qt.AlignVCenter
                        source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/display-brightness-symbolic.svg"
                    }
                }

                Item {
                    height: NemacUI.Units.smallSpacing / 2
                }
            }

            RoundedItem {
                visible: screenRepeater.count > 0

                Label {
                    text: qsTr("Screen")
                    color: NemacUI.Theme.disabledTextColor
                }

                TabBar {
                    id: screenTabBar
                    Layout.fillWidth: true
                    visible: screenRepeater.count > 1
                    currentIndex: 0

                    Repeater {
                        id: screenTabRepeater
                        model: screen.outputModel

                        TabButton {
                            text: {
                                var name = model.display
                                if (name.length > 20)
                                    name = name.substring(0, 17) + "..."
                                return name
                            }
                            width: screenTabBar.width / screenTabRepeater.count
                        }
                    }
                }

                Item {
                    height: NemacUI.Units.smallSpacing / 2
                    visible: screenTabBar.visible
                }

                Repeater {
                    id: screenRepeater
                    model: screen.outputModel

                    ColumnLayout {
                        id: screenDelegate
                        Layout.fillWidth: true
                        visible: screenRepeater.count === 1 || index === screenTabBar.currentIndex

                        property var output: model

                        GridLayout {
                            columns: 2
                            columnSpacing: NemacUI.Units.largeSpacing * 1.5
                            rowSpacing: NemacUI.Units.largeSpacing * 1.5
                            Layout.fillWidth: true

                            Label {
                                text: qsTr("Screen Name")
                                visible: screenRepeater.count > 1
                            }

                            Label {
                                text: screenDelegate.output.display
                                color: NemacUI.Theme.disabledTextColor
                                visible: screenRepeater.count > 1
                            }

                            Label {
                                text: qsTr("Resolution")
                            }

                            ComboBox {
                                Layout.fillWidth: true
                                model: screenDelegate.output.resolutions
                                leftPadding: NemacUI.Units.largeSpacing
                                rightPadding: NemacUI.Units.largeSpacing
                                topInset: 0
                                bottomInset: 0
                                currentIndex: screenDelegate.output.resolutionIndex !== undefined ?
                                                  screenDelegate.output.resolutionIndex : -1
                                onActivated: {
                                    screenDelegate.output.resolutionIndex = currentIndex
                                    screen.save()
                                }
                            }

                            Label {
                                text: qsTr("Refresh rate")
                            }

                            ComboBox {
                                Layout.fillWidth: true
                                model: screenDelegate.output.refreshRates
                                leftPadding: NemacUI.Units.largeSpacing
                                rightPadding: NemacUI.Units.largeSpacing
                                topInset: 0
                                bottomInset: 0
                                currentIndex: screenDelegate.output.refreshRateIndex ?
                                                  screenDelegate.output.refreshRateIndex : 0
                                onActivated: {
                                    screenDelegate.output.refreshRateIndex = currentIndex
                                    screen.save()
                                }
                            }

                            Label {
                                text: qsTr("Rotation")
                            }

                            Item {
                                Layout.fillWidth: true
                                height: _rotLayout.implicitHeight

                                RowLayout {
                                    id: _rotLayout
                                    anchors.fill: parent
                                    spacing: 0

                                    RotationButton {
                                        value: 0
                                    }

                                    Item { Layout.fillWidth: true }

                                    RotationButton {
                                        value: 90
                                    }

                                    Item { Layout.fillWidth: true }

                                    RotationButton {
                                        value: 180
                                    }

                                    Item { Layout.fillWidth: true }

                                    RotationButton {
                                        value: 270
                                    }
                                }
                            }

                            Label {
                                text: qsTr("Primary")
                                visible: screenRepeater.count > 1
                            }

                            CheckBox {
                                checked: screenDelegate.output.primary
                                visible: screenRepeater.count > 1
                                onClicked: {
                                    if (checked) {
                                        screenDelegate.output.primary = true
                                        screen.save()
                                    } else {
                                        checked = true
                                    }
                                }
                            }

                            Label {
                                text: qsTr("Enabled")
                                visible: screenRepeater.count > 1
                            }

                            CheckBox {
                                checked: screenDelegate.output.enabled
                                visible: screenRepeater.count > 1
                                onClicked: {
                                    screenDelegate.output.enabled = checked
                                    screen.save()
                                }
                            }
                        }
                    }
                }
            }

            RoundedItem {
                Label {
                    text: qsTr("Scale")
                    color: NemacUI.Theme.disabledTextColor
                }

                TabBar {
                    id: dockSizeTabbar
                    Layout.fillWidth: true

                    TabButton {
                        text: "100%"
                    }

                    TabButton {
                        text: "125%"
                    }

                    TabButton {
                        text: "150%"
                    }

                    TabButton {
                        text: "175%"
                    }

                    TabButton {
                        text: "200%"
                    }

                    currentIndex: {
                        var index = 0

                        if (appearance.devicePixelRatio <= 1.0)
                            index = 0
                        else if (appearance.devicePixelRatio <= 1.25)
                            index = 1
                        else if (appearance.devicePixelRatio <= 1.50)
                            index = 2
                        else if (appearance.devicePixelRatio <= 1.75)
                            index = 3
                        else if (appearance.devicePixelRatio <= 2.0)
                            index = 4

                        return index
                    }

                    onCurrentIndexChanged: {
                        var value = 1.0

                        switch (currentIndex) {
                        case 0:
                            value = 1.0
                            break;
                        case 1:
                            value = 1.25
                            break;
                        case 2:
                            value = 1.50
                            break;
                        case 3:
                            value = 1.75
                            break;
                        case 4:
                            value = 2.0
                            break;
                        }

                        if (appearance.devicePixelRatio !== value) {
                            appearance.setDevicePixelRatio(value)
                        }
                    }
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }
}
