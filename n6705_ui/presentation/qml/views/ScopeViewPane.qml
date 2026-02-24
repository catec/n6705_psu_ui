/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\views\ScopeViewPane.qml
 * @brief Oscilloscope-like view for live trend visualization.
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
    property bool showTrendPanel: true

    function clearCharts() {
        voltageChart.clearSeries()
        currentChart.clearSeries()
        powerChart.clearSeries()
        chargeChart.clearSeries()
        energyChart.clearSeries()
    }

    function appendFromVm(vm) {
        if (!vm) {
            return
        }
        voltageChart.appendPoint(vm.lastElapsedS, vm.measuredVoltage)
        currentChart.appendPoint(vm.lastElapsedS, vm.measuredCurrent)
        powerChart.appendPoint(vm.lastElapsedS, vm.measuredPower)
        chargeChart.appendPoint(vm.lastElapsedS, vm.chargeAh)
        energyChart.appendPoint(vm.lastElapsedS, vm.energyWh)
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: lightTheme ? "#EFF7FE" : "#060A10"
        border.width: 1
        border.color: lightTheme ? "#B2C9DB" : "#223040"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 52
            radius: 6
            color: lightTheme ? "#EAF4FD" : "#101A26"
            border.width: 1
            border.color: lightTheme ? "#B4CBDE" : "#243548"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 10

                Label {
                    text: "Scope View"
                    color: lightTheme ? "#16364C" : "#E2EAF7"
                    font.pixelSize: 13
                    font.bold: true
                }

                Rectangle {
                    implicitWidth: 94
                    implicitHeight: 24
                    radius: 4
                    color: root.dashboard && root.dashboard.monitoring ? "#173725" : "#3A2415"
                    border.width: 1
                    border.color: root.dashboard && root.dashboard.monitoring ? "#2B7B53" : "#8B4D24"

                    Label {
                        anchors.centerIn: parent
                        text: root.dashboard && root.dashboard.monitoring ? "RUNNING" : "IDLE"
                        color: root.dashboard && root.dashboard.monitoring ? "#7CE6B2" : "#F2B07D"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Label {
                    text: root.dashboard ? ("CH" + root.dashboard.chartChannel + " trace set") : ""
                    color: lightTheme ? "#516F87" : "#95A9C3"
                    font.pixelSize: 11
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: root.dashboard
                        ? ("Time/Div " + Math.max(0.1, (root.dashboard.axisMax - root.dashboard.axisMin) / 10.0).toFixed(2) + " s")
                        : ""
                    color: lightTheme ? "#4F6E86" : "#A6BAD2"
                    font.pixelSize: 11
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Repeater {
                model: root.dashboard ? root.dashboard.channelCount : 4
                delegate: Rectangle {
                    readonly property int channelNumber: index + 1
                    Layout.fillWidth: true
                    implicitHeight: 30
                    radius: 5
                    color: channelNumber === 1 ? "#D6D33A" : (channelNumber === 2 ? "#46CC5A" : (channelNumber === 3 ? "#39A8FF" : "#D15AF0"))
                    border.width: 1
                    border.color: Qt.darker(color, 1.35)

                    Label {
                        anchors.centerIn: parent
                        text: root.dashboard
                            ? ("CH" + channelNumber + "  " + root.dashboard.channelVm(channelNumber).measuredVoltage.toFixed(2) + "V")
                            : ("CH" + channelNumber)
                        color: "#0B0F14"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }
            }
        }

        ScrollView {
            id: chartsScroll
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: showTrendPanel
            clip: true
            contentWidth: availableWidth

            ColumnLayout {
                width: chartsScroll.availableWidth
                spacing: 8

                MetricChart {
                    id: voltageChart
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    title: "Voltage Trace"
                    unit: "V"
                    seriesColor: "#00C4FF"
                    axisMinX: root.dashboard ? root.dashboard.axisMin : 0
                    axisMaxX: root.dashboard ? root.dashboard.axisMax : 60
                    lightTheme: root.lightTheme
                }

                MetricChart {
                    id: currentChart
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    title: "Current Trace"
                    unit: "A"
                    seriesColor: "#FFC15A"
                    axisMinX: root.dashboard ? root.dashboard.axisMin : 0
                    axisMaxX: root.dashboard ? root.dashboard.axisMax : 60
                    lightTheme: root.lightTheme
                }

                MetricChart {
                    id: powerChart
                    Layout.fillWidth: true
                    Layout.preferredHeight: 180
                    title: "Power Trace"
                    unit: "W"
                    seriesColor: "#7CF7BA"
                    axisMinX: root.dashboard ? root.dashboard.axisMin : 0
                    axisMaxX: root.dashboard ? root.dashboard.axisMax : 60
                    lightTheme: root.lightTheme
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    MetricChart {
                        id: chargeChart
                        Layout.fillWidth: true
                        Layout.preferredHeight: 160
                        title: "Charge Consumption"
                        unit: "Ah"
                        seriesColor: "#6FB1FF"
                        axisMinX: root.dashboard ? root.dashboard.axisMin : 0
                        axisMaxX: root.dashboard ? root.dashboard.axisMax : 60
                        lightTheme: root.lightTheme
                    }

                    MetricChart {
                        id: energyChart
                        Layout.fillWidth: true
                        Layout.preferredHeight: 160
                        title: "Energy Consumption"
                        unit: "Wh"
                        seriesColor: "#9AF17C"
                        axisMinX: root.dashboard ? root.dashboard.axisMin : 0
                        axisMaxX: root.dashboard ? root.dashboard.axisMax : 60
                        lightTheme: root.lightTheme
                    }
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            visible: !showTrendPanel
            radius: 8
            color: lightTheme ? "#E8F2FB" : "#141E2A"
            border.width: 1
            border.color: lightTheme ? "#B3CADC" : "#30455C"

            Label {
                anchors.centerIn: parent
                text: "Trend panel is hidden from Display Options"
                color: lightTheme ? "#4F6E86" : "#95ACC8"
                font.pixelSize: 13
            }
        }
    }
}




