"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file n6705_ui/models.py
@brief Shared domain models for channel telemetry and totals.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""
from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime


@dataclass(slots=True)
class ChannelMeasurement:
    timestamp: datetime
    channel: int
    voltage_v: float
    current_a: float
    power_w: float


@dataclass(slots=True)
class ChannelTotals:
    charge_ah: float = 0.0
    energy_wh: float = 0.0




