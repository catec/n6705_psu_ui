/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\components\SetpointDial.qml
 * @brief Dial-based editor component for channel setpoints.
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
    property string label: "Setpoint"
    property string unit: ""
    property real minValue: 0.0
    property real maxValue: 1.0
    property real value: 0.0
    property int decimals: 3
    signal valueEdited(real value)
    property bool _dialMoved: false
    property bool _sliderMoved: false

    function _clamp(v) {
        var lo = Math.min(minValue, maxValue)
        var hi = Math.max(minValue, maxValue)
        return Math.max(lo, Math.min(hi, v))
    }

    radius: 8
    color: lightTheme ? "#EEF7FF" : "#0A1420"
    border.width: 1
    border.color: lightTheme ? "#ABC5DA" : "#2C435A"
    implicitHeight: 246

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 6

        Label {
            text: root.label
            color: lightTheme ? "#1A3A51" : "#D3E0F2"
            font.pixelSize: 12
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Dial {
            id: dial
            Layout.alignment: Qt.AlignHCenter
            from: Math.min(root.minValue, root.maxValue)
            to: Math.max(root.minValue, root.maxValue)
            value: root._clamp(root.value)
            stepSize: Math.max((to - from) / 300.0, 0.0001)
            snapMode: Dial.SnapAlways

            onMoved: {
                var clamped = root._clamp(value)
                root.value = clamped
                root._dialMoved = true
            }

            onPressedChanged: {
                if (!pressed && root._dialMoved) {
                    root._dialMoved = false
                    root.valueEdited(root._clamp(value))
                }
            }
        }

        Slider {
            id: slider
            Layout.fillWidth: true
            from: dial.from
            to: dial.to
            value: root._clamp(root.value)
            stepSize: dial.stepSize

            onMoved: {
                var clamped = root._clamp(value)
                root.value = clamped
                root._sliderMoved = true
            }

            onPressedChanged: {
                if (!pressed && root._sliderMoved) {
                    root._sliderMoved = false
                    root.valueEdited(root._clamp(value))
                }
            }
        }

        Label {
            text: root.value.toFixed(root.decimals) + (root.unit === "" ? "" : (" " + root.unit))
            color: "#7EE0BA"
            font.family: "Noto Sans Mono"
            font.pixelSize: 13
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            text: "Range " + root.minValue.toFixed(root.decimals) + " .. " + root.maxValue.toFixed(root.decimals) + (root.unit === "" ? "" : (" " + root.unit))
            color: lightTheme ? "#55758F" : "#86A4C2"
            font.pixelSize: 10
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WrapAnywhere
        }
    }
}




