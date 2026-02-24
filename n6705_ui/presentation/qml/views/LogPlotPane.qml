/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\views\LogPlotPane.qml
 * @brief Historical log plotting and export view.
 * @author Mouhsine Kassimi Farhaoui
 * @par Mail
 * mouhsine98@gmail.com
 */
// Signature: mkassimi
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Dialogs

import "../components"

Item {
    id: root
    property var dashboard
    property bool lightTheme: false
    property bool ch1Enabled: true
    property bool ch2Enabled: true
    property bool ch3Enabled: true
    property bool ch4Enabled: true
    property bool showVoltageChart: true
    property bool showCurrentChart: true
    property bool showPowerChart: true
    property bool showChargeChart: true
    property bool showEnergyChart: true
    property bool showLegend: true
    property real strokeWidth: 1.6

    function setAllChannels(state) {
        var enabled = Boolean(state)
        ch1Enabled = enabled
        ch2Enabled = enabled
        ch3Enabled = enabled
        ch4Enabled = enabled
    }

    function setAllMetrics(state) {
        var enabled = Boolean(state)
        showVoltageChart = enabled
        showCurrentChart = enabled
        showPowerChart = enabled
        showChargeChart = enabled
        showEnergyChart = enabled
    }

    function channelEnabled(channel) {
        if (channel === 1) {
            return ch1Enabled
        }
        if (channel === 2) {
            return ch2Enabled
        }
        if (channel === 3) {
            return ch3Enabled
        }
        if (channel === 4) {
            return ch4Enabled
        }
        return false
    }

    function filteredSeries(rawSeries) {
        var list = rawSeries || []
        var out = []
        for (var i = 0; i < list.length; i++) {
            var series = list[i]
            if (channelEnabled(Number(series.channel))) {
                out.push(series)
            }
        }
        return out
    }

    function _statsObject(seriesList) {
        var totalCount = 0
        var minV = 0
        var maxV = 0
        var sumV = 0
        var found = false
        var lastY = 0
        var lastX = -1e100

        for (var i = 0; i < seriesList.length; i++) {
            var points = seriesList[i].points || []
            for (var j = 0; j < points.length; j++) {
                var x = Number(points[j].x)
                var y = Number(points[j].y)
                if (!Number.isFinite(x) || !Number.isFinite(y)) {
                    continue
                }

                if (!found) {
                    minV = y
                    maxV = y
                    found = true
                } else {
                    if (y < minV) {
                        minV = y
                    }
                    if (y > maxV) {
                        maxV = y
                    }
                }
                if (x >= lastX) {
                    lastX = x
                    lastY = y
                }
                sumV += y
                totalCount += 1
            }
        }

        if (!found || totalCount <= 0) {
            return {"count": 0, "min": 0, "max": 0, "avg": 0, "last": 0}
        }

        return {
            "count": totalCount,
            "min": minV,
            "max": maxV,
            "avg": sumV / totalCount,
            "last": lastY
        }
    }

    function _formatValue(value, decimals) {
        if (!Number.isFinite(value)) {
            return "--"
        }
        var d = Math.max(0, Number(decimals))
        if (Math.abs(value) > 0 && Math.abs(value) < 1e-3) {
            return value.toExponential(2)
        }
        return value.toFixed(d)
    }

    function statsSummary(seriesList, unit, decimals) {
        var stats = _statsObject(seriesList)
        if (stats.count <= 0) {
            return "No data"
        }
        return "n=" + stats.count
            + " | min " + _formatValue(stats.min, decimals) + unit
            + " | max " + _formatValue(stats.max, decimals) + unit
            + " | avg " + _formatValue(stats.avg, decimals) + unit
            + " | last " + _formatValue(stats.last, decimals) + unit
    }

    function activeChannelsText() {
        var labels = []
        if (ch1Enabled) { labels.push("CH1") }
        if (ch2Enabled) { labels.push("CH2") }
        if (ch3Enabled) { labels.push("CH3") }
        if (ch4Enabled) { labels.push("CH4") }
        return labels.length > 0 ? labels.join(" ") : "none"
    }

    function urlToLocalPath(urlValue) {
        var raw = String(urlValue)
        if (raw.indexOf("file://") === 0) {
            return decodeURIComponent(raw.substring(7))
        }
        return decodeURIComponent(raw)
    }

    function ensurePngExtension(pathValue) {
        var p = String(pathValue).trim()
        if (p === "") {
            return ""
        }
        if (!p.toLowerCase().endsWith(".png")) {
            p = p + ".png"
        }
        return p
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

    function loadSelectedCsvFiles(files) {
        var paths = []
        for (var i = 0; i < files.length; i++) {
            var path = urlToLocalPath(files[i])
            if (path !== "") {
                paths.push(path)
            }
        }
        if (dashboard && paths.length > 0) {
            dashboard.loadLogFiles(paths)
            exportHint.text = ""
        }
    }

    function exportChartsAsPng(targetPath) {
        var safePath = ensurePngExtension(targetPath)
        if (safePath === "") {
            exportHint.text = "Export path is empty"
            return
        }

        exportHint.text = "Exporting PNG..."
        captureArea.grabToImage(function(result) {
            var ok = result.saveToFile(safePath)
            if (ok) {
                exportHint.text = "PNG exported: " + safePath
            } else {
                exportHint.text = "Failed to export PNG"
            }
        })
    }

    FileDialog {
        id: csvOpenDialog
        title: "Select one or more CSV logs"
        fileMode: FileDialog.OpenFiles
        nameFilters: ["CSV files (*.csv)", "All files (*)"]
        options: FileDialog.DontUseNativeDialog
        onAccepted: root.loadSelectedCsvFiles(selectedFiles)
    }

    FileDialog {
        id: pngSaveDialog
        title: "Export charts to PNG"
        fileMode: FileDialog.SaveFile
        nameFilters: ["PNG image (*.png)", "All files (*)"]
        defaultSuffix: "png"
        options: FileDialog.DontUseNativeDialog

        onAccepted: {
            var localPath = root.ensurePngExtension(root.urlToLocalPath(selectedFile))
            root.exportChartsAsPng(localPath)
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 10
        color: lightTheme ? "#F0F7FE" : "#060A10"
        border.width: 1
        border.color: lightTheme ? "#B2C9DB" : "#223040"
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 8

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 142
            radius: 7
            color: lightTheme ? "#EAF4FD" : "#121C29"
            border.width: 1
            border.color: lightTheme ? "#B4CBDE" : "#2A3E54"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 10
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    TextField {
                        id: titleField
                        Layout.fillWidth: true
                        placeholderText: "Figure title"
                        text: dashboard ? dashboard.logPlotTitle : "Historical Log Plot"
                        onEditingFinished: {
                            if (dashboard) {
                                dashboard.setLogPlotTitle(text)
                            }
                        }
                    }

                    Button {
                        text: "Load CSV(s)"
                        enabled: !dashboard || !dashboard.logPlotLoading
                        onClicked: csvOpenDialog.open()
                    }

                    Button {
                        text: "Clear"
                        enabled: dashboard && dashboard.logPlotHasData && !dashboard.logPlotLoading
                        onClicked: {
                            dashboard.clearLogPlot()
                            exportHint.text = ""
                        }
                    }

                    Button {
                        text: "Export PNG"
                        enabled: dashboard && dashboard.logPlotHasData && !dashboard.logPlotLoading
                        onClicked: {
                            var stamp = new Date()
                            function pad(v) { return v < 10 ? ("0" + v) : String(v) }
                            var fileName = "log_plot_"
                                + stamp.getFullYear()
                                + pad(stamp.getMonth() + 1)
                                + pad(stamp.getDate())
                                + "_"
                                + pad(stamp.getHours())
                                + pad(stamp.getMinutes())
                                + pad(stamp.getSeconds())
                                + ".png"
                            var baseDir = "logs"
                            if (dashboard && dashboard.loggingPath) {
                                var currentPath = String(dashboard.loggingPath)
                                var slash = Math.max(currentPath.lastIndexOf("/"), currentPath.lastIndexOf("\\"))
                                if (slash > 0) {
                                    baseDir = currentPath.substring(0, slash)
                                }
                            }
                            pngSaveDialog.currentFile = root.localPathToFileUrl(baseDir + "/" + fileName)
                            pngSaveDialog.open()
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Label {
                        text: "Channels:"
                        color: lightTheme ? "#35536A" : "#BFD1E6"
                        font.pixelSize: 12
                        font.bold: true
                    }

                    CheckBox { text: "CH1"; checked: ch1Enabled; onToggled: ch1Enabled = checked }
                    CheckBox { text: "CH2"; checked: ch2Enabled; onToggled: ch2Enabled = checked }
                    CheckBox { text: "CH3"; checked: ch3Enabled; onToggled: ch3Enabled = checked }
                    CheckBox { text: "CH4"; checked: ch4Enabled; onToggled: ch4Enabled = checked }

                    Button { text: "All"; onClicked: setAllChannels(true) }
                    Button { text: "None"; onClicked: setAllChannels(false) }

                    Rectangle {
                        Layout.preferredWidth: 1
                        Layout.fillHeight: true
                        color: lightTheme ? "#AFC6D9" : "#30465E"
                    }

                    Label {
                        text: "Legend"
                        color: lightTheme ? "#35536A" : "#BFD1E6"
                        font.pixelSize: 12
                    }
                    Switch {
                        checked: showLegend
                        onToggled: showLegend = checked
                    }

                    Label {
                        text: "Line"
                        color: lightTheme ? "#35536A" : "#BFD1E6"
                        font.pixelSize: 12
                    }
                    Slider {
                        Layout.preferredWidth: 120
                        from: 1.0
                        to: 3.4
                        stepSize: 0.1
                        value: strokeWidth
                        onMoved: strokeWidth = value
                    }
                    Label {
                        text: Number(strokeWidth).toFixed(1) + "px"
                        color: lightTheme ? "#35536A" : "#BFD1E6"
                        font.pixelSize: 11
                    }
                }
            }
        }

        Rectangle {
            id: captureArea
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 8
            color: lightTheme ? "#F7FBFF" : "#070E17"
            border.width: 1
            border.color: lightTheme ? "#B4CBDE" : "#2A3E54"

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 104
                    radius: 6
                    color: lightTheme ? "#EDF6FD" : "#0F1926"
                    border.width: 1
                    border.color: lightTheme ? "#B4CBDE" : "#2A4058"

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 8
                        spacing: 12

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2

                            Label {
                                text: dashboard ? dashboard.logPlotTitle : "Historical Log Plot"
                                color: lightTheme ? "#16364C" : "#E2ECFA"
                                font.pixelSize: 18
                                font.bold: true
                            }

                            Label {
                                text: dashboard
                                    ? ("Files: " + dashboard.logPlotFileCount
                                    + " | Samples: " + dashboard.logPlotSampleCount
                                    + " | Duration: " + Number(dashboard.logPlotDurationS).toFixed(2) + " s")
                                    : "Files: 0 | Samples: 0"
                                color: lightTheme ? "#4F6E86" : "#9DB5D0"
                                font.pixelSize: 12
                            }

                            Label {
                                visible: dashboard
                                    && dashboard.logPlotStartIso !== ""
                                    && dashboard.logPlotEndIso !== ""
                                text: dashboard
                                    ? ("Range: " + dashboard.logPlotStartIso + " -> " + dashboard.logPlotEndIso)
                                    : ""
                                color: lightTheme ? "#517089" : "#7FA2C4"
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                            }
                        }

                        BusyIndicator {
                            running: dashboard && dashboard.logPlotLoading
                            visible: running
                            implicitWidth: 36
                            implicitHeight: 36
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 6
                        color: lightTheme ? "#EDF6FD" : "#0F1926"
                        border.width: 1
                        border.color: lightTheme ? "#B4CBDE" : "#2A4058"

                        Label {
                            anchors.fill: parent
                            anchors.margins: 8
                            text: "Voltage: " + root.statsSummary(
                                root.filteredSeries(dashboard ? dashboard.logPlotVoltageSeries : []),
                                "V",
                                5
                            )
                            color: lightTheme ? "#23435D" : "#D5E3F5"
                            wrapMode: Text.WrapAnywhere
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 6
                        color: lightTheme ? "#EDF6FD" : "#0F1926"
                        border.width: 1
                        border.color: lightTheme ? "#B4CBDE" : "#2A4058"

                        Label {
                            anchors.fill: parent
                            anchors.margins: 8
                            text: "Current: " + root.statsSummary(
                                root.filteredSeries(dashboard ? dashboard.logPlotCurrentSeries : []),
                                "A",
                                6
                            )
                            color: lightTheme ? "#23435D" : "#D5E3F5"
                            wrapMode: Text.WrapAnywhere
                            font.pixelSize: 11
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 52
                        radius: 6
                        color: lightTheme ? "#EDF6FD" : "#0F1926"
                        border.width: 1
                        border.color: lightTheme ? "#B4CBDE" : "#2A4058"

                        Label {
                            anchors.fill: parent
                            anchors.margins: 8
                            text: "Power: " + root.statsSummary(
                                root.filteredSeries(dashboard ? dashboard.logPlotPowerSeries : []),
                                "W",
                                6
                            )
                            color: lightTheme ? "#23435D" : "#D5E3F5"
                            wrapMode: Text.WrapAnywhere
                            font.pixelSize: 11
                        }
                    }
                }

                SplitView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    orientation: Qt.Horizontal

                    Rectangle {
                        SplitView.minimumWidth: 250
                        SplitView.preferredWidth: 310
                        color: lightTheme ? "#EEF6FD" : "#0F1823"
                        border.width: 1
                        border.color: lightTheme ? "#B4CBDE" : "#2C4259"
                        radius: 6

                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 8
                            spacing: 8

                            Label {
                                text: "View Filters"
                                color: lightTheme ? "#17374E" : "#DFEAF8"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                implicitHeight: Math.max(122, filterColumn.implicitHeight + 16)
                                color: lightTheme ? "#F7FBFF" : "#101A27"
                                border.width: 1
                                border.color: lightTheme ? "#B4CBDE" : "#2D435A"
                                radius: 6

                                ColumnLayout {
                                    id: filterColumn
                                    anchors.fill: parent
                                    anchors.margins: 8
                                    spacing: 6

                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Label {
                                            text: "Metrics:"
                                            color: lightTheme ? "#35536A" : "#B8CBE2"
                                            font.pixelSize: 11
                                        }

                                        Flow {
                                            Layout.fillWidth: true
                                            spacing: 8

                                            CheckBox { text: "V"; checked: showVoltageChart; onToggled: showVoltageChart = checked }
                                            CheckBox { text: "I"; checked: showCurrentChart; onToggled: showCurrentChart = checked }
                                            CheckBox { text: "P"; checked: showPowerChart; onToggled: showPowerChart = checked }
                                            CheckBox { text: "Ah"; checked: showChargeChart; onToggled: showChargeChart = checked }
                                            CheckBox { text: "Wh"; checked: showEnergyChart; onToggled: showEnergyChart = checked }
                                        }
                                    }

                                    RowLayout {
                                        Layout.fillWidth: true
                                        spacing: 6
                                        Button { text: "All Metrics"; onClicked: setAllMetrics(true) }
                                        Button { text: "None"; onClicked: setAllMetrics(false) }
                                        Item { Layout.fillWidth: true }
                                    }

                                    Label {
                                        Layout.fillWidth: true
                                        text: "Active channels: " + root.activeChannelsText()
                                        color: lightTheme ? "#4F6E86" : "#8FB0D0"
                                        font.pixelSize: 11
                                        wrapMode: Text.WrapAnywhere
                                    }
                                }
                            }

                            Label {
                                text: "Loaded CSV Files"
                                color: lightTheme ? "#17374E" : "#DFEAF8"
                                font.pixelSize: 13
                                font.bold: true
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: lightTheme ? "#F7FBFF" : "#070D14"
                                radius: 6
                                border.width: 1
                                border.color: lightTheme ? "#B2C8DA" : "#263A4F"

                                ListView {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    clip: true
                                    spacing: 4
                                    model: dashboard ? dashboard.logPlotFilesModel : null

                                    delegate: Rectangle {
                                        width: ListView.view ? ListView.view.width : parent.width
                                        height: 26
                                        radius: 5
                                        color: lightTheme ? "#EDF6FD" : "#132131"
                                        border.width: 1
                                        border.color: lightTheme ? "#B4CBDE" : "#2D435A"

                                        Label {
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            text: {
                                                if (typeof modelData !== "undefined") {
                                                    return String(modelData)
                                                }
                                                if (typeof display !== "undefined") {
                                                    return String(display)
                                                }
                                                return ""
                                            }
                                            color: lightTheme ? "#23435D" : "#CFE0F5"
                                            elide: Text.ElideMiddle
                                            verticalAlignment: Text.AlignVCenter
                                            font.pixelSize: 11
                                        }
                                    }
                                }
                            }

                            Label {
                                id: exportHint
                                Layout.fillWidth: true
                                text: ""
                                color: lightTheme ? "#2F7D55" : "#8DD1A8"
                                wrapMode: Text.WrapAnywhere
                                font.pixelSize: 11
                            }
                        }
                    }

                    ScrollView {
                        SplitView.fillWidth: true
                        SplitView.fillHeight: true
                        clip: true
                        contentWidth: availableWidth

                        ColumnLayout {
                            width: parent.width
                            spacing: 8

                            MultiSeriesMetricChart {
                                visible: showVoltageChart
                                Layout.fillWidth: true
                                Layout.preferredHeight: 260
                                title: "Voltage"
                                unit: "V"
                                axisMinX: dashboard ? dashboard.logPlotAxisMin : 0
                                axisMaxX: dashboard ? dashboard.logPlotAxisMax : 1
                                showLegend: root.showLegend
                                strokeWidth: root.strokeWidth
                                seriesData: root.filteredSeries(dashboard ? dashboard.logPlotVoltageSeries : [])
                                lightTheme: root.lightTheme
                            }

                            MultiSeriesMetricChart {
                                visible: showCurrentChart
                                Layout.fillWidth: true
                                Layout.preferredHeight: 260
                                title: "Current"
                                unit: "A"
                                axisMinX: dashboard ? dashboard.logPlotAxisMin : 0
                                axisMaxX: dashboard ? dashboard.logPlotAxisMax : 1
                                showLegend: root.showLegend
                                strokeWidth: root.strokeWidth
                                seriesData: root.filteredSeries(dashboard ? dashboard.logPlotCurrentSeries : [])
                                lightTheme: root.lightTheme
                            }

                            MultiSeriesMetricChart {
                                visible: showPowerChart
                                Layout.fillWidth: true
                                Layout.preferredHeight: 260
                                title: "Power"
                                unit: "W"
                                axisMinX: dashboard ? dashboard.logPlotAxisMin : 0
                                axisMaxX: dashboard ? dashboard.logPlotAxisMax : 1
                                showLegend: root.showLegend
                                strokeWidth: root.strokeWidth
                                seriesData: root.filteredSeries(dashboard ? dashboard.logPlotPowerSeries : [])
                                lightTheme: root.lightTheme
                            }

                            RowLayout {
                                visible: showChargeChart || showEnergyChart
                                Layout.fillWidth: true
                                spacing: 8

                                MultiSeriesMetricChart {
                                    visible: showChargeChart
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 240
                                    title: "Charge"
                                    unit: "Ah"
                                    axisMinX: dashboard ? dashboard.logPlotAxisMin : 0
                                    axisMaxX: dashboard ? dashboard.logPlotAxisMax : 1
                                    showLegend: root.showLegend
                                    strokeWidth: root.strokeWidth
                                    seriesData: root.filteredSeries(dashboard ? dashboard.logPlotChargeSeries : [])
                                    lightTheme: root.lightTheme
                                }

                                MultiSeriesMetricChart {
                                    visible: showEnergyChart
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 240
                                    title: "Energy"
                                    unit: "Wh"
                                    axisMinX: dashboard ? dashboard.logPlotAxisMin : 0
                                    axisMaxX: dashboard ? dashboard.logPlotAxisMax : 1
                                    showLegend: root.showLegend
                                    strokeWidth: root.strokeWidth
                                    seriesData: root.filteredSeries(dashboard ? dashboard.logPlotEnergySeries : [])
                                    lightTheme: root.lightTheme
                                }
                            }

                            Label {
                                visible: !showVoltageChart
                                    && !showCurrentChart
                                    && !showPowerChart
                                    && !showChargeChart
                                    && !showEnergyChart
                                Layout.fillWidth: true
                                text: "No metrics selected. Enable at least one metric in View Filters."
                                color: lightTheme ? "#4F6E86" : "#8FB0D0"
                                horizontalAlignment: Text.AlignHCenter
                                font.pixelSize: 12
                            }
                        }
                    }
                }
            }
        }
    }

    Connections {
        target: dashboard

        function onLogPlotChanged() {
            if (!titleField.activeFocus && dashboard) {
                titleField.text = dashboard.logPlotTitle
            }
        }
    }
}




