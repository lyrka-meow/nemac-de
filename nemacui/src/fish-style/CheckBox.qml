/*
 * Copyright 2017 Marco Martin <mart@kde.org>
 * Copyright 2017 The Qt Company Ltd.
 *
 * GNU Lesser General Public License Usage
 * Alternatively, this file may be used under the terms of the GNU Lesser
 * General Public License version 3 as published by the Free Software
 * Foundation and appearing in the file LICENSE.LGPLv3 included in the
 * packaging of this file. Please review the following information to
 * ensure the GNU Lesser General Public License version 3 requirements
 * will be met: https://www.gnu.org/licenses/lgpl.html.
 *
 * GNU General Public License Usage
 * Alternatively, this file may be used under the terms of the GNU
 * General Public License version 2.0 or later as published by the Free
 * Software Foundation and appearing in the file LICENSE.GPL included in
 * the packaging of this file. Please review the following information to
 * ensure the GNU General Public License version 2.0 requirements will be
 * met: http://www.gnu.org/licenses/gpl-2.0.html.
 */

import QtQuick 2.9
import QtQuick.Templates 2.2 as T
import NemacUI 1.0 as NemacUI

T.CheckBox {
    id: controlRoot

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                            Math.max(contentItem.implicitHeight,
                                        indicator ? indicator.implicitHeight : 0) + topPadding + bottomPadding)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    padding: 1
    spacing: NemacUI.Units.smallSpacing

    hoverEnabled: true

    indicator: CheckIndicator {
        control: controlRoot
    }

//    indicator: Item {
//        width: NemacUI.Units.iconSizes.smallMedium + NemacUI.Units.smallSpacing
//        height: NemacUI.Units.iconSizes.smallMedium + NemacUI.Units.smallSpacing

//        CheckIndicator {
//            anchors.centerIn: parent
//            width: NemacUI.Units.iconSizes.smallMedium
//            height: NemacUI.Units.iconSizes.smallMedium
//            control: controlRoot
//        }
//    }

    contentItem: Text {
        leftPadding: controlRoot.indicator && !controlRoot.mirrored ? controlRoot.indicator.width + controlRoot.spacing : 0
        rightPadding: controlRoot.indicator && controlRoot.mirrored ? controlRoot.indicator.width + controlRoot.spacing : 0
        opacity: controlRoot.enabled ? 1 : 0.6
        text: controlRoot.text
        font: controlRoot.font
        elide: Text.ElideRight
        visible: controlRoot.text
        horizontalAlignment: Text.AlignLeft
        verticalAlignment: Text.AlignVCenter
        color: NemacUI.Theme.textColor
    }
}
