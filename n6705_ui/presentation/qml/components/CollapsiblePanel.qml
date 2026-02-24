/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\components\CollapsiblePanel.qml
 * @brief Reusable collapsible panel container.
 * @author Mouhsine Kassimi Farhaoui
 * @par Mail
 * mouhsine98@gmail.com
 */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root
    property bool lightTheme: false
    property string title: "Panel"
    property bool collapsed: false
    property color panelColor: lightTheme ? "#F4FAFF" : "#111A25"
    property color borderColor: lightTheme ? "#B2C8DA" : "#2F4359"
    property color accentColor: "#5E82A6"
    property color headerColor: lightTheme ? "#E7F2FC" : "#162433"
    property color headerBorderColor: lightTheme ? "#B4CBDE" : "#30465C"
    property color titleColor: lightTheme ? "#18364C" : "#DCE9F8"
    default property alias contentData: contentColumn.data

    radius: 10
    color: panelColor
    border.width: 1
    border.color: borderColor

    implicitWidth: 320
    implicitHeight: headerBox.implicitHeight + bodyItem.implicitHeight + 18

    Column {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        Rectangle {
            id: headerBox
            width: parent.width
            implicitHeight: 36
            radius: 7
            color: root.headerColor
            border.width: 1
            border.color: root.headerBorderColor

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.margins: 4
                width: 4
                radius: 2
                color: root.accentColor
            }

            RowLayout {
                id: headerRow
                anchors.fill: parent
                anchors.margins: 6
                anchors.leftMargin: 12
                spacing: 8

                ToolButton {
                    text: root.collapsed ? "▸" : "▾"
                    onClicked: root.collapsed = !root.collapsed
                    font.pixelSize: 16
                    padding: 0
                    implicitWidth: 24
                    implicitHeight: 24
                }

                Label {
                    text: root.title
                    color: root.titleColor
                    font.pixelSize: 13
                    font.bold: true
                    Layout.fillWidth: true
                }
            }
        }

        Item {
            id: bodyItem
            width: parent.width
            implicitHeight: root.collapsed ? 0 : contentColumn.implicitHeight + 14
            clip: true

            Behavior on implicitHeight {
                NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
            }

            ColumnLayout {
                id: contentColumn
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.leftMargin: 6
                anchors.rightMargin: 6
                anchors.topMargin: 6
                spacing: 8
                visible: !root.collapsed
            }
        }
    }
}




