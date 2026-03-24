/*
 * Copyright (C) 2021 NemacDE Team.
 *
 * Author:     revenmartin <revenmartin@gmail.com>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
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
import NemacUI 1.0 as NemacUI
import Nemac.Settings 1.0
import "../"

ItemPage {
    headerTitle: qsTr("About")

    About {
        id: about
    }

    Scrollable {
        anchors.fill: parent
        contentHeight: layout.implicitHeight

        ColumnLayout {
            id: layout
            anchors.fill: parent

            Item {
                height: NemacUI.Units.largeSpacing
            }

            Label {
                Layout.alignment: Qt.AlignTop | Qt.AlignHCenter
                text: "<b>Nemac DE</b>"
                font.pointSize: 28
                color: "#3385FF"
            }

            Item {
                height: NemacUI.Units.largeSpacing * 2
            }

            RoundedItem {
                StandardItem {
                    key: qsTr("System Version")
                    value: about.version
                }

                StandardItem {
                    key: qsTr("System Type")
                    value: about.architecture
                }

                StandardItem {
                    key: qsTr("Kernel Version")
                    value: about.kernelVersion
                }

                StandardItem {
                    key: qsTr("Processor")
                    value: about.cpuInfo
                }

                StandardItem {
                    key: qsTr("RAM")
                    value: about.memorySize
                }

                StandardItem {
                    key: qsTr("Internal Storage")
                    value: about.internalStorage
                }
            }

            Item {
                height: NemacUI.Units.smallSpacing
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: about.isNemacDE
                spacing: NemacUI.Units.smallSpacing

                Label {
                    Layout.fillWidth: true
                    visible: about.releaseInfoSummary.length > 0
                    text: about.releaseInfoSummary
                    wrapMode: Text.WordWrap
                    font.bold: about.releaseUpdateAvailable
                    color: about.releaseUpdateAvailable ? "#3385FF" : palette.windowText
                }

                Label {
                    Layout.fillWidth: true
                    visible: about.releaseInfoSubtext.length > 0
                    text: about.releaseInfoSubtext
                    wrapMode: Text.WordWrap
                    opacity: 0.88
                    font.pointSize: 11
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NemacUI.Units.smallSpacing
                    visible: about.releaseInfoBusy && !about.deUpdateBusy

                    BusyIndicator {
                        implicitWidth: 28
                        implicitHeight: 28
                        running: true
                    }

                    Label {
                        Layout.fillWidth: true
                        text: qsTr("Проверка релизов…")
                        opacity: 0.85
                    }
                }

                StandardButton {
                    Layout.fillWidth: true
                    text: qsTr("Обновить DE")
                    enabled: !about.deUpdateBusy
                    onClicked: about.startDeUpdate()
                }

                Label {
                    Layout.fillWidth: true
                    visible: about.deUpdateStatus.length > 0
                    text: about.deUpdatePhase === "downloading"
                          ? about.deUpdateStatus + " — " + Math.round(about.deUpdateProgress * 100) + "%"
                          : about.deUpdateStatus
                    wrapMode: Text.WordWrap
                    opacity: 0.9
                }

                ProgressBar {
                    Layout.fillWidth: true
                    visible: about.deUpdatePhase === "downloading"
                    from: 0
                    to: 1
                    value: about.deUpdateProgress
                }

                BusyIndicator {
                    Layout.alignment: Qt.AlignHCenter
                    implicitWidth: 48
                    implicitHeight: 48
                    visible: about.deUpdateBusy
                             && (about.deUpdatePhase === "checking"
                                 || about.deUpdatePhase === "installing")
                    running: visible
                }

                StandardButton {
                    Layout.fillWidth: true
                    visible: about.deUpdateCanCancel
                    text: qsTr("Остановить")
                    onClicked: about.cancelDeUpdate()
                }
            }
        }
    }
}
