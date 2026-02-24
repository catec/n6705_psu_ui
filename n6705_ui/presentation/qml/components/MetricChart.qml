/*
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com
*/

/**
 * @file n6705_ui\presentation\qml\components\MetricChart.qml
 * @brief Single-series metric chart component.
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
    property string title: "Metric"
    property string unit: ""
    property color seriesColor: "#0EA5E9"
    property real axisMinX: 0
    property real axisMaxX: 60
    property int maxPoints: 360
    property bool autoCompressX: true
    property real minRangeX: 60
    property real xOverflowThreshold: 0.98
    property real xExpandFactor: 1.2

    readonly property color panelBg: lightTheme ? "#F5FAFF" : "#03070D"
    readonly property color panelBorder: lightTheme ? "#AFC8DD" : "#294158"
    readonly property color titleFg: lightTheme ? "#143247" : "#E1EDFF"
    readonly property color metaFg: lightTheme ? "#4E6D85" : "#86A5C7"
    readonly property color gridFg: lightTheme ? "#B8CCDC" : "#334A62"
    readonly property color axisFg: lightTheme ? "#7A92A8" : "#8DA6C0"
    readonly property color axisAccent: lightTheme ? "#8E7A1F" : "#D3BD45"

    radius: 8
    color: panelBg
    border.color: panelBorder
    border.width: 1

    property var points: []

    function clearSeries() {
        points = []
        canvas.requestPaint()
    }

    function appendPoint(x, y) {
        var list = points.slice(0)
        list.push({"x": x, "y": y})
        if (list.length > maxPoints) {
            list = list.slice(list.length - maxPoints)
        }
        points = list
        canvas.requestPaint()
    }

    function _minY() {
        if (points.length <= 0) return -1
        var minV = points[0].y
        for (var i = 1; i < points.length; i++) {
            if (points[i].y < minV) minV = points[i].y
        }
        return minV
    }

    function _maxY() {
        if (points.length <= 0) return 1
        var maxV = points[0].y
        for (var i = 1; i < points.length; i++) {
            if (points[i].y > maxV) maxV = points[i].y
        }
        return maxV
    }

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

    function _rangeY() {
        var minV = _minY()
        var maxV = _maxY()
        if (!Number.isFinite(minV) || !Number.isFinite(maxV)) {
            return {"min": -1, "max": 1, "step": 0.5}
        }
        var span = Math.max(1e-9, maxV - minV)
        var step = _niceStep(span / 4.0)
        var yMin = Math.floor(minV / step) * step
        var yMax = Math.ceil(maxV / step) * step
        if (Math.abs(yMax - yMin) < 1e-9) {
            yMin -= step
            yMax += step
        }
        return {"min": yMin, "max": yMax, "step": step}
    }

    function _axisDecimals(step) {
        if (!Number.isFinite(step) || step <= 0) {
            return 2
        }
        if (step >= 1) {
            return 2
        }
        return Math.min(7, Math.max(2, Math.ceil(-Math.log10(step)) + 1))
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

    function _rangeX() {
        var xMin = axisMinX
        var xMax = Math.max(axisMinX + 1e-9, axisMaxX)

        if (!autoCompressX || points.length <= 0) {
            return {"min": xMin, "max": xMax}
        }

        var latestX = Number(points[points.length - 1].x)
        if (!Number.isFinite(latestX)) {
            return {"min": xMin, "max": xMax}
        }

        // Keep growing visible X range when newest sample is about to hit right border.
        var effectiveMin = 0.0
        var effectiveMax = Math.max(minRangeX, xMax)
        while (latestX >= effectiveMax * xOverflowThreshold) {
            effectiveMax *= Math.max(1.05, xExpandFactor)
        }
        return {"min": effectiveMin, "max": effectiveMax}
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: 3

        RowLayout {
            Layout.fillWidth: true

            Label {
                text: unit === "" ? title : (title + " (" + unit + ")")
                color: titleFg
                font.pixelSize: 12
                font.bold: true
            }

            Item { Layout.fillWidth: true }

            Label {
                text: points.length > 0 ? ("Samples: " + points.length) : "Samples: 0"
                color: metaFg
                font.pixelSize: 11
            }
        }

        Canvas {
            id: canvas
            Layout.fillWidth: true
            Layout.fillHeight: true
            antialiasing: false

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

                var padL = 36
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

                var yRange = root._rangeY()
                var yMin = yRange.min
                var yMax = yRange.max
                var yStep = yRange.step
                var xRange = root._rangeX()
                var xMin = xRange.min
                var xMax = Math.max(xMin + 1e-9, xRange.max)

                ctx.fillStyle = root.axisFg
                ctx.font = "11px Noto Sans"
                ctx.fillText(root._formatAxisValue(yMax, yStep), 2, padT + 10)
                ctx.fillText(root._formatAxisValue(yMin, yStep), 2, padT + plotH)
                ctx.fillText(xMin.toFixed(1) + "s", padL, h - 4)
                ctx.fillText(xMax.toFixed(1) + "s", padL + plotW - 30, h - 4)

                if (points.length <= 0) {
                    return
                }

                ctx.strokeStyle = seriesColor
                ctx.lineWidth = 2
                ctx.beginPath()

                var started = false
                for (var i = 0; i < points.length; i++) {
                    var pxRaw = points[i].x
                    var pyRaw = points[i].y
                    if (pxRaw < xMin || pxRaw > xMax) {
                        continue
                    }

                    var nx = (pxRaw - xMin) / (xMax - xMin)
                    var ny = (pyRaw - yMin) / (yMax - yMin)
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

                var lastPoint = points[points.length - 1]
                if (lastPoint.x >= xMin && lastPoint.x <= xMax) {
                    var lx = padL + ((lastPoint.x - xMin) / (xMax - xMin) * plotW)
                    var ly = padT + ((1.0 - ((lastPoint.y - yMin) / (yMax - yMin))) * plotH)
                    ctx.fillStyle = seriesColor
                    ctx.beginPath()
                    ctx.arc(lx, ly, 3, 0, Math.PI * 2, true)
                    ctx.fill()
                }
            }
        }
    }

    onAxisMinXChanged: canvas.requestPaint()
    onAxisMaxXChanged: canvas.requestPaint()
}




