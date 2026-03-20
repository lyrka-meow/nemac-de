import QtQuick 2.9
import QtQuick.Templates 2.2 as T
import NemacUI 1.0 as NemacUI

T.TabButton {
    id: control

    property int standardHeight: NemacUI.Units.iconSizes.medium + NemacUI.Units.smallSpacing
    property color pressedColor: Qt.rgba(NemacUI.Theme.textColor.r, NemacUI.Theme.textColor.g, NemacUI.Theme.textColor.b, 0.5)

    implicitWidth: Math.max(background ? background.implicitWidth : 0,
                            contentItem.implicitWidth + leftPadding + rightPadding)
    implicitHeight: Math.max(background ? background.implicitHeight : 0,
                             standardHeight)
    baselineOffset: contentItem.y + contentItem.baselineOffset

    padding: 0
    spacing: 0

    contentItem: Text {
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight

        text: control.text
        font: control.font
        color: !control.enabled ? NemacUI.Theme.disabledTextColor : control.pressed ? pressedColor : control.checked ? NemacUI.Theme.textColor : NemacUI.Theme.textColor
    }
}
