import QtQuick 2.1
import QtQuick.Window 2.2
import QtQuick.Templates 2.3 as T
import NemacUI 1.0 as NemacUI

T.Label {
    id: control

    verticalAlignment: lineCount > 1 ? Text.AlignTop : Text.AlignVCenter

    activeFocusOnTab: false
    // Text.NativeRendering is broken on non integer pixel ratios
    // renderType: Window.devicePixelRatio % 1 !== 0 ? Text.QtRendering : Text.NativeRendering

    renderType: NemacUI.Theme.renderType

    font.capitalization: NemacUI.Theme.defaultFont.capitalization
    font.family: NemacUI.Theme.fontFamily
    font.italic: NemacUI.Theme.defaultFont.italic
    font.letterSpacing: NemacUI.Theme.defaultFont.letterSpacing
    font.pointSize: NemacUI.Theme.fontSize
    font.strikeout: NemacUI.Theme.defaultFont.strikeout
    font.underline: NemacUI.Theme.defaultFont.underline
    font.weight: NemacUI.Theme.defaultFont.weight
    font.wordSpacing: NemacUI.Theme.defaultFont.wordSpacing
    color: NemacUI.Theme.textColor
    linkColor: NemacUI.Theme.linkColor

    opacity: enabled ? 1 : 0.6

    Accessible.role: Accessible.StaticText
    Accessible.name: text
}
