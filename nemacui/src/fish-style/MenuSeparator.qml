import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Templates 2.12 as T
import NemacUI 1.0 as NemacUI

T.MenuSeparator {
    id: control

    implicitHeight: NemacUI.Units.largeSpacing + separator.height
    width: parent.width

    background: Rectangle {
        id: separator
        anchors.centerIn: control
        width: control.width - NemacUI.Units.largeSpacing * 2
        height: 1
        color: NemacUI.Theme.textColor
        opacity: 0.3
    }
}