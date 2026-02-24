/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\Main.qml
 * @brief Top-level application window and global UI composition.
 * @author Mouhsine Kassimi Farhaoui
 * @par Mail
 * mouhsine98@gmail.com
 */
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Controls.Material 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

import "components"
import "views"

ApplicationWindow {
    id: window
    width: 1800
    height: 980
    minimumWidth: 1320
    minimumHeight: 820
    visible: true
    title: "N6705 Power Console"
    font.family: "Noto Sans"

    property bool lightTheme: false

    Material.theme: lightTheme ? Material.Light : Material.Dark
    Material.accent: Material.Teal
    Material.primary: Material.BlueGrey

    readonly property color chassisBgTop: lightTheme ? "#EAF3FB" : "#0A1118"
    readonly property color chassisBgBottom: lightTheme ? "#DCEBF7" : "#111B27"
    readonly property color casePanel: lightTheme ? "#F3F8FD" : "#0F1823"
    readonly property color caseBorder: lightTheme ? "#A7C3DA" : "#2D4156"
    readonly property color displayBg: lightTheme ? "#EEF5FB" : "#090D12"
    readonly property color displayBorder: lightTheme ? "#A5C1D6" : "#1F2A35"
    readonly property color topBarBg: lightTheme ? "#EDF6FD" : "#111A26"
    readonly property color topBarBorder: lightTheme ? "#AFC7DA" : "#31485F"
    readonly property color topBarText: lightTheme ? "#17374E" : "#E2ECF8"
    readonly property color topBarMuted: lightTheme ? "#4F6F88" : "#9CB2CB"
    readonly property color channel1Color: "#D6D33A"
    readonly property color channel2Color: "#46CC5A"
    readonly property color channel3Color: "#39A8FF"
    readonly property color channel4Color: "#D15AF0"

    property int viewMode: 0 // 0 Meter, 1 Scope, 2 Data Logger, 3 Log Plot
    property bool singleOutputView: true
    property bool showLeftPanel: true
    property bool showRightPanel: true
    property bool showTrendPanel: true
    property bool showEventPanel: true
    property int telemetryTick: 0
    property QtObject dashboardVm: dashboard
    property bool introActive: true
    property real introProgress: 0.0
    property real introSweep: -0.35

    function channelColor(channel) {
        if (channel === 1) {
            return channel1Color
        }
        if (channel === 2) {
            return channel2Color
        }
        if (channel === 3) {
            return channel3Color
        }
        return channel4Color
    }

    function activeChannelVm() {
        return dashboard ? dashboard.channelVm(dashboard.chartChannel) : null
    }

    function selectChannel(channel) {
        if (!dashboard) {
            return
        }
        dashboard.chartChannel = channel
        dashboard.setChannelPolling(channel, true)
        clearMetricCharts()
    }

    function clearMetricCharts() {
        if (scopePane) {
            scopePane.clearCharts()
        }
    }

    function appendMetricsFromActiveVm() {
        var vm = activeChannelVm()
        if (!vm || !scopePane) {
            return
        }
        scopePane.appendFromVm(vm)
    }

    function setAllOutputs(state) {
        if (!dashboard) {
            return
        }
        for (var ch = 1; ch <= dashboard.channelCount; ch++) {
            dashboard.setChannelOutput(ch, state)
        }
    }

    function defaultCsvFileName() {
        var now = new Date()
        function pad(value) {
            return value < 10 ? ("0" + value) : String(value)
        }
        return "consumption_"
            + now.getFullYear()
            + pad(now.getMonth() + 1)
            + pad(now.getDate())
            + "_"
            + pad(now.getHours())
            + pad(now.getMinutes())
            + pad(now.getSeconds())
            + ".csv"
    }

    function ensureCsvExtension(pathValue) {
        var p = String(pathValue).trim()
        if (p === "") {
            return ""
        }
        if (!p.toLowerCase().endsWith(".csv")) {
            p = p + ".csv"
        }
        return p
    }

    function urlToLocalPath(urlValue) {
        var raw = String(urlValue)
        if (raw.indexOf("file://") === 0) {
            return decodeURIComponent(raw.substring(7))
        }
        return decodeURIComponent(raw)
    }

    function localPathToFileUrl(pathValue) {
        var p = String(pathValue || "").trim()
        if (p === "") {
            return ""
        }
        if (p.indexOf("file://") === 0) {
            return p
        }
        return "file://" + p
    }

    background: Rectangle {
        clip: true

        gradient: Gradient {
            GradientStop { position: 0.0; color: chassisBgTop }
            GradientStop { position: 1.0; color: chassisBgBottom }
        }

        Rectangle {
            id: glowOne
            width: 620
            height: 620
            radius: 310
            x: -180
            y: -220
            color: "#1A3A54"
            opacity: 0.28

            SequentialAnimation on x {
                loops: Animation.Infinite
                NumberAnimation { to: -120; duration: 6200; easing.type: Easing.InOutSine }
                NumberAnimation { to: -200; duration: 6200; easing.type: Easing.InOutSine }
            }
        }

        Rectangle {
            id: glowTwo
            width: 560
            height: 560
            radius: 280
            x: parent.width - 360
            y: parent.height - 320
            color: "#3E2455"
            opacity: 0.2

            SequentialAnimation on y {
                loops: Animation.Infinite
                NumberAnimation { to: window.height - 260; duration: 7000; easing.type: Easing.InOutSine }
                NumberAnimation { to: window.height - 340; duration: 7000; easing.type: Easing.InOutSine }
            }
        }
    }

    FileDialog {
        id: csvSaveDialog
        title: "Select logging CSV file"
        fileMode: FileDialog.SaveFile
        nameFilters: ["CSV files (*.csv)", "All files (*)"]
        defaultSuffix: "csv"
        options: FileDialog.DontUseNativeDialog

        onAccepted: {
            var localPath = window.ensureCsvExtension(window.urlToLocalPath(selectedFile))
            if (localPath === "") {
                return
            }
            logPathField.text = localPath
            if (dashboard) {
                dashboard.loggingPath = localPath
            }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            radius: 12
            color: topBarBg
            border.width: 1
            border.color: topBarBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 10

                Label {
                    text: "KEYSIGHT N6705"
                    color: topBarText
                    font.pixelSize: 22
                    font.bold: true
                }

                Rectangle {
                    implicitWidth: 180
                    implicitHeight: 30
                    radius: 6
                    color: dashboard && dashboard.connected ? "#DFF6E4" : "#F6E4E4"
                    border.width: 1
                    border.color: dashboard && dashboard.connected ? "#85C89A" : "#D4A1A1"

                    Label {
                        anchors.centerIn: parent
                        text: dashboard && dashboard.connected ? "REMOTE LINK ACTIVE" : "LOCAL / OFFLINE"
                        color: dashboard && dashboard.connected ? "#1A5B2A" : "#7A2323"
                        font.pixelSize: 11
                        font.bold: true
                    }
                }

                Label {
                    text: dashboard && dashboard.idn !== "--" ? dashboard.idn : "DC POWER ANALYZER"
                    color: topBarMuted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                    Layout.preferredWidth: 480
                }

                Item { Layout.fillWidth: true }

                Rectangle {
                    implicitWidth: 70
                    implicitHeight: 34
                    radius: 17
                    color: lightTheme ? "#FFE8A8" : "#233146"
                    border.width: 1
                    border.color: lightTheme ? "#E2BE56" : "#446089"

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: lightTheme = !lightTheme
                    }

                    Rectangle {
                        width: 28
                        height: 28
                        radius: 14
                        y: 3
                        x: lightTheme ? parent.width - width - 3 : 3
                        color: "#FFFFFF"
                        border.width: 1
                        border.color: lightTheme ? "#D7C07C" : "#8EA3BC"

                        Label {
                            anchors.centerIn: parent
                            text: lightTheme ? "☀" : "☾"
                            color: lightTheme ? "#D68A00" : "#294A79"
                            font.pixelSize: 14
                            font.bold: true
                        }

                        Behavior on x {
                            NumberAnimation { duration: 160; easing.type: Easing.InOutCubic }
                        }
                    }
                }

                Label {
                    text: dashboard ? dashboard.statusText : ""
                    color: topBarMuted
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                    Layout.preferredWidth: 520
                    wrapMode: Text.WrapAnywhere
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 66
            radius: 12
            color: topBarBg
            border.width: 1
            border.color: topBarBorder

            RowLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                Label {
                    text: "Measure"
                    color: topBarMuted
                    font.bold: true
                    font.pixelSize: 12
                }

                Button {
                    checkable: true
                    checked: viewMode === 0
                    text: "Meter View"
                    onClicked: viewMode = 0
                    background: Rectangle {
                        radius: 8
                        color: viewMode === 0
                            ? (lightTheme ? "#1D7D8A" : "#1F5E66")
                            : (lightTheme ? "#E7F1FA" : "#1A2838")
                        border.width: 1
                        border.color: viewMode === 0
                            ? (lightTheme ? "#2A8D9A" : "#3A9AA6")
                            : (lightTheme ? "#9EBBD2" : "#31495F")
                    }
                    contentItem: Label {
                        text: parent.text
                        color: viewMode === 0 ? "#EAF6FF" : (lightTheme ? "#1E3C52" : "#E7F0FA")
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    checkable: true
                    checked: viewMode === 1
                    text: "Scope View"
                    onClicked: viewMode = 1
                    background: Rectangle {
                        radius: 8
                        color: viewMode === 1
                            ? (lightTheme ? "#1D7D8A" : "#1F5E66")
                            : (lightTheme ? "#E7F1FA" : "#1A2838")
                        border.width: 1
                        border.color: viewMode === 1
                            ? (lightTheme ? "#2A8D9A" : "#3A9AA6")
                            : (lightTheme ? "#9EBBD2" : "#31495F")
                    }
                    contentItem: Label {
                        text: parent.text
                        color: viewMode === 1 ? "#EAF6FF" : (lightTheme ? "#1E3C52" : "#E7F0FA")
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    checkable: true
                    checked: viewMode === 2
                    text: "Data Logger"
                    onClicked: viewMode = 2
                    background: Rectangle {
                        radius: 8
                        color: viewMode === 2
                            ? (lightTheme ? "#1D7D8A" : "#1F5E66")
                            : (lightTheme ? "#E7F1FA" : "#1A2838")
                        border.width: 1
                        border.color: viewMode === 2
                            ? (lightTheme ? "#2A8D9A" : "#3A9AA6")
                            : (lightTheme ? "#9EBBD2" : "#31495F")
                    }
                    contentItem: Label {
                        text: parent.text
                        color: viewMode === 2 ? "#EAF6FF" : (lightTheme ? "#1E3C52" : "#E7F0FA")
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Button {
                    checkable: true
                    checked: viewMode === 3
                    text: "Log Plot"
                    onClicked: viewMode = 3
                    background: Rectangle {
                        radius: 8
                        color: viewMode === 3
                            ? (lightTheme ? "#1D7D8A" : "#1F5E66")
                            : (lightTheme ? "#E7F1FA" : "#1A2838")
                        border.width: 1
                        border.color: viewMode === 3
                            ? (lightTheme ? "#2A8D9A" : "#3A9AA6")
                            : (lightTheme ? "#9EBBD2" : "#31495F")
                    }
                    contentItem: Label {
                        text: parent.text
                        color: viewMode === 3 ? "#EAF6FF" : (lightTheme ? "#1E3C52" : "#E7F0FA")
                        font.bold: true
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: lightTheme ? "#AFC6D9" : "#324A60"
                }

                Button {
                    text: showLeftPanel ? "Hide Left" : "Show Left"
                    onClicked: showLeftPanel = !showLeftPanel
                }

                Button {
                    text: showRightPanel ? "Hide Right" : "Show Right"
                    onClicked: showRightPanel = !showRightPanel
                }

                Button {
                    text: singleOutputView ? "All Outputs" : "Single Output"
                    visible: viewMode === 0
                    onClicked: singleOutputView = !singleOutputView
                }

                Item { Layout.fillWidth: true }

                Label {
                    text: dashboard && dashboard.monitoring ? "RUNNING" : "STOPPED"
                    color: dashboard && dashboard.monitoring ? "#2E7D32" : "#9A3412"
                    font.pixelSize: 12
                    font.bold: true
                }
            }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 10

            Rectangle {
                visible: showLeftPanel
                enabled: showLeftPanel
                Layout.preferredWidth: showLeftPanel ? 290 : 0
                Layout.minimumWidth: showLeftPanel ? 290 : 0
                Layout.maximumWidth: showLeftPanel ? 290 : 0
                Layout.fillHeight: true
                radius: 12
                color: casePanel
                border.width: 1
                border.color: caseBorder

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 70
                        radius: 10
                        color: lightTheme ? "#EAF4FD" : "#111E2D"
                        border.width: 1
                        border.color: lightTheme ? "#B4CBDE" : "#35506A"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 2

                                Label {
                                    text: "Output Control"
                                    color: lightTheme ? "#17374E" : "#DFECFA"
                                    font.bold: true
                                    font.pixelSize: 14
                                }

                                Label {
                                    text: dashboard ? ("Selected CH" + dashboard.chartChannel) : "Selected CH--"
                                    color: lightTheme ? "#4F6E86" : "#AFC7DF"
                                    font.pixelSize: 11
                                }
                            }

                            Rectangle {
                                implicitWidth: 90
                                implicitHeight: 24
                                radius: 5
                                color: dashboard && dashboard.monitoring ? "#184834" : "#4A2B1E"
                                border.width: 1
                                border.color: dashboard && dashboard.monitoring ? "#2D8C64" : "#915739"

                                Label {
                                    anchors.centerIn: parent
                                    text: dashboard && dashboard.monitoring ? "RUNNING" : "STOPPED"
                                    color: dashboard && dashboard.monitoring ? "#89F1C6" : "#F4B88F"
                                    font.pixelSize: 10
                                    font.bold: true
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 122
                        radius: 10
                        color: lightTheme ? "#EFF7FE" : "#0F1A27"
                        border.width: 1
                        border.color: lightTheme ? "#B4CBDE" : "#304A62"

                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8

                            Repeater {
                                model: dashboard ? dashboard.channelCount : 4

                                delegate: Button {
                                    readonly property int channelNumber: index + 1
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 46
                                    text: "OUTPUT " + channelNumber
                                    onClicked: selectChannel(channelNumber)

                                    background: Rectangle {
                                        radius: 8
                                        color: dashboard && dashboard.chartChannel === channelNumber
                                            ? Qt.lighter(channelColor(channelNumber), 1.1)
                                            : (lightTheme ? "#E8F2FB" : "#162637")
                                        border.width: 1
                                        border.color: dashboard && dashboard.chartChannel === channelNumber
                                            ? channelColor(channelNumber)
                                            : (lightTheme ? "#AFC6D9" : "#395772")
                                    }

                                    contentItem: Label {
                                        text: parent.text
                                        color: dashboard && dashboard.chartChannel === channelNumber
                                            ? "#111A24"
                                            : (lightTheme ? "#1B3B52" : "#DCEAF9")
                                        font.bold: true
                                        font.pixelSize: 12
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                    }
                                }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 116
                        radius: 10
                        color: lightTheme ? "#EFF7FE" : "#0F1A27"
                        border.width: 1
                        border.color: lightTheme ? "#B4CBDE" : "#304A62"

                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8

                            Button {
                                Layout.fillWidth: true
                                text: "Sel ON"
                                onClicked: {
                                    if (dashboard) {
                                        dashboard.setChannelOutput(dashboard.chartChannel, true)
                                    }
                                }
                            }

                            Button {
                                Layout.fillWidth: true
                                text: "Sel OFF"
                                onClicked: {
                                    if (dashboard) {
                                        dashboard.setChannelOutput(dashboard.chartChannel, false)
                                    }
                                }
                            }

                            Button {
                                Layout.fillWidth: true
                                text: "All ON"
                                onClicked: setAllOutputs(true)
                            }

                            Button {
                                Layout.fillWidth: true
                                text: "All OFF"
                                onClicked: setAllOutputs(false)
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 92
                        radius: 10
                        color: lightTheme ? "#EFF7FE" : "#0F1A27"
                        border.width: 1
                        border.color: lightTheme ? "#B4CBDE" : "#304A62"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: "Run"
                                enabled: dashboard && dashboard.connected && !dashboard.monitoring
                                onClicked: dashboard.startMonitoring()
                            }

                            Button {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                text: "Stop"
                                enabled: dashboard && dashboard.monitoring
                                onClicked: dashboard.stopMonitoring()
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }

                    Label {
                        Layout.fillWidth: true
                        text: "Compact panel: no scroll required"
                        color: lightTheme ? "#4F6E86" : "#7FA0BF"
                        font.pixelSize: 10
                        horizontalAlignment: Text.AlignHCenter
                    }
                }
            }

                Rectangle {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: 16
                color: lightTheme ? "#EFF7FE" : "#121922"
                border.width: 2
                border.color: lightTheme ? "#AFC6D9" : "#3A4756"

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: 7
                        color: lightTheme ? "#EAF4FD" : "#1A2430"
                        border.width: 1
                        border.color: lightTheme ? "#B4CBDE" : "#2D3B4A"

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 10

                            Label {
                                text: "Display: "
                                    + (viewMode === 0
                                        ? "Meter"
                                        : (viewMode === 1
                                            ? "Scope"
                                            : (viewMode === 2 ? "Data Logger" : "Log Plot")))
                                color: lightTheme ? "#15354B" : "#E5EBF5"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            Label {
                                text: dashboard ? ("Selected Output: " + dashboard.chartChannel) : "Selected Output: --"
                                color: lightTheme ? "#4F6E86" : "#9FB0C7"
                                font.pixelSize: 12
                            }

                            Item { Layout.fillWidth: true }

                            Label {
                                text: dashboard && dashboard.connected ? "LAN" : "NO LINK"
                                color: dashboard && dashboard.connected ? "#7EE39C" : "#E3A57E"
                                font.pixelSize: 12
                                font.bold: true
                            }
                        }
                    }

                    StackLayout {
                        id: centerStack
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        currentIndex: viewMode

                        MeterViewPane {
                            id: meterPane
                            dashboard: window.dashboardVm
                            singleOutputView: window.singleOutputView
                            telemetryTick: window.telemetryTick
                            lightTheme: window.lightTheme
                        }

                        ScopeViewPane {
                            id: scopePane
                            dashboard: window.dashboardVm
                            showTrendPanel: window.showTrendPanel
                            lightTheme: window.lightTheme
                        }

                        DataLoggerPane {
                            id: loggerPane
                            dashboard: window.dashboardVm
                            showEventPanel: window.showEventPanel
                            telemetryTick: window.telemetryTick
                            lightTheme: window.lightTheme
                        }

                        LogPlotPane {
                            id: logPlotPane
                            dashboard: window.dashboardVm
                            lightTheme: window.lightTheme
                        }
                    }
                }
            }

            Rectangle {
                visible: showRightPanel
                enabled: showRightPanel
                Layout.preferredWidth: showRightPanel ? 350 : 0
                Layout.minimumWidth: showRightPanel ? 350 : 0
                Layout.maximumWidth: showRightPanel ? 350 : 0
                Layout.fillHeight: true
                radius: 12
                    color: casePanel
                    border.width: 1
                    border.color: caseBorder

                ScrollView {
                    id: rightPanelScroll
                    anchors.fill: parent
                    anchors.margins: 8
                    clip: true
                    contentWidth: availableWidth
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded

                    ColumnLayout {
                        width: rightPanelScroll.availableWidth
                        spacing: 8

                        CollapsiblePanel {
                            Layout.fillWidth: true
                            title: "Connection Properties"
                            accentColor: "#5A7390"
                            collapsed: false
                            lightTheme: window.lightTheme
                            panelColor: lightTheme ? "#EEF6FD" : "#111A25"
                            borderColor: lightTheme ? "#B4CBDE" : "#2F4359"

                            TextField {
                                id: hostField
                                Layout.fillWidth: true
                                placeholderText: "Host/IP"
                                text: dashboard ? dashboard.connectionHost : ""
                                onEditingFinished: {
                                    if (dashboard) {
                                        dashboard.setConnectionParams(text, Number(portField.text), Number(timeoutField.text))
                                    }
                                }
                            }

                            Button {
                                Layout.fillWidth: true
                                text: "Use PSU IP 192.168.6.59"
                                onClicked: {
                                    hostField.text = "192.168.6.59"
                                    if (dashboard) {
                                        dashboard.setConnectionParams("192.168.6.59", Number(portField.text), Number(timeoutField.text))
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                TextField {
                                    id: portField
                                    Layout.fillWidth: true
                                    placeholderText: "Port"
                                    text: dashboard ? String(dashboard.connectionPort) : "5025"
                                    onEditingFinished: {
                                        if (dashboard) {
                                            dashboard.setConnectionParams(hostField.text, Number(text), Number(timeoutField.text))
                                        }
                                    }
                                }

                                TextField {
                                    id: timeoutField
                                    Layout.fillWidth: true
                                    placeholderText: "Timeout"
                                    text: dashboard ? Number(dashboard.connectionTimeout).toFixed(2) : "3.00"
                                    onEditingFinished: {
                                        if (dashboard) {
                                            dashboard.setConnectionParams(hostField.text, Number(portField.text), Number(text))
                                        }
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Button {
                                    text: "Connect"
                                    Layout.fillWidth: true
                                    enabled: dashboard && !dashboard.connected && !dashboard.connecting
                                    onClicked: dashboard.connectDevice(hostField.text, Number(portField.text), Number(timeoutField.text))
                                }

                                Button {
                                    text: "Disconnect"
                                    Layout.fillWidth: true
                                    enabled: dashboard && dashboard.connected && !dashboard.connecting
                                    onClicked: dashboard.disconnectDevice()
                                }
                            }

                            Label {
                                Layout.fillWidth: true
                                text: dashboard && dashboard.connecting ? "Connecting... please wait" : ""
                                color: "#F5C084"
                                font.pixelSize: 11
                                visible: text !== ""
                            }
                        }

                        CollapsiblePanel {
                            Layout.fillWidth: true
                            title: "Measurement / Logger"
                            accentColor: "#507A68"
                            collapsed: false
                            lightTheme: window.lightTheme
                            panelColor: lightTheme ? "#EEF6FD" : "#111A25"
                            borderColor: lightTheme ? "#B4CBDE" : "#2F4359"

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                TextField {
                                    id: intervalField
                                    Layout.fillWidth: true
                                    placeholderText: "Interval (s)"
                                    text: dashboard ? Number(dashboard.pollInterval).toFixed(2) : "1.00"
                                    onEditingFinished: {
                                        if (dashboard) {
                                            dashboard.setPollInterval(Number(text))
                                            hzField.text = Number(dashboard.pollFrequency).toFixed(2)
                                        }
                                    }
                                }

                                TextField {
                                    id: hzField
                                    Layout.fillWidth: true
                                    placeholderText: "Frequency (Hz)"
                                    text: dashboard ? Number(dashboard.pollFrequency).toFixed(2) : "1.00"
                                    onEditingFinished: {
                                        if (dashboard) {
                                            dashboard.setPollFrequency(Number(text))
                                            intervalField.text = Number(dashboard.pollInterval).toFixed(2)
                                            text = Number(dashboard.pollFrequency).toFixed(2)
                                        }
                                    }
                                }
                            }

                            Label {
                                text: "CSV File Path"
                                color: lightTheme ? "#35536A" : "#C3D5EA"
                                font.pixelSize: 12
                                font.bold: true
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                TextField {
                                    id: logPathField
                                    Layout.fillWidth: true
                                    placeholderText: "Select or type a CSV path"
                                    text: dashboard ? dashboard.loggingPath : ""
                                    onEditingFinished: {
                                        var normalized = window.ensureCsvExtension(text)
                                        text = normalized
                                        if (dashboard && normalized !== "") {
                                            dashboard.loggingPath = normalized
                                        }
                                    }
                                }

                                Button {
                                    text: "Browse..."
                                    onClicked: {
                                        var candidate = window.ensureCsvExtension(
                                            logPathField.text === "" ? ("logs/" + window.defaultCsvFileName()) : logPathField.text
                                        )
                                        csvSaveDialog.currentFile = window.localPathToFileUrl(candidate)
                                        csvSaveDialog.open()
                                    }
                                }
                            }

                            Button {
                                Layout.fillWidth: true
                                text: "Auto Generate CSV Name"
                                onClicked: {
                                    var current = String(logPathField.text).trim()
                                    var baseDir = "logs"
                                    var slashIndex = Math.max(current.lastIndexOf("/"), current.lastIndexOf("\\"))
                                    if (slashIndex >= 0) {
                                        baseDir = current.substring(0, slashIndex)
                                    }
                                    var generated = baseDir + "/" + window.defaultCsvFileName()
                                    logPathField.text = generated
                                    if (dashboard) {
                                        dashboard.loggingPath = generated
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Button {
                                    Layout.fillWidth: true
                                    text: "Start Log"
                                    enabled: dashboard && dashboard.connected && !dashboard.loggingActive
                                    onClicked: {
                                        if (dashboard) {
                                            var candidate = window.ensureCsvExtension(logPathField.text)
                                            if (candidate === "") {
                                                candidate = "logs/" + window.defaultCsvFileName()
                                            }
                                            logPathField.text = candidate
                                            dashboard.loggingPath = candidate
                                            dashboard.startLogging()
                                        }
                                    }
                                }

                                Button {
                                    Layout.fillWidth: true
                                    text: "Stop Log"
                                    enabled: dashboard && dashboard.loggingActive
                                    onClicked: dashboard.stopLogging()
                                }
                            }
                        }

                        CollapsiblePanel {
                            Layout.fillWidth: true
                            title: "Display Options"
                            accentColor: "#8A6E44"
                            collapsed: false
                            lightTheme: window.lightTheme
                            panelColor: lightTheme ? "#EEF6FD" : "#111A25"
                            borderColor: lightTheme ? "#B4CBDE" : "#2F4359"

                            Switch {
                                text: checked ? "Left panel visible" : "Left panel hidden"
                                checked: showLeftPanel
                                onToggled: showLeftPanel = checked
                            }

                            Switch {
                                text: checked ? "Right panel visible" : "Right panel hidden"
                                checked: showRightPanel
                                onToggled: showRightPanel = checked
                            }

                            Switch {
                                text: checked ? "Trend visible" : "Trend hidden"
                                checked: showTrendPanel
                                onToggled: showTrendPanel = checked
                            }

                            Switch {
                                text: checked ? "Event log visible" : "Event log hidden"
                                checked: showEventPanel
                                onToggled: showEventPanel = checked
                            }
                        }
                    }
                }
            }
        }
    }

    Rectangle {
        id: startupOverlay
        anchors.fill: parent
        z: 200
        visible: introActive
        color: "#040A12"
        opacity: introActive ? 1.0 : 0.0

        gradient: Gradient {
            GradientStop { position: 0.0; color: "#081A2E" }
            GradientStop { position: 1.0; color: "#040A12" }
        }

        MouseArea {
            anchors.fill: parent
            enabled: introActive
        }

        Rectangle {
            id: bootPanel
            width: Math.min(parent.width * 0.68, 1040)
            height: Math.min(parent.height * 0.54, 480)
            anchors.centerIn: parent
            radius: 24
            color: "#0B1D30"
            border.width: 2
            border.color: "#2A6E98"
            opacity: 0.0
            scale: 0.94

            Rectangle {
                anchors.fill: parent
                anchors.margins: 10
                radius: 18
                color: "#0A2138"
                border.width: 1
                border.color: "#1D4B69"
            }

            Rectangle {
                id: sweepLine
                width: 120
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                x: parent.width * introSweep
                color: "#77E7FF"
                opacity: 0.08
                radius: 12
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 28
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 20
                        height: 20
                        radius: 10
                        color: "#53E3FF"
                    }

                    Label {
                        text: "N6705 POWER CONSOLE"
                        color: "#D8ECFF"
                        font.pixelSize: 28
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: "BOOT SEQUENCE"
                        color: "#7FB4D7"
                        font.pixelSize: 12
                        font.bold: true
                    }
                }

                Label {
                    Layout.fillWidth: true
                    text: "Made by: Mouhsine Kassimi Farhaoui"
                    color: "#8CB7D8"
                    font.pixelSize: 12
                    horizontalAlignment: Text.AlignRight
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 214
                    radius: 14
                    color: "#071B2E"
                    border.width: 1
                    border.color: "#1D4B69"

                    Item {
                        anchors.fill: parent
                        anchors.margins: 10

                        Repeater {
                            model: 6
                            delegate: Rectangle {
                                width: parent.width
                                height: 1
                                y: index * (parent.height / 5)
                                color: "#3F789D"
                                opacity: 0.22
                            }
                        }

                        Repeater {
                            model: 8
                            delegate: Rectangle {
                                width: 1
                                height: parent.height
                                x: index * (parent.width / 7)
                                color: "#3F789D"
                                opacity: 0.22
                            }
                        }

                        Canvas {
                            id: bootWaveCanvas
                            anchors.fill: parent
                            onPaint: {
                                if (!startupOverlay.visible || width <= 2 || height <= 2) {
                                    return
                                }
                                var ctx = getContext("2d")
                                ctx.clearRect(0, 0, width, height)
                                ctx.lineWidth = 6
                                ctx.lineJoin = "round"
                                ctx.lineCap = "round"
                                var grad = ctx.createLinearGradient(0, 0, width, 0)
                                grad.addColorStop(0, "#52E6FF")
                                grad.addColorStop(1, "#00B5D7")
                                ctx.strokeStyle = grad
                                var p = Math.max(0.08, introProgress)
                                ctx.beginPath()
                                ctx.moveTo(width * 0.03, height * 0.74)
                                ctx.lineTo(width * (0.14 + p * 0.05), height * 0.68)
                                ctx.lineTo(width * (0.27 + p * 0.06), height * 0.42)
                                ctx.lineTo(width * (0.39 + p * 0.05), height * 0.54)
                                ctx.lineTo(width * (0.52 + p * 0.05), height * 0.30)
                                ctx.lineTo(width * (0.65 + p * 0.06), height * 0.43)
                                ctx.lineTo(width * (0.79 + p * 0.04), height * 0.33)
                                ctx.lineTo(width * (0.93), height * 0.39)
                                ctx.stroke()
                            }

                            Connections {
                                target: window
                                function onIntroProgressChanged() {
                                    if (startupOverlay.visible) {
                                        bootWaveCanvas.requestPaint()
                                    }
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Label {
                        text: "Initializing channels"
                        color: "#AFCDE6"
                        font.pixelSize: 13
                    }

                    Item { Layout.fillWidth: true }

                    Label {
                        text: Math.round(introProgress * 100) + "%"
                        color: "#6DE8FF"
                        font.pixelSize: 13
                        font.bold: true
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 16
                    radius: 8
                    color: "#112A3F"
                    border.width: 1
                    border.color: "#22587A"

                    Rectangle {
                        width: Math.max(10, (parent.width - 2) * introProgress)
                        height: parent.height - 2
                        x: 1
                        y: 1
                        radius: 7
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: "#4FE6FF" }
                            GradientStop { position: 1.0; color: "#00B5D7" }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: 4
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 9
                            radius: 4
                            color: {
                                if (index === 0) return "#D6D33A"
                                if (index === 1) return "#46CC5A"
                                if (index === 2) return "#39A8FF"
                                return "#D15AF0"
                            }
                            opacity: introProgress > ((index + 1) * 0.18) ? 0.95 : 0.22
                        }
                    }
                }
            }
        }

        SequentialAnimation {
            id: bootSequence
            running: introActive

            ParallelAnimation {
                NumberAnimation {
                    target: bootPanel
                    property: "opacity"
                    from: 0.0
                    to: 1.0
                    duration: 360
                    easing.type: Easing.OutCubic
                }
                NumberAnimation {
                    target: bootPanel
                    property: "scale"
                    from: 0.94
                    to: 1.0
                    duration: 480
                    easing.type: Easing.OutBack
                }
            }

            PauseAnimation { duration: 80 }

            ParallelAnimation {
                NumberAnimation {
                    target: window
                    property: "introProgress"
                    from: 0.0
                    to: 1.0
                    duration: 1900
                    easing.type: Easing.InOutCubic
                }
                NumberAnimation {
                    target: window
                    property: "introSweep"
                    from: -0.35
                    to: 1.2
                    duration: 1900
                    easing.type: Easing.InOutQuad
                }
            }

            PauseAnimation { duration: 180 }

            NumberAnimation {
                target: startupOverlay
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 460
                easing.type: Easing.InOutQuad
            }

            ScriptAction {
                script: {
                    window.introActive = false
                }
            }
        }
    }

    Connections {
        target: dashboard ? dashboard.channelVm(dashboard.chartChannel) : null

        function onDataChanged() {
            if (viewMode === 1 && showTrendPanel) {
                appendMetricsFromActiveVm()
            }
        }
    }

    Connections {
        target: dashboard

        function onChartSelectionChanged() {
            clearMetricCharts()
        }

        function onMonitoringChanged() {
            if (dashboard.monitoring) {
                clearMetricCharts()
            }
        }

        function onSessionChanged() {
            if (!hostField.activeFocus) {
                hostField.text = dashboard.connectionHost
            }
            if (!portField.activeFocus) {
                portField.text = String(dashboard.connectionPort)
            }
            if (!timeoutField.activeFocus) {
                timeoutField.text = Number(dashboard.connectionTimeout).toFixed(2)
            }
            if (!intervalField.activeFocus) {
                intervalField.text = Number(dashboard.pollInterval).toFixed(2)
            }
            if (!hzField.activeFocus) {
                hzField.text = Number(dashboard.pollFrequency).toFixed(2)
            }
        }

        function onLoggingChanged() {
            if (!logPathField.activeFocus) {
                logPathField.text = dashboard.loggingPath
            }
        }

        function onTelemetryChanged() {
            telemetryTick = telemetryTick + 1
        }
    }
}




