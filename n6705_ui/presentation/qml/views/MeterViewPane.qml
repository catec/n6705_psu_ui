/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\views\MeterViewPane.qml
 * @brief Meter-style operational view for live channel control.
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
    property bool singleOutputView: true
    property int telemetryTick: 0
    property var selectedVm: root.dashboard ? root.dashboard.channelVm(root.dashboard.chartChannel) : null

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: lightTheme ? "#F0F7FE" : "#080D13"
        border.width: 1
        border.color: lightTheme ? "#AFC5D8" : "#223041"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 34
            radius: 6
            color: lightTheme ? "#EAF4FD" : "#0F1722"
            border.width: 1
            border.color: lightTheme ? "#B4CBDE" : "#24374A"

            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Label {
                    text: root.singleOutputView ? "Single Output Meter View" : "All Outputs Meter View"
                    color: lightTheme ? "#15354B" : "#DDE7F5"
                    font.pixelSize: 12
                    font.bold: true
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: root.dashboard ? ("Selected CH" + root.dashboard.chartChannel) : ""
                    color: lightTheme ? "#4D6D86" : "#8FA6C2"
                    font.pixelSize: 12
                }
            }
        }

        Item {
            id: contentHost
            Layout.fillWidth: true
            Layout.fillHeight: true

            ChannelScreen {
                anchors.fill: parent
                visible: root.singleOutputView
                channelVm: root.selectedVm
                dashboard: root.dashboard
                telemetryTick: root.telemetryTick
                lightTheme: root.lightTheme
            }

            ScrollView {
                anchors.fill: parent
                visible: !root.singleOutputView
                clip: true

                ColumnLayout {
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: root.dashboard ? root.dashboard.channelCount : 4
                        delegate: MiniMeterStrip {
                            Layout.fillWidth: true
                            channelVm: root.dashboard ? root.dashboard.channelVm(index + 1) : null
                            telemetryTick: root.telemetryTick
                            lightTheme: root.lightTheme
                        }
                    }
                }
            }
        }
    }
}




