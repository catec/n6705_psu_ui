/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\components\DigitalReadout.qml
 * @brief Numeric digital display component for telemetry values.
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
    property string label: "V"
    property string valueText: "0.000"
    property string unit: ""
    property color valueColor: "#7BEBFF"

    radius: 8
    color: lightTheme ? "#F4FAFF" : "#02070D"
    border.width: 1
    border.color: lightTheme ? "#AFC8DD" : "#28415D"
    implicitHeight: 86

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 9
        spacing: 4

        Label {
            text: root.label
            color: lightTheme ? "#4A6C88" : "#80A0C3"
            font.pixelSize: 11
            Layout.fillWidth: true
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: root.valueText
                color: root.valueColor
                font.family: "Noto Sans Mono"
                font.pixelSize: 32
                font.bold: true
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
            }

            Label {
                text: root.unit
                color: lightTheme ? "#4E6E86" : "#9CB4CB"
                font.pixelSize: 12
                font.bold: true
            }
        }
    }
}




