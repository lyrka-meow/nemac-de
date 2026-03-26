/*
 * Copyright (C) 2021 NemacDE Team.
 *
 * Author:     Reion Wong <reionwong@gmail.com>
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
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

    readonly property int contentMargin: Math.round(NemacUI.Units.largeSpacing * 1.25)

    implicitHeight: visible ? (mainColumn.implicitHeight + 2 * contentMargin) : 0
    height: implicitHeight

    property bool available: mprisManager.availableServices.length > 0
    property bool isPlaying: currentService && mprisManager.playbackStatus === Mpris.Playing
    property alias currentService: mprisManager.currentService
    property var artUrlTag: Mpris.metadataToString(Mpris.ArtUrl)
    property var titleTag: Mpris.metadataToString(Mpris.Title)
    property var artistTag: Mpris.metadataToString(Mpris.Artist)
    property var albumTag: Mpris.metadataToString(Mpris.Album)
    property var lengthTag: Mpris.metadataToString(Mpris.Length)

    property real trackLengthUs: {
        if (lengthTag in mprisManager.metadata)
            return Math.max(1, Number(mprisManager.metadata[lengthTag]))
        return 1
    }

    MprisManager {
        id: mprisManager

        onCurrentServiceChanged: control.updateInfo()
        onMetadataChanged: control.updateInfo()
        onPositionChanged: {
            if (!seekSlider.pressed)
                seekSlider.value = mprisManager.position
        }
    }

    Timer {
        id: positionTimer
        interval: 500
        repeat: true
        running: control.visible && control.isPlaying
        onTriggered: {
            if (!seekSlider.pressed && mprisManager.position >= 0)
                seekSlider.value = mprisManager.position
        }
    }

    Component.onCompleted: control.updateInfo()

    function updateInfo() {
        var titleAvailable = (titleTag in mprisManager.metadata) ? mprisManager.metadata[titleTag].toString() !== "" : false
        var artistAvailable = (artistTag in mprisManager.metadata) ? mprisManager.metadata[artistTag].toString() !== "" : false

        control.visible = titleAvailable || artistAvailable
        _songLabel.text = titleAvailable ? mprisManager.metadata[titleTag].toString() : ""
        _artistLabel.text = artistAvailable ? mprisManager.metadata[artistTag].toString() : ""
        _albumLabel.text = (albumTag in mprisManager.metadata) ? mprisManager.metadata[albumTag].toString() : ""
        artImage.source = (artUrlTag in mprisManager.metadata) ? mprisManager.metadata[artUrlTag].toString() : ""

        seekSlider.to = Math.max(control.trackLengthUs, 1)
        seekSlider.value = mprisManager.position >= 0 ? mprisManager.position : 0
    }

    function formatTime(us) {
        var sec = Math.floor(Number(us) / 1000000)
        var m = Math.floor(sec / 60)
        var s = sec % 60
        return m + ":" + (s < 10 ? "0" : "") + s
    }

    Rectangle {
        anchors.fill: parent
        color: "white"
        radius: NemacUI.Theme.bigRadius
        opacity: NemacUI.Theme.darkMode ? 0.2 : 0.7
    }

    ColumnLayout {
        id: mainColumn
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: contentMargin
        width: parent.width
        spacing: NemacUI.Units.largeSpacing

        ColumnLayout {
            id: artColumn
            Layout.fillWidth: true
            spacing: NemacUI.Units.largeSpacing

            Item {
                Layout.alignment: Qt.AlignHCenter
                width: 148
                height: 148

                Rectangle {
                    id: artCircle
                    anchors.centerIn: parent
                    width: 140
                    height: 140
                    radius: width / 2
                    color: NemacUI.Theme.darkMode ? "#2a2a2e" : "#e8e8ec"
                    border.width: 2
                    border.color: Qt.rgba(NemacUI.Theme.highlightColor.r,
                                          NemacUI.Theme.highlightColor.g,
                                          NemacUI.Theme.highlightColor.b, 0.55)

                    Image {
                        id: defaultImage
                        anchors.fill: parent
                        anchors.margins: 4
                        source: "qrc:/images/media-cover.svg"
                        sourceSize: Qt.size(width, height)
                        visible: !artImage.visible
                        fillMode: Image.Pad
                    }

                    Image {
                        id: artImage
                        anchors.fill: parent
                        anchors.margins: 4
                        visible: status === Image.Ready
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        layer.enabled: true
                        layer.effect: OpacityMask {
                            maskSource: Rectangle {
                                width: artImage.width
                                height: artImage.height
                                radius: width / 2
                            }
                        }
                    }
                }
            }

            Label {
                id: _songLabel
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 13
                font.bold: true
                font.capitalization: Font.AllUppercase
                elide: Text.ElideMiddle
                wrapMode: Text.WordWrap
                maximumLineCount: 2
                color: NemacUI.Theme.textColor
            }

            Label {
                id: _artistLabel
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 11
                elide: Text.ElideMiddle
                color: Qt.rgba(NemacUI.Theme.textColor.r, NemacUI.Theme.textColor.g, NemacUI.Theme.textColor.b, 0.8)
            }

            Label {
                id: _albumLabel
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                font.pointSize: 9
                font.capitalization: Font.AllUppercase
                elide: Text.ElideMiddle
                visible: text.length > 0
                color: Qt.rgba(NemacUI.Theme.textColor.r, NemacUI.Theme.textColor.g, NemacUI.Theme.textColor.b, 0.7)
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: NemacUI.Units.smallSpacing

            Label {
                text: formatTime(seekSlider.value)
                font.pointSize: 9
                color: Qt.rgba(NemacUI.Theme.textColor.r, NemacUI.Theme.textColor.g, NemacUI.Theme.textColor.b, 0.7)
                Layout.preferredWidth: 40
            }

            Slider {
                id: seekSlider
                Layout.fillWidth: true
                from: 0
                to: Math.max(control.trackLengthUs, 1)
                stepSize: Math.max(1, Math.max(control.trackLengthUs, 1) / 400)

                palette.mid: NemacUI.Theme.darkMode ? "#3a3a42" : "#d0d0d8"
                palette.highlight: NemacUI.Theme.highlightColor

                onPressedChanged: {
                    if (!pressed)
                        mprisManager.setPosition(Math.round(value))
                }
            }

            Label {
                text: formatTime(control.trackLengthUs)
                font.pointSize: 9
                color: Qt.rgba(NemacUI.Theme.textColor.r, NemacUI.Theme.textColor.g, NemacUI.Theme.textColor.b, 0.7)
                Layout.preferredWidth: 40
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 64
            Layout.alignment: Qt.AlignHCenter
            spacing: NemacUI.Units.largeSpacing * 1.5

            IconButton {
                width: 40
                height: 40
                source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/media-skip-backward-symbolic.svg"
                onLeftButtonClicked: if (mprisManager.canGoPrevious) mprisManager.previous()
                visible: mprisManager.canGoPrevious
            }

            Rectangle {
                width: 56
                height: 56
                radius: 28
                color: NemacUI.Theme.highlightColor
                visible: mprisManager.canPause || mprisManager.canPlay

                Image {
                    id: playPauseIcon
                    anchors.centerIn: parent
                    width: 28
                    height: 28
                    sourceSize: Qt.size(width, height)
                    source: control.isPlaying ? "qrc:/images/dark/media-playback-pause-symbolic.svg"
                                              : "qrc:/images/dark/media-playback-start-symbolic.svg"
                    smooth: false
                }

                ColorOverlay {
                    anchors.fill: playPauseIcon
                    source: playPauseIcon
                    color: "#ffffff"
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        if ((control.isPlaying && mprisManager.canPause) || (!control.isPlaying && mprisManager.canPlay))
                            mprisManager.playPause()
                    }
                }
            }

            IconButton {
                width: 40
                height: 40
                source: "qrc:/images/" + (NemacUI.Theme.darkMode ? "dark" : "light") + "/media-skip-forward-symbolic.svg"
                onLeftButtonClicked: if (mprisManager.canGoNext) mprisManager.next()
                visible: mprisManager.canGoNext
            }
        }
    }
}