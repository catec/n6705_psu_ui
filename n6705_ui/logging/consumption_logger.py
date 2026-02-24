"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file n6705_ui/logging/consumption_logger.py
@brief CSV logging service with per-channel Ah/Wh accumulation.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""


from __future__ import annotations

import csv
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

from n6705_ui.models import ChannelMeasurement, ChannelTotals


@dataclass(slots=True)
class _AccumulatorState:
    last_timestamp: datetime | None = None
    totals: ChannelTotals = field(default_factory=ChannelTotals)


class ConsumptionLogger:
    def __init__(self) -> None:
        self._file_handle = None
        self._writer: csv.DictWriter | None = None
        self._path: Path | None = None
        self._states: dict[int, _AccumulatorState] = {}

    @property
    def is_running(self) -> bool:
        return self._file_handle is not None and self._writer is not None

    @property
    def path(self) -> Path | None:
        return self._path

    def start(self, path: str | Path) -> None:
        if self.is_running:
            raise RuntimeError("A logging session is already active")

        output_path = Path(path).expanduser().resolve()
        output_path.parent.mkdir(parents=True, exist_ok=True)

        self._file_handle = output_path.open("w", newline="", encoding="utf-8")
        self._writer = csv.DictWriter(
            self._file_handle,
            fieldnames=[
                "timestamp_iso",
                "channel",
                "voltage_v",
                "current_a",
                "power_w",
                "charge_ah",
                "energy_wh",
            ],
        )
        self._writer.writeheader()
        self._file_handle.flush()
        self._states.clear()
        self._path = output_path

    def stop(self) -> None:
        if self._file_handle is not None:
            self._file_handle.close()
        self._file_handle = None
        self._writer = None

    def register(self, sample: ChannelMeasurement) -> ChannelTotals:
        if not self.is_running or self._writer is None or self._file_handle is None:
            raise RuntimeError("Logger is not active")

        state = self._states.setdefault(sample.channel, _AccumulatorState())
        if state.last_timestamp is not None:
            delta_seconds = (sample.timestamp - state.last_timestamp).total_seconds()
            if delta_seconds > 0:
                delta_hours = delta_seconds / 3600.0
                state.totals.energy_wh += sample.power_w * delta_hours
                state.totals.charge_ah += sample.current_a * delta_hours

        state.last_timestamp = sample.timestamp

        self._writer.writerow(
            {
                "timestamp_iso": sample.timestamp.isoformat(timespec="milliseconds"),
                "channel": sample.channel,
                "voltage_v": f"{sample.voltage_v:.6f}",
                "current_a": f"{sample.current_a:.6f}",
                "power_w": f"{sample.power_w:.6f}",
                "charge_ah": f"{state.totals.charge_ah:.9f}",
                "energy_wh": f"{state.totals.energy_wh:.9f}",
            }
        )
        self._file_handle.flush()
        return ChannelTotals(
            charge_ah=state.totals.charge_ah,
            energy_wh=state.totals.energy_wh,
        )

    def totals_for_channel(self, channel: int) -> ChannelTotals:
        state = self._states.get(channel)
        if state is None:
            return ChannelTotals()
        return ChannelTotals(
            charge_ah=state.totals.charge_ah,
            energy_wh=state.totals.energy_wh,
        )







