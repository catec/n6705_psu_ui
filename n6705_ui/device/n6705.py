"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file n6705_ui/device/n6705.py
@brief Keysight N6705 device adapter and SCPI command abstraction.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""


from __future__ import annotations

from datetime import datetime
from typing import Iterable

from n6705_ui.communication.scpi_client import ScpiTcpClient
from n6705_ui.models import ChannelMeasurement


class N6705PowerAnalyzer:
    def __init__(self, client: ScpiTcpClient) -> None:
        self._client = client
        self._supports_batch_measure = True
        # MEAS:POW? is unsupported on many N6705 modules; computing P = V * I is safer and faster.
        self._supports_power_measure = False

    def connect(self) -> None:
        self._client.connect()

    def disconnect(self) -> None:
        self._client.disconnect()

    @property
    def is_connected(self) -> bool:
        return self._client.is_connected

    def identify(self) -> str:
        return self._client.query("*IDN?")

    def get_channel_count(self) -> int:
        response = self._client.query("SYST:CHAN?")
        count = int(_parse_single_float(response))
        return max(1, min(4, count))

    def get_error(self) -> str:
        return self._client.query("SYST:ERR?")

    def set_voltage(self, channel: int, voltage_v: float) -> None:
        self._client.write(f"VOLT {voltage_v:.6g},(@{channel})")

    def set_current(self, channel: int, current_a: float) -> None:
        self._client.write(f"CURR {current_a:.6g},(@{channel})")

    def get_voltage_setpoint(self, channel: int) -> float:
        response = self._client.query(f"VOLT? (@{channel})")
        return _parse_single_float(response)

    def get_current_setpoint(self, channel: int) -> float:
        response = self._client.query(f"CURR? (@{channel})")
        return _parse_single_float(response)

    def get_voltage_min_limit(self, channel: int) -> float:
        # Per programming guide: VOLT? [MIN|MAX,] (@chanlist)
        response = self._client.query(f"VOLT? MIN,(@{channel})")
        return _parse_single_float(response)

    def get_voltage_max_limit(self, channel: int) -> float:
        # Per programming guide: VOLT? [MIN|MAX,] (@chanlist)
        response = self._client.query(f"VOLT? MAX,(@{channel})")
        return _parse_single_float(response)

    def get_current_min_limit(self, channel: int) -> float:
        # Per programming guide: CURR? [MIN|MAX,] (@chanlist)
        response = self._client.query(f"CURR? MIN,(@{channel})")
        return _parse_single_float(response)

    def get_current_max_limit(self, channel: int) -> float:
        # Per programming guide: CURR? [MIN|MAX,] (@chanlist)
        response = self._client.query(f"CURR? MAX,(@{channel})")
        return _parse_single_float(response)

    def set_output(self, channel: int, enabled: bool) -> None:
        state = "ON" if enabled else "OFF"
        self._client.write(f"OUTP {state},(@{channel})")

    def get_output_state(self, channel: int) -> bool:
        response = self._client.query(f"OUTP? (@{channel})")
        return int(float(response)) == 1

    def measure_channels(self, channels: Iterable[int]) -> list[ChannelMeasurement]:
        ordered = sorted(set(channels))
        if not ordered:
            return []

        if self._supports_batch_measure:
            try:
                chanlist = _format_chanlist(ordered)
                voltages = _parse_float_list(self._client.query(f"MEAS:VOLT? {chanlist}"), len(ordered))
                currents = _parse_float_list(self._client.query(f"MEAS:CURR? {chanlist}"), len(ordered))

                if self._supports_power_measure:
                    try:
                        powers = _parse_float_list(self._client.query(f"MEAS:POW? {chanlist}"), len(ordered))
                    except Exception:
                        self._supports_power_measure = False
                        powers = [voltages[idx] * currents[idx] for idx in range(len(ordered))]
                else:
                    powers = [voltages[idx] * currents[idx] for idx in range(len(ordered))]

                now = datetime.now()
                return [
                    ChannelMeasurement(
                        timestamp=now,
                        channel=channel,
                        voltage_v=voltages[idx],
                        current_a=currents[idx],
                        power_w=powers[idx],
                    )
                    for idx, channel in enumerate(ordered)
                ]
            except Exception:
                # Avoid paying a timeout penalty on every poll if chanlist queries are unsupported.
                self._supports_batch_measure = False

        # Fallback: query channel-by-channel when a mixed chanlist fails.
        samples: list[ChannelMeasurement] = []
        last_exc: Exception | None = None
        for channel in ordered:
            try:
                voltage_v = _parse_single_float(self._client.query(f"MEAS:VOLT? (@{channel})"))
                current_a = _parse_single_float(self._client.query(f"MEAS:CURR? (@{channel})"))

                if self._supports_power_measure:
                    try:
                        power_w = _parse_single_float(self._client.query(f"MEAS:POW? (@{channel})"))
                    except Exception:
                        self._supports_power_measure = False
                        power_w = voltage_v * current_a
                else:
                    power_w = voltage_v * current_a

                samples.append(
                    ChannelMeasurement(
                        timestamp=datetime.now(),
                        channel=channel,
                        voltage_v=voltage_v,
                        current_a=current_a,
                        power_w=power_w,
                    )
                )
            except Exception as exc:  # noqa: BLE001
                last_exc = exc

        if not samples and last_exc is not None:
            raise last_exc
        return samples


def _format_chanlist(channels: Iterable[int]) -> str:
    numeric_channels = [int(ch) for ch in channels]
    if not numeric_channels:
        raise ValueError("Channel list cannot be empty")
    return "(@" + ",".join(str(ch) for ch in numeric_channels) + ")"


def _parse_float_list(response: str, expected_count: int) -> list[float]:
    tokens = [token.strip() for token in response.split(",") if token.strip()]
    if len(tokens) != expected_count:
        raise ValueError(
            f"Cantidad de datos inesperada. Esperado={expected_count}, recibido={len(tokens)}. "
            f"Respuesta='{response}'"
        )
    return [float(token) for token in tokens]


def _parse_single_float(response: str) -> float:
    token = response.strip().split(",")[0]
    return float(token)





