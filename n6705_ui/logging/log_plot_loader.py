"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file n6705_ui/logging/log_plot_loader.py
@brief Historical CSV loader and plot-series payload builder.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""


from __future__ import annotations

import colorsys
import csv
import math
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable


@dataclass(slots=True)
class _LogRow:
    timestamp: datetime
    channel: int
    voltage_v: float
    current_a: float
    power_w: float
    charge_ah: float
    energy_wh: float


class LogPlotLoader:
    """Loads one or more log CSV files and returns series payload for QML charts."""

    _METRIC_KEYS = ("voltage_v", "current_a", "power_w", "charge_ah", "energy_wh")

    _CHANNEL_BASE_RGB = {
        1: (214, 211, 58),
        2: (70, 204, 90),
        3: (57, 168, 255),
        4: (209, 90, 240),
    }

    def __init__(self, max_points_per_series: int = 1800) -> None:
        self._max_points_per_series = max(150, int(max_points_per_series))

    def load_csv_files(self, paths: Iterable[str | Path]) -> dict:
        normalized_paths = self._normalize_paths(paths)
        if not normalized_paths:
            raise ValueError("No CSV files were selected")

        series_by_metric = {metric: [] for metric in self._METRIC_KEYS}
        total_rows = 0
        max_duration_s = 0.0
        global_start_ts: datetime | None = None
        global_end_ts: datetime | None = None
        loaded_files: list[str] = []

        for file_index, path in enumerate(normalized_paths):
            rows = self._read_rows(path)
            if not rows:
                continue

            loaded_files.append(str(path))
            total_rows += len(rows)
            rows.sort(key=lambda item: item.timestamp)
            file_start_ts = rows[0].timestamp
            file_end_ts = rows[-1].timestamp
            file_duration_s = max(0.0, (rows[-1].timestamp - file_start_ts).total_seconds())
            max_duration_s = max(max_duration_s, file_duration_s)
            if global_start_ts is None or file_start_ts < global_start_ts:
                global_start_ts = file_start_ts
            if global_end_ts is None or file_end_ts > global_end_ts:
                global_end_ts = file_end_ts

            channel_rows: dict[int, list[_LogRow]] = {}
            for row in rows:
                channel_rows.setdefault(row.channel, []).append(row)

            for channel, group in sorted(channel_rows.items()):
                group.sort(key=lambda item: item.timestamp)
                elapsed_values = [max(0.0, (item.timestamp - file_start_ts).total_seconds()) for item in group]

                label = f"{path.name} | CH{channel}"
                color = self._series_color(channel=channel, file_index=file_index)

                for metric in self._METRIC_KEYS:
                    points = [
                        {
                            "x": elapsed,
                            "y": float(getattr(item, metric)),
                        }
                        for elapsed, item in zip(elapsed_values, group)
                    ]
                    points = self._decimate(points)

                    series_by_metric[metric].append(
                        {
                            "name": label,
                            "file": str(path),
                            "channel": channel,
                            "color": color,
                            "points": points,
                        }
                    )

        if not loaded_files:
            raise ValueError("Selected CSV files are empty or contain no valid rows")

        return {
            "files": loaded_files,
            "file_count": len(loaded_files),
            "sample_count": total_rows,
            "duration_s": max_duration_s,
            "global_start_iso": (
                global_start_ts.isoformat(timespec="milliseconds")
                if global_start_ts is not None
                else ""
            ),
            "global_end_iso": (
                global_end_ts.isoformat(timespec="milliseconds")
                if global_end_ts is not None
                else ""
            ),
            "series": series_by_metric,
        }

    def _normalize_paths(self, raw_paths: Iterable[str | Path]) -> list[Path]:
        normalized: list[Path] = []
        seen: set[Path] = set()

        for raw in raw_paths:
            text = str(raw).strip()
            if not text:
                continue
            path = Path(text).expanduser().resolve()
            if path in seen:
                continue
            if not path.exists() or not path.is_file():
                raise FileNotFoundError(f"File not found: {path}")
            if path.suffix.lower() != ".csv":
                continue
            normalized.append(path)
            seen.add(path)

        return normalized

    def _read_rows(self, path: Path) -> list[_LogRow]:
        rows: list[_LogRow] = []

        with path.open("r", newline="", encoding="utf-8") as handle:
            reader = csv.DictReader(handle)
            required_headers = {
                "timestamp_iso",
                "channel",
                "voltage_v",
                "current_a",
                "power_w",
                "charge_ah",
                "energy_wh",
            }

            available_headers = set(reader.fieldnames or [])
            missing = required_headers - available_headers
            if missing:
                missing_text = ", ".join(sorted(missing))
                raise ValueError(f"Invalid CSV '{path.name}', missing columns: {missing_text}")

            for raw in reader:
                try:
                    timestamp = self._parse_timestamp(raw["timestamp_iso"])
                    rows.append(
                        _LogRow(
                            timestamp=timestamp,
                            channel=int(float(raw["channel"])),
                            voltage_v=float(raw["voltage_v"]),
                            current_a=float(raw["current_a"]),
                            power_w=float(raw["power_w"]),
                            charge_ah=float(raw["charge_ah"]),
                            energy_wh=float(raw["energy_wh"]),
                        )
                    )
                except Exception:
                    # Skip malformed rows and keep loading valid data.
                    continue

        return rows

    def _parse_timestamp(self, raw_value: str) -> datetime:
        token = str(raw_value).strip()
        if not token:
            raise ValueError("empty timestamp")
        if token.endswith("Z"):
            token = token[:-1] + "+00:00"
        return datetime.fromisoformat(token)

    def _decimate(self, points: list[dict[str, float]]) -> list[dict[str, float]]:
        if len(points) <= self._max_points_per_series:
            return points

        # Keep extrema per bucket so Y scale/shape stay faithful while reducing point count.
        target_pairs = max(1, self._max_points_per_series // 2)
        bucket_size = max(1, int(math.ceil(len(points) / target_pairs)))

        reduced: list[dict[str, float]] = []
        for start_idx in range(0, len(points), bucket_size):
            bucket = points[start_idx:start_idx + bucket_size]
            if not bucket:
                continue

            min_point = bucket[0]
            max_point = bucket[0]
            for point in bucket[1:]:
                if point["y"] < min_point["y"]:
                    min_point = point
                if point["y"] > max_point["y"]:
                    max_point = point

            if min_point["x"] <= max_point["x"]:
                reduced.append(min_point)
                if max_point is not min_point:
                    reduced.append(max_point)
            else:
                reduced.append(max_point)
                if max_point is not min_point:
                    reduced.append(min_point)

        if reduced and reduced[-1] is not points[-1]:
            reduced.append(points[-1])

        if len(reduced) > self._max_points_per_series:
            stride = int(math.ceil(len(reduced) / self._max_points_per_series))
            reduced = [reduced[idx] for idx in range(0, len(reduced), stride)]
            if reduced and reduced[-1] is not points[-1]:
                reduced.append(points[-1])
            return reduced[: self._max_points_per_series]

        return reduced

    def _series_color(self, channel: int, file_index: int) -> str:
        red, green, blue = self._CHANNEL_BASE_RGB.get(int(channel), (120, 196, 255))
        hue, lightness, saturation = colorsys.rgb_to_hls(red / 255.0, green / 255.0, blue / 255.0)

        # Offset color per file to keep same channel recognizable but distinct in legend.
        hue = (hue + (file_index * 0.085)) % 1.0
        lightness = min(0.76, max(0.32, lightness + ((file_index % 3) - 1) * 0.06))

        out_r, out_g, out_b = colorsys.hls_to_rgb(hue, lightness, saturation)
        return f"#{int(out_r * 255):02X}{int(out_g * 255):02X}{int(out_b * 255):02X}"







