/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\components\MultiSeriesMetricChart.qml
 * @brief Multi-series chart component for historical comparisons.
 * @author Mouhsine Kassimi Farhaoui
 * @par Mail
 * mouhsine98@gmail.com
 */
// Signature: mkassimi
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Rectangle {
    id: root

    property bool lightTheme: false
    property string title: "Metric"
    property string unit: ""
    property real axisMinX: 0
    property real axisMaxX: 1
    property var seriesData: []
    property real strokeWidth: 1.6
    property bool showLegend: true

    readonly property color panelBg: lightTheme ? "#F5FAFF" : "#03070D"
    readonly property color panelBorder: lightTheme ? "#AFC8DD" : "#294158"
    readonly property color titleFg: lightTheme ? "#143247" : "#E1EDFF"
    readonly property color metaFg: lightTheme ? "#4E6D85" : "#89AACA"
    readonly property color legendBg: lightTheme ? "#EAF3FB" : "#08101A"
    readonly property color legendBorder: lightTheme ? "#B7CCDD" : "#223647"
    readonly property color legendItemBg: lightTheme ? "#F8FCFF" : "#101C2A"
    readonly property color legendItemBorder: lightTheme ? "#B9CFDF" : "#2B435A"
    readonly property color legendFg: lightTheme ? "#23435C" : "#DBE8F8"
    readonly property color gridFg: lightTheme ? "#B8CCDC" : "#30465B"
    readonly property color axisFg: lightTheme ? "#7A92A8" : "#8DA6C0"
    readonly property color axisAccent: lightTheme ? "#8E7A1F" : "#D3BD45"

    radius: 8
    color: panelBg
    border.color: panelBorder
    border.width: 1

    function _niceStep(rawStep) {
        if (!Number.isFinite(rawStep) || rawStep <= 0) {
            return 1
        }
        var power = Math.pow(10, Math.floor(Math.log10(rawStep)))
        var normalized = rawStep / power
        var nice = 1
        if (normalized <= 1) {
            nice = 1
        } else if (normalized <= 2) {
            nice = 2
        } else if (normalized <= 5) {
            nice = 5
        } else {
            nice = 10
        }
        return nice * power
    }

    function _axisDecimals(step) {
        if (!Number.isFinite(step) || step <= 0) {
            return 2
        }
        if (step >= 1) {
            return 2
        }
        return Math.min(8, Math.max(2, Math.ceil(-Math.log10(step)) + 1))
    }

    function _formatAxisValue(value, step) {
        if (!Number.isFinite(value)) {
            return "--"
        }
        var absV = Math.abs(value)
        if (absV > 0 && absV < 1e-3) {
            return value.toExponential(2)
        }
        return value.toFixed(_axisDecimals(step))
    }

    function _formatTime(seconds, span) {
        if (!Number.isFinite(seconds)) {
            return "--"
        }
        var safeSpan = Math.max(1e-9, Number(span))
        if (safeSpan >= 3600) {
            return (seconds / 3600.0).toFixed(2) + "h"
        }
        if (safeSpan >= 120) {
            return (seconds / 60.0).toFixed(2) + "m"
        }
        if (safeSpan >= 10) {
            return seconds.toFixed(2) + "s"
        }
        return seconds.toFixed(3) + "s"
    }

    function _pointCount() {
        var count = 0
        for (var i = 0; i < seriesData.length; i++) {
            var points = seriesData[i].points || []
            count += points.length
        }
        return count
    }

    function _rangeY() {
        var xMin = axisMinX
        var xMax = Math.max(axisMinX + 1e-9, axisMaxX)

        var found = false
        var minV = 0
        var maxV = 1

        for (var i = 0; i < seriesData.length; i++) {
            var points = seriesData[i].points || []
            for (var j = 0; j < points.length; j++) {
                var px = Number(points[j].x)
                if (px < xMin || px > xMax) {
                    continue
                }
                var py = Number(points[j].y)
                if (!Number.isFinite(py)) {
                    continue
                }
                if (!found) {
                    minV = py
                    maxV = py
                    found = true
                } else {
                    if (py < minV) {
                        minV = py
                    }
                    if (py > maxV) {
                        maxV = py
                    }
                }
            }
        }

        if (!found) {
            return {"min": -1, "max": 1, "step": 0.5}
        }

        var span = Math.max(1e-9, maxV - minV)
        var step = _niceStep(span / 4.0)
        var yMin = Math.floor(minV / step) * step
        var yMax = Math.ceil(maxV / step) * step
        var pad = Math.max(step * 0.5, (yMax - yMin) * 0.03)
        yMin -= pad
        yMax += pad

        if (Math.abs(yMax - yMin) < 1e-9) {
            yMin -= step
            yMax += step
        }

        return {"min": yMin, "max": yMax, "step": step}
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Label {
                text: unit === "" ? title : (title + " (" + unit + ")")
                color: titleFg
                font.pixelSize: 12
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Label {
                text: "Series: " + seriesData.length + " | Pts: " + root._pointCount()
                color: metaFg
                font.pixelSize: 11
            }
        }

        Rectangle {
            Layout.fillWidth: true
            visible: showLegend && seriesData.length > 0
            implicitHeight: Math.min(68, legendFlow.implicitHeight + 8)
            color: legendBg
            border.width: 1
            border.color: legendBorder
            radius: 6

            ScrollView {
                anchors.fill: parent
                anchors.margins: 4
                clip: true
                contentWidth: availableWidth
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AsNeeded

                Flow {
                    id: legendFlow
                    width: parent.width
                    spacing: 6

                    Repeater {
                        model: seriesData
                        delegate: Rectangle {
                            required property var modelData
                            implicitHeight: 22
                            implicitWidth: legendLabel.implicitWidth + 26
                            radius: 11
                            color: legendItemBg
                            border.width: 1
                            border.color: legendItemBorder

                            Row {
                                anchors.fill: parent
                                anchors.margins: 5
                                spacing: 5

                                Rectangle {
                                    width: 10
                                    height: 10
                                    radius: 5
                                    color: modelData.color || "#7FDBFF"
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                Label {
                                    id: legendLabel
                                    text: modelData.name || "series"
                                    color: legendFg
                                    font.pixelSize: 10
                                }
                            }
                        }
                    }
                }
            }
        }

        Canvas {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: true

            onPaint: {
                if (width <= 2 || height <= 2) {
                    return
                }
                var ctx = getContext("2d")
                ctx.reset()

                var w = width
                var h = height

                ctx.fillStyle = root.panelBg
                ctx.fillRect(0, 0, w, h)

                var padL = 42
                var padR = 12
                var padT = 10
                var padB = 24

                var plotW = Math.max(10, w - padL - padR)
                var plotH = Math.max(10, h - padT - padB)

                ctx.strokeStyle = root.gridFg
                ctx.lineWidth = 1

                for (var gx = 0; gx <= 10; gx++) {
                    var xx = padL + (plotW * gx / 10.0)
                    ctx.beginPath()
                    ctx.moveTo(xx, padT)
                    ctx.lineTo(xx, padT + plotH)
                    ctx.stroke()
                }

                for (var gy = 0; gy <= 8; gy++) {
                    var yy = padT + (plotH * gy / 8.0)
                    ctx.beginPath()
                    ctx.moveTo(padL, yy)
                    ctx.lineTo(padL + plotW, yy)
                    ctx.stroke()
                }

                ctx.strokeStyle = root.axisAccent
                ctx.beginPath()
                ctx.moveTo(padL, padT)
                ctx.lineTo(padL, padT + plotH)
                ctx.lineTo(padL + plotW, padT + plotH)
                ctx.stroke()

                var xMin = axisMinX
                var xMax = Math.max(axisMinX + 1e-9, axisMaxX)
                var xSpan = xMax - xMin
                var yRange = root._rangeY()
                var yMin = yRange.min
                var yMax = yRange.max
                var yStep = yRange.step

                ctx.fillStyle = root.axisFg
                ctx.font = "11px Noto Sans"
                ctx.fillText(root._formatAxisValue(yMax, yStep), 2, padT + 10)
                ctx.fillText(root._formatAxisValue(yMin, yStep), 2, padT + plotH)
                ctx.fillText(root._formatTime(xMin, xSpan), padL, h - 4)
                var xMaxLabel = root._formatTime(xMax, xSpan)
                var maxLabelPad = Math.max(34, xMaxLabel.length * 6)
                ctx.fillText(xMaxLabel, padL + plotW - maxLabelPad, h - 4)

                if (seriesData.length <= 0) {
                    return
                }

                for (var si = 0; si < seriesData.length; si++) {
                    var series = seriesData[si]
                    var points = series.points || []
                    if (points.length <= 0) {
                        continue
                    }

                    ctx.strokeStyle = series.color || "#7FDBFF"
                    ctx.lineWidth = strokeWidth
                    ctx.beginPath()

                    var started = false
                    for (var pi = 0; pi < points.length; pi++) {
                        var rawX = Number(points[pi].x)
                        var rawY = Number(points[pi].y)
                        if (!Number.isFinite(rawX) || !Number.isFinite(rawY)) {
                            continue
                        }
                        if (rawX < xMin || rawX > xMax) {
                            continue
                        }

                        var nx = (rawX - xMin) / (xMax - xMin)
                        var ny = (rawY - yMin) / (yMax - yMin)
                        var px = padL + (nx * plotW)
                        var py = padT + ((1.0 - ny) * plotH)

                        if (!started) {
                            ctx.moveTo(px, py)
                            started = true
                        } else {
                            ctx.lineTo(px, py)
                        }
                    }

                    if (started) {
                        ctx.stroke()
                    }
                }
            }
        }

        Label {
            Layout.fillWidth: true
            visible: seriesData.length === 0
            text: "No data loaded"
            color: metaFg
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: 11
        }
    }

    onSeriesDataChanged: canvas.requestPaint()
    onAxisMinXChanged: canvas.requestPaint()
    onAxisMaxXChanged: canvas.requestPaint()
    onWidthChanged: canvas.requestPaint()
    onHeightChanged: canvas.requestPaint()
}




