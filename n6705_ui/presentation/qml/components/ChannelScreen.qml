/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\components\ChannelScreen.qml
 * @brief Channel control and readout panel component.
 * @author Mouhsine Kassimi Farhaoui
 * @par Mail
 * mouhsine98@gmail.com
 */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "."

Rectangle {
    id: root
    property var channelVm
    property var dashboard
    property bool lightTheme: false
    property int telemetryTick: 0
    property bool syncingFromDevice: false

    radius: 10
    color: lightTheme ? "#EEF6FD" : "#060B12"
    border.width: 1
    border.color: lightTheme ? "#B2C9DB" : "#223649"

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

    function safeNumber(text, fallback) {
        var value = Number(text)
        return Number.isFinite(value) ? value : fallback
    }

    function clampVoltage(value) {
        if (!channelVm) {
            return value
        }
        return Math.max(channelVm.voltageMin, Math.min(channelVm.voltageMax, value))
    }

    function clampCurrent(value) {
        if (!channelVm) {
            return value
        }
        return Math.max(channelVm.currentMin, Math.min(channelVm.currentMax, value))
    }

    function modeText() {
        if (!channelVm) {
            return "--"
        }
        if (!channelVm.outputEnabled) {
            return "OFF"
        }
        if (channelVm.setCurrent <= 0.0) {
            return "CV"
        }
        var ratio = Math.abs(channelVm.measuredCurrent) / Math.max(1e-9, Math.abs(channelVm.setCurrent))
        return ratio >= 0.98 ? "CC" : "CV"
    }

    function applySetpoints() {
        if (!channelVm || !dashboard) {
            return
        }
        var v = root.clampVoltage(root.safeNumber(voltageInput.text, channelVm.setVoltage))
        var c = root.clampCurrent(root.safeNumber(currentInput.text, channelVm.setCurrent))
        voltageInput.text = v.toFixed(3)
        currentInput.text = c.toFixed(4)
        dashboard.applyChannelSetpoints(channelVm.channelNumber, v, c)
    }

    function queueAutoApply() {
        if (syncingFromDevice || !channelVm || !dashboard || !dashboard.connected) {
            return
        }
        autoApplyTimer.restart()
    }

    Timer {
        id: autoApplyTimer
        interval: 180
        repeat: false
        onTriggered: root.applySetpoints()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 10
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: dashboard ? dashboard.channelCount : 4

                delegate: Rectangle {
                    readonly property int channelNumber: index + 1
                    Layout.fillWidth: true
                    Layout.preferredHeight: 56
                    radius: 5
                    color: channelColor(channelNumber)
                    border.width: dashboard && dashboard.chartChannel === channelNumber ? 2 : 1
                    border.color: dashboard && dashboard.chartChannel === channelNumber
                        ? "#F5FAFF"
                        : Qt.darker(color, 1.35)

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (dashboard) {
                                dashboard.chartChannel = channelNumber
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 4
                        spacing: 1

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 4

                            Label {
                                text: "" + channelNumber
                                color: "#081018"
                                font.pixelSize: 14
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: dashboard && dashboard.channelVm(channelNumber).outputEnabled ? "On" : "Off"
                                color: "#081018"
                                font.pixelSize: 10
                                font.bold: true
                            }
                        }

                        Label {
                            text: {
                                var _ = telemetryTick
                                return dashboard
                                    ? (dashboard.channelVm(channelNumber).measuredVoltage.toFixed(2) + "V")
                                    : "--"
                            }
                            color: "#0A111A"
                            font.pixelSize: 10
                            font.family: "Noto Sans Mono"
                            font.bold: true
                        }

                        Label {
                            text: {
                                var _ = telemetryTick
                                return dashboard
                                    ? (dashboard.channelVm(channelNumber).measuredCurrent.toFixed(3) + "A")
                                    : "--"
                            }
                            color: "#0A111A"
                            font.pixelSize: 10
                            font.family: "Noto Sans Mono"
                            font.bold: true
                        }
                    }
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 430
                Layout.fillHeight: true
                radius: 8
                color: lightTheme ? "#F6FBFF" : "#091421"
                border.width: 1
                border.color: lightTheme ? "#B4CBDE" : "#273A4F"

                ScrollView {
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    contentWidth: availableWidth

                    ColumnLayout {
                        width: parent.width
                        spacing: 10

                        CollapsiblePanel {
                            Layout.fillWidth: true
                            title: "Output Settings"
                            accentColor: "#617B9D"
                            collapsed: false
                            panelColor: lightTheme ? "#EEF6FD" : "#0F1722"
                            borderColor: lightTheme ? "#B4CBDE" : "#2B4158"
                            lightTheme: root.lightTheme

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 8
                                rowSpacing: 8

                                Label { text: "Voltage Set"; color: lightTheme ? "#1A3A51" : "#D5E1F1" }
                                TextField {
                                    id: voltageInput
                                    objectName: "meterVoltageInput"
                                    Layout.fillWidth: true
                                    text: channelVm ? channelVm.setVoltage.toFixed(3) : "0.000"
                                    onEditingFinished: root.queueAutoApply()
                                }

                                Label { text: "Current Limit"; color: lightTheme ? "#1A3A51" : "#D5E1F1" }
                                TextField {
                                    id: currentInput
                                    objectName: "meterCurrentInput"
                                    Layout.fillWidth: true
                                    text: channelVm ? channelVm.setCurrent.toFixed(4) : "0.0000"
                                    onEditingFinished: root.queueAutoApply()
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: channelVm
                                    ? ("Limits -> V: " + channelVm.voltageMin.toFixed(3) + " .. " + channelVm.voltageMax.toFixed(3)
                                    + " | I: " + channelVm.currentMin.toFixed(4) + " .. " + channelVm.currentMax.toFixed(4))
                                    : "Limits unavailable"
                                color: lightTheme ? "#4F6E86" : "#8FB0CE"
                                font.family: "Noto Sans Mono"
                                font.pixelSize: 11
                                wrapMode: Text.WrapAnywhere
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                SetpointDial {
                                    id: voltageDial
                                    Layout.fillWidth: true
                                    label: "Voltage (Radial)"
                                    unit: "V"
                                    decimals: 3
                                    minValue: channelVm ? channelVm.voltageMin : 0.0
                                    maxValue: channelVm ? channelVm.voltageMax : 60.0
                                    value: channelVm ? channelVm.setVoltage : 0.0
                                    lightTheme: root.lightTheme
                                    onValueEdited: function(value) {
                                        voltageInput.text = root.clampVoltage(value).toFixed(3)
                                        root.queueAutoApply()
                                    }
                                }

                                SetpointDial {
                                    id: currentDial
                                    Layout.fillWidth: true
                                    label: "Current (Radial)"
                                    unit: "A"
                                    decimals: 4
                                    minValue: channelVm ? channelVm.currentMin : 0.0
                                    maxValue: channelVm ? channelVm.currentMax : 10.0
                                    value: channelVm ? channelVm.setCurrent : 0.0
                                    lightTheme: root.lightTheme
                                    onValueEdited: function(value) {
                                        currentInput.text = root.clampCurrent(value).toFixed(4)
                                        root.queueAutoApply()
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Button {
                                    objectName: "meterApplyButton"
                                    text: "Apply"
                                    Layout.fillWidth: true
                                    onClicked: root.applySetpoints()
                                }

                                Switch {
                                    id: outputSwitch
                                    text: checked ? "Output ON" : "Output OFF"
                                    checked: channelVm ? channelVm.outputEnabled : false
                                    onToggled: {
                                        if (channelVm && dashboard) {
                                            dashboard.setChannelOutput(channelVm.channelNumber, checked)
                                        }
                                    }
                                }
                            }
                        }

                        CollapsiblePanel {
                            Layout.fillWidth: true
                            title: "Properties"
                            collapsed: true
                            accentColor: "#58776A"
                            panelColor: lightTheme ? "#EEF6FD" : "#0F1722"
                            borderColor: lightTheme ? "#B4CBDE" : "#2B4158"
                            lightTheme: root.lightTheme

                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                columnSpacing: 10
                                rowSpacing: 6

                                Label { text: "Set Voltage"; color: lightTheme ? "#4F6E86" : "#AFC2D8" }
                                Label { text: channelVm ? (channelVm.setVoltage.toFixed(4) + " V") : "--"; color: lightTheme ? "#1A3A51" : "#ECF3FF" }

                                Label { text: "Set Current"; color: lightTheme ? "#4F6E86" : "#AFC2D8" }
                                Label { text: channelVm ? (channelVm.setCurrent.toFixed(6) + " A") : "--"; color: lightTheme ? "#1A3A51" : "#ECF3FF" }

                                Label { text: "Charge"; color: lightTheme ? "#4F6E86" : "#AFC2D8" }
                                Label { text: channelVm ? (channelVm.chargeAh.toFixed(9) + " Ah") : "--"; color: lightTheme ? "#1A3A51" : "#ECF3FF" }

                                Label { text: "Energy"; color: lightTheme ? "#4F6E86" : "#AFC2D8" }
                                Label { text: channelVm ? (channelVm.energyWh.toFixed(9) + " Wh") : "--"; color: lightTheme ? "#1A3A51" : "#ECF3FF" }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 8
                color: lightTheme ? "#F8FCFF" : "#07111B"
                border.width: 1
                border.color: lightTheme ? "#B4CBDE" : "#273A4F"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 42
                        radius: 6
                        color: lightTheme ? "#EDF6FD" : "#0D1A28"
                        border.width: 1
                        border.color: lightTheme ? "#B4CBDE" : "#2E445B"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Label {
                                text: channelVm ? ("OUTPUT " + channelVm.channelNumber) : "OUTPUT --"
                                color: channelVm ? channelColor(channelVm.channelNumber) : "#D6D33A"
                                font.pixelSize: 16
                                font.bold: true
                            }

                            Label {
                                text: "Mode: " + modeText()
                                color: lightTheme ? "#1D3D54" : "#D8E5F6"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: channelVm && channelVm.outputEnabled ? "Output Enabled" : "Output Disabled"
                                color: channelVm && channelVm.outputEnabled ? "#8DF2C3" : "#F4AF8E"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                    }

                    DigitalReadout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 116
                        label: "Voltage"
                        valueText: {
                            var _ = telemetryTick
                            return channelVm ? channelVm.measuredVoltage.toFixed(4) : "0.0000"
                        }
                        unit: "V"
                        valueColor: "#00C4FF"
                        lightTheme: root.lightTheme
                    }

                    DigitalReadout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 116
                        label: "Current"
                        valueText: {
                            var _ = telemetryTick
                            return channelVm ? channelVm.measuredCurrent.toFixed(6) : "0.000000"
                        }
                        unit: "A"
                        valueColor: "#FFBD61"
                        lightTheme: root.lightTheme
                    }

                    DigitalReadout {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 116
                        label: "Power"
                        valueText: {
                            var _ = telemetryTick
                            return channelVm ? channelVm.measuredPower.toFixed(4) : "0.0000"
                        }
                        unit: "W"
                        valueColor: "#82F0B4"
                        lightTheme: root.lightTheme
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            radius: 6
                            color: lightTheme ? "#EDF6FD" : "#0D1A28"
                            border.width: 1
                            border.color: lightTheme ? "#B4CBDE" : "#2E445B"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8

                                Label {
                                    text: "Charge"
                                    color: lightTheme ? "#4F6E86" : "#AAC0DA"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Label {
                                    text: channelVm ? (channelVm.chargeAh.toFixed(9) + " Ah") : "--"
                                    color: lightTheme ? "#1A3A51" : "#ECF3FF"
                                    font.family: "Noto Sans Mono"
                                    font.pixelSize: 16
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 74
                            radius: 6
                            color: lightTheme ? "#EDF6FD" : "#0D1A28"
                            border.width: 1
                            border.color: lightTheme ? "#B4CBDE" : "#2E445B"

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 8

                                Label {
                                    text: "Energy"
                                    color: lightTheme ? "#4F6E86" : "#AAC0DA"
                                    font.pixelSize: 12
                                    font.bold: true
                                }
                                Label {
                                    text: channelVm ? (channelVm.energyWh.toFixed(9) + " Wh") : "--"
                                    color: lightTheme ? "#1A3A51" : "#ECF3FF"
                                    font.family: "Noto Sans Mono"
                                    font.pixelSize: 16
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }
        }
    }

    Connections {
        target: channelVm
        function onDataChanged() {
            if (!channelVm) {
                return
            }
            root.syncingFromDevice = true
            if (!voltageInput.activeFocus) {
                voltageInput.text = root.clampVoltage(channelVm.setVoltage).toFixed(3)
            }
            if (!currentInput.activeFocus) {
                currentInput.text = root.clampCurrent(channelVm.setCurrent).toFixed(4)
            }
            voltageDial.value = root.clampVoltage(channelVm.setVoltage)
            currentDial.value = root.clampCurrent(channelVm.setCurrent)
            outputSwitch.checked = channelVm.outputEnabled
            root.syncingFromDevice = false
        }
    }
}




