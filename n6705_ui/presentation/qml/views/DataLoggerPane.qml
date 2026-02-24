/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\views\DataLoggerPane.qml
 * @brief Data logger view with event stream and channel summaries.
 * @author Mouhsine Kassimi Farhaoui
 * @par Mail
 * mouhsine98@gmail.com
 */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

import "../components"

Item {
    id: root
    property var dashboard
    property bool lightTheme: false
    property bool showEventPanel: true
    property int telemetryTick: 0

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: lightTheme ? "#F0F7FE" : "#090E14"
        border.width: 1
        border.color: lightTheme ? "#B2C9DB" : "#223141"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 6
            color: lightTheme ? "#EAF4FD" : "#121C29"
            border.width: 1
            border.color: lightTheme ? "#B4CBDE" : "#2A3E54"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Label {
                    text: "Data Logger View"
                    color: lightTheme ? "#17374E" : "#DEE7F4"
                    font.pixelSize: 14
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: root.dashboard && root.dashboard.loggingActive ? "LOGGING ACTIVE" : "LOGGER IDLE"
                    color: root.dashboard && root.dashboard.loggingActive ? "#83F2B7" : "#F5BA84"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        GridLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 330
            columns: 2
            rowSpacing: 10
            columnSpacing: 10

            Repeater {
                model: root.dashboard ? root.dashboard.channelCount : 4
                delegate: Rectangle {
                    readonly property int channelNumber: index + 1
                    property var channelVm: root.dashboard ? root.dashboard.channelVm(channelNumber) : null

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumHeight: 150
                    radius: 8
                    color: lightTheme ? "#EEF6FD" : "#101925"
                    border.width: 1
                    border.color: lightTheme ? "#B4CBDE" : "#2E4156"

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        spacing: 6

                        Label {
                            text: "CH" + channelNumber
                            color: channelNumber === 1 ? "#D6D33A" : (channelNumber === 2 ? "#46CC5A" : (channelNumber === 3 ? "#39A8FF" : "#D15AF0"))
                            font.bold: true
                            font.pixelSize: 30
                        }

                        Label {
                            text: {
                                var _ = root.telemetryTick
                                return channelVm ? ("Charge: " + channelVm.chargeAh.toFixed(8) + " Ah") : "Charge: --"
                            }
                            color: lightTheme ? "#23435D" : "#D2DCEB"
                            font.family: "Noto Sans Mono"
                            font.pixelSize: 15
                            elide: Text.ElideRight
                        }

                        Label {
                            text: {
                                var _ = root.telemetryTick
                                return channelVm ? ("Energy: " + channelVm.energyWh.toFixed(8) + " Wh") : "Energy: --"
                            }
                            color: lightTheme ? "#23435D" : "#D2DCEB"
                            font.family: "Noto Sans Mono"
                            font.pixelSize: 15
                            elide: Text.ElideRight
                        }

                        Label {
                            text: {
                                var _ = root.telemetryTick
                                return channelVm
                                    ? ("Meas V/I: " + channelVm.measuredVoltage.toFixed(3) + "V   " + channelVm.measuredCurrent.toFixed(4) + "A")
                                    : "Meas V/I: --"
                            }
                            color: lightTheme ? "#4F6E86" : "#9CB8D4"
                            font.family: "Noto Sans Mono"
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }

                        Label {
                            text: {
                                var _ = root.telemetryTick
                                return channelVm ? ("Meas P: " + channelVm.measuredPower.toFixed(3) + " W") : "Meas P: --"
                            }
                            color: lightTheme ? "#4F6E86" : "#9CB8D4"
                            font.family: "Noto Sans Mono"
                            font.pixelSize: 14
                            elide: Text.ElideRight
                        }
                    }
                }
            }
        }

        CollapsiblePanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: showEventPanel
            title: "Event Log"
            accentColor: "#8A734D"
            collapsed: false
            panelColor: lightTheme ? "#EEF6FD" : "#101925"
            borderColor: lightTheme ? "#B4CBDE" : "#2E4156"
            lightTheme: root.lightTheme

            Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 280
                radius: 6
                color: lightTheme ? "#F7FBFF" : "#070B10"
                border.width: 1
                border.color: lightTheme ? "#B2C8DA" : "#293B4E"

                ListView {
                    anchors.fill: parent
                    anchors.margins: 8
                    model: root.dashboard ? root.dashboard.logLinesModel : null
                    clip: true
                    spacing: 2

                    delegate: Text {
                        width: ListView.view ? ListView.view.width : parent.width
                        text: {
                            if (typeof modelData !== "undefined") {
                                return String(modelData)
                            }
                            if (typeof display !== "undefined") {
                                return String(display)
                            }
                            return ""
                        }
                        color: lightTheme ? "#2B5977" : "#9CD1FF"
                        font.family: "Noto Sans Mono"
                        font.pixelSize: 13
                        wrapMode: Text.WrapAnywhere
                    }

                    onCountChanged: positionViewAtEnd()
                }
            }
        }
    }
}




