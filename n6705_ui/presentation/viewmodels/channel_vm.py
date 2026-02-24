"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file n6705_ui/presentation/viewmodels/channel_vm.py
@brief Channel-level ViewModel for telemetry and control state.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""
from __future__ import annotations

from PySide6.QtCore import Property, QObject, Signal

from n6705_ui.models import ChannelMeasurement, ChannelTotals
from n6705_ui.presentation.models.time_series_model import TimeSeriesTableModel


class ChannelViewModel(QObject):
    dataChanged = Signal()
    pollingSelectedChanged = Signal()

    def __init__(self, channel_number: int, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._channel_number = int(channel_number)
        self._set_voltage = 0.0
        self._set_current = 0.0
        self._voltage_min = 0.0
        self._voltage_max = 60.0
        self._current_min = 0.0
        self._current_max = 10.0
        self._measured_voltage = 0.0
        self._measured_current = 0.0
        self._measured_power = 0.0
        self._charge_ah = 0.0
        self._energy_wh = 0.0
        self._last_elapsed_s = 0.0
        self._integration_prev_elapsed_s: float | None = None
        self._output_enabled = False
        self._polling_selected = True

        self._voltage_series = TimeSeriesTableModel(max_points=900)
        self._current_series = TimeSeriesTableModel(max_points=900)
        self._power_series = TimeSeriesTableModel(max_points=900)

    @Property(int, constant=True)
    def channelNumber(self) -> int:  # noqa: N802
        return self._channel_number

    @Property(float, notify=dataChanged)
    def setVoltage(self) -> float:  # noqa: N802
        return self._set_voltage

    @Property(float, notify=dataChanged)
    def setCurrent(self) -> float:  # noqa: N802
        return self._set_current

    @Property(float, notify=dataChanged)
    def voltageMin(self) -> float:  # noqa: N802
        return self._voltage_min

    @Property(float, notify=dataChanged)
    def voltageMax(self) -> float:  # noqa: N802
        return self._voltage_max

    @Property(float, notify=dataChanged)
    def currentMin(self) -> float:  # noqa: N802
        return self._current_min

    @Property(float, notify=dataChanged)
    def currentMax(self) -> float:  # noqa: N802
        return self._current_max

    @Property(float, notify=dataChanged)
    def measuredVoltage(self) -> float:  # noqa: N802
        return self._measured_voltage

    @Property(float, notify=dataChanged)
    def measuredCurrent(self) -> float:  # noqa: N802
        return self._measured_current

    @Property(float, notify=dataChanged)
    def measuredPower(self) -> float:  # noqa: N802
        return self._measured_power

    @Property(float, notify=dataChanged)
    def chargeAh(self) -> float:  # noqa: N802
        return self._charge_ah

    @Property(float, notify=dataChanged)
    def energyWh(self) -> float:  # noqa: N802
        return self._energy_wh

    @Property(float, notify=dataChanged)
    def lastElapsedS(self) -> float:  # noqa: N802
        return self._last_elapsed_s

    @Property(bool, notify=dataChanged)
    def outputEnabled(self) -> bool:  # noqa: N802
        return self._output_enabled

    @Property(bool, notify=pollingSelectedChanged)
    def pollingSelected(self) -> bool:  # noqa: N802
        return self._polling_selected

    @pollingSelected.setter
    def pollingSelected(self, value: bool) -> None:  # noqa: N802
        new_value = bool(value)
        if self._polling_selected == new_value:
            return
        self._polling_selected = new_value
        self.pollingSelectedChanged.emit()

    @Property(QObject, constant=True)
    def voltageSeriesModel(self) -> QObject:  # noqa: N802
        return self._voltage_series

    @Property(QObject, constant=True)
    def currentSeriesModel(self) -> QObject:  # noqa: N802
        return self._current_series

    @Property(QObject, constant=True)
    def powerSeriesModel(self) -> QObject:  # noqa: N802
        return self._power_series

    def update_setpoints(self, voltage_v: float, current_a: float) -> None:
        self._set_voltage = float(voltage_v)
        self._set_current = float(current_a)
        self.dataChanged.emit()

    def update_limits(
        self,
        voltage_min: float,
        voltage_max: float,
        current_min: float,
        current_max: float,
    ) -> None:
        v_min = float(voltage_min)
        v_max = float(voltage_max)
        i_min = float(current_min)
        i_max = float(current_max)

        if v_max < v_min:
            v_min, v_max = v_max, v_min
        if i_max < i_min:
            i_min, i_max = i_max, i_min

        self._voltage_min = v_min
        self._voltage_max = v_max
        self._current_min = i_min
        self._current_max = i_max
        self.dataChanged.emit()

    def update_output(self, enabled: bool) -> None:
        self._output_enabled = bool(enabled)
        self.dataChanged.emit()

    def update_measurement(self, sample: ChannelMeasurement, elapsed_s: float) -> None:
        elapsed_s = float(elapsed_s)
        if self._integration_prev_elapsed_s is not None and elapsed_s >= self._integration_prev_elapsed_s:
            delta_h = (elapsed_s - self._integration_prev_elapsed_s) / 3600.0
            self._charge_ah += float(sample.current_a) * delta_h
            self._energy_wh += float(sample.power_w) * delta_h

        self._integration_prev_elapsed_s = elapsed_s
        self._measured_voltage = float(sample.voltage_v)
        self._measured_current = float(sample.current_a)
        self._measured_power = float(sample.power_w)
        self._last_elapsed_s = elapsed_s

        self._voltage_series.append_point(elapsed_s, self._measured_voltage)
        self._current_series.append_point(elapsed_s, self._measured_current)
        self._power_series.append_point(elapsed_s, self._measured_power)

        self.dataChanged.emit()

    def update_totals(self, totals: ChannelTotals) -> None:
        self._charge_ah = float(totals.charge_ah)
        self._energy_wh = float(totals.energy_wh)
        self.dataChanged.emit()

    def reset_series(self) -> None:
        self._voltage_series.clear()
        self._current_series.clear()
        self._power_series.clear()

    def reset_totals(self) -> None:
        self._charge_ah = 0.0
        self._energy_wh = 0.0
        self._integration_prev_elapsed_s = None
        self.dataChanged.emit()




