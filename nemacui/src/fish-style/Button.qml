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
import QtQuick.Templates 2.12 as T
import QtGraphicalEffects 1.0
import NemacUI 1.0 as NemacUI
import QtQuick.Controls.impl 2.12

T.Button {
    id: control
    implicitWidth: Math.max(background.implicitWidth, contentItem.implicitWidth + NemacUI.Units.largeSpacing)
    implicitHeight: background.implicitHeight
    hoverEnabled: true

    icon.width: NemacUI.Units.iconSizes.small
    icon.height: NemacUI.Units.iconSizes.small

    icon.color: control.enabled ? (control.highlighted ? control.NemacUI.Theme.highlightColor : control.NemacUI.Theme.textColor) : control.NemacUI.Theme.disabledTextColor
    spacing: NemacUI.Units.smallSpacing

    property color hoveredColor: NemacUI.Theme.darkMode ? Qt.lighter(NemacUI.Theme.alternateBackgroundColor, 1.2)
                                                       : Qt.darker(NemacUI.Theme.alternateBackgroundColor, 1.1)

    property color pressedColor: NemacUI.Theme.darkMode ? Qt.lighter(NemacUI.Theme.alternateBackgroundColor, 1.1)
                                                       : Qt.darker(NemacUI.Theme.alternateBackgroundColor, 1.2)

    property color borderColor: Qt.rgba(NemacUI.Theme.highlightColor.r,
                                        NemacUI.Theme.highlightColor.g,
                                        NemacUI.Theme.highlightColor.b, 0.5)

    property color flatHoveredColor: Qt.rgba(NemacUI.Theme.highlightColor.r,
                                             NemacUI.Theme.highlightColor.g,
                                             NemacUI.Theme.highlightColor.b, 0.2)
    property color flatPressedColor: Qt.rgba(NemacUI.Theme.highlightColor.r,
                                             NemacUI.Theme.highlightColor.g,
                                             NemacUI.Theme.highlightColor.b, 0.25)

    contentItem: IconLabel {
        text: control.text
        font: control.font
        icon: control.icon
        color: !control.enabled ? control.NemacUI.Theme.disabledTextColor : control.flat ? NemacUI.Theme.highlightColor : NemacUI.Theme.textColor
        spacing: control.spacing
        mirrored: control.mirrored
        display: control.display
        alignment: Qt.AlignCenter
    }

    background: Item {
        implicitWidth: (NemacUI.Units.iconSizes.medium * 3) + NemacUI.Units.largeSpacing
        implicitHeight: NemacUI.Units.iconSizes.medium + NemacUI.Units.smallSpacing

        Rectangle {
            id: _flatBackground
            anchors.fill: parent
            radius: NemacUI.Theme.mediumRadius
            border.width: 1
            border.color: control.enabled ? control.activeFocus ? NemacUI.Theme.highlightColor : "transparent"
                                          : "transparent"
            visible: control.flat

            color: {
                if (!control.enabled)
                    return NemacUI.Theme.alternateBackgroundColor

                if (control.pressed)
                    return control.flatPressedColor

                if (control.hovered)
                    return control.flatHoveredColor

                return Qt.rgba(NemacUI.Theme.highlightColor.r,
                               NemacUI.Theme.highlightColor.g,
                               NemacUI.Theme.highlightColor.b, 0.1)
            }
        }

        Rectangle {
            id: _background
            anchors.fill: parent
            radius: NemacUI.Theme.mediumRadius
            border.width: 1
            visible: !control.flat
            border.color: control.enabled ? control.activeFocus ? NemacUI.Theme.highlightColor : "transparent"
                                          : "transparent"

            color: {
                if (!control.enabled)
                    return NemacUI.Theme.alternateBackgroundColor

                if (control.pressed)
                    return control.pressedColor

                if (control.hovered)
                    return control.hoveredColor

                return NemacUI.Theme.alternateBackgroundColor
            }
        }
    }
}
