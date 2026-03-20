import QtQuick 2.15
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import NemacUI 1.0 as NemacUI
import Nemac.TextEditor 1.0

NemacUI.Window {
    id: root
    width: 640
    height: 480
    minimumWidth: 300
    minimumHeight: 300
    visible: true
    title: qsTr("Text Editor")

    FileHelper {
        id: fileHelper

        onNewPath: {
            _tabView.addTab(textEditorCompeont, { fileUrl: path })
        }
    }

    headerItem: Item {
        Rectangle {
            anchors.fill: parent
            color: NemacUI.Theme.backgroundColor
        }

        NemacUI.TabBar {
            id: _tabbar
            anchors.fill: parent
            anchors.margins: NemacUI.Units.smallSpacing / 2
            anchors.rightMargin: NemacUI.Units.largeSpacing * 4

            model: _tabView.count
            currentIndex : _tabView.currentIndex

            onNewTabClicked: {
                addTab()
            }

            delegate: NemacUI.TabButton {
                id: _tabBtn
                text: _tabView.contentModel.get(index).tabName
                implicitHeight: _tabbar.height
                implicitWidth: Math.min(_tabbar.width / _tabbar.count,
                                        _tabBtn.contentWidth)

                ToolTip.delay: 1000
                ToolTip.timeout: 5000

                checked: _tabView.currentIndex === index

                ToolTip.visible: hovered
                ToolTip.text: _tabView.contentModel.get(index).fileUrl

                onClicked: {
                    _tabView.currentIndex = index
                    _tabView.currentItem.forceActiveFocus()
                }

                onCloseClicked: {
                    _tabView.closeTab(index)
                }
            }
        }
    }

    DropArea {
        id: _dropArea
        anchors.fill: parent

        onDropped: {
            if (drop.hasUrls) {
                for (var i = 0; i < drop.urls.length; ++i) {
                    fileHelper.addPath(drop.urls[i])
                }
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        NemacUI.TabView {
            id: _tabView
            Layout.fillWidth: true
            Layout.fillHeight: true
        }

        Item {
            id: _bottomItem
            z: 999
            Layout.fillWidth: true
            Layout.preferredHeight: 20 + NemacUI.Units.smallSpacing

            Rectangle {
                anchors.fill: parent
                color: NemacUI.Theme.backgroundColor
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.leftMargin: NemacUI.Units.smallSpacing
                anchors.rightMargin: NemacUI.Units.smallSpacing
                anchors.bottomMargin: NemacUI.Units.smallSpacing

                Label {
                    text: _tabView.currentItem ? qsTr("Characters %1").arg(_tabView.currentItem.characterCount)
                                               : ""
                }
            }
        }
    }

    function addPath(path) {
        _tabView.addTab(textEditorCompeont, { fileUrl: path })
    }

    function addTab() {
        _tabView.addTab(textEditorCompeont, {})
    }

    Component {
        id: textEditorCompeont

        TextEditor {
            fileUrl: "file:///home/nemac/桌面/winepath"
        }
    }

    Component.onCompleted: {
        // addTab()
    }
}
