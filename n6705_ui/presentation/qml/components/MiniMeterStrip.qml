/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\components\MiniMeterStrip.qml
 * @brief Compact meter strip component for channel cards.
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
    property var channelVm
    property int telemetryTick: 0

    function channelColor(channel) {
        if (channel === 1) {
            return "#D6D33A"
        }
        if (channel === 2) {
            return "#46CC5A"
        }
        if (channel === 3) {
            return "#39A8FF"
        }
        return "#D15AF0"
    }

    radius: 8
    color: lightTheme ? "#F4FAFF" : "#070C13"
    border.width: 1
    border.color: lightTheme ? "#B1C8DA" : "#22364A"
    implicitHeight: 78

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        Rectangle {
            radius: 4
            color: channelVm ? channelColor(channelVm.channelNumber) : "#AAB3BE"
            border.width: 1
            border.color: Qt.darker(color, 1.3)
            implicitWidth: 80
            implicitHeight: 26

            Label {
                anchors.centerIn: parent
                text: channelVm && channelVm.outputEnabled
                    ? ("CH" + channelVm.channelNumber + " ON")
                    : (channelVm ? ("CH" + channelVm.channelNumber + " OFF") : "CH-")
                color: "#0A0E14"
                font.pixelSize: 12
                font.bold: true
            }
        }

        Label {
            text: {
                var _ = telemetryTick
                return channelVm ? (channelVm.measuredVoltage.toFixed(3) + " V") : "--"
            }
            color: "#79D7FF"
            font.family: "Noto Sans Mono"
            font.pixelSize: 20
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }

        Label {
            text: {
                var _ = telemetryTick
                return channelVm ? (channelVm.measuredCurrent.toFixed(4) + " A") : "--"
            }
            color: "#FFC47C"
            font.family: "Noto Sans Mono"
            font.pixelSize: 18
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }

        Label {
            text: {
                var _ = telemetryTick
                return channelVm ? (channelVm.measuredPower.toFixed(3) + " W") : "--"
            }
            color: "#98F1C1"
            font.family: "Noto Sans Mono"
            font.pixelSize: 16
            font.bold: true
            Layout.fillWidth: true
            horizontalAlignment: Text.AlignRight
        }
    }
}




