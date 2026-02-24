"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file tests/test_log_plot_loader.py
@brief Unit tests for historical CSV log loading and decimation.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""
from __future__ import annotations

"""Tests for historical log CSV loader.

Signature: mkassimi
"""

import csv
import tempfile
import unittest
from datetime import datetime, timedelta
from pathlib import Path

from n6705_ui.logging.log_plot_loader import LogPlotLoader


class LogPlotLoaderTests(unittest.TestCase):
    def setUp(self) -> None:
        self._tmp = tempfile.TemporaryDirectory()
        self.tmp_path = Path(self._tmp.name)

    def tearDown(self) -> None:
        self._tmp.cleanup()

    def _write_csv(self, path: Path, rows: list[dict]) -> None:
        path.parent.mkdir(parents=True, exist_ok=True)
        with path.open("w", newline="", encoding="utf-8") as handle:
            writer = csv.DictWriter(
                handle,
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
            writer.writeheader()
            writer.writerows(rows)

    def test_load_single_file_builds_metric_series(self) -> None:
        csv_path = self.tmp_path / "consumption_a.csv"
        t0 = datetime(2026, 2, 23, 14, 0, 0)
        rows = [
            {
                "timestamp_iso": (t0 + timedelta(seconds=0)).isoformat(timespec="milliseconds"),
                "channel": 1,
                "voltage_v": 5.0,
                "current_a": 1.0,
                "power_w": 5.0,
                "charge_ah": 0.0,
                "energy_wh": 0.0,
            },
            {
                "timestamp_iso": (t0 + timedelta(seconds=1)).isoformat(timespec="milliseconds"),
                "channel": 1,
                "voltage_v": 5.1,
                "current_a": 1.1,
                "power_w": 5.61,
                "charge_ah": 0.0003,
                "energy_wh": 0.0016,
            },
            {
                "timestamp_iso": (t0 + timedelta(seconds=2)).isoformat(timespec="milliseconds"),
                "channel": 2,
                "voltage_v": 12.0,
                "current_a": 0.2,
                "power_w": 2.4,
                "charge_ah": 0.0001,
                "energy_wh": 0.0007,
            },
        ]
        self._write_csv(csv_path, rows)

        loader = LogPlotLoader(max_points_per_series=300)
        payload = loader.load_csv_files([csv_path])

        self.assertEqual(payload["file_count"], 1)
        self.assertEqual(payload["sample_count"], 3)
        self.assertAlmostEqual(payload["duration_s"], 2.0, places=3)
        self.assertEqual(len(payload["series"]["voltage_v"]), 2)  # CH1 + CH2
        self.assertEqual(len(payload["series"]["current_a"]), 2)

        first_voltage = payload["series"]["voltage_v"][0]
        self.assertTrue(first_voltage["name"].startswith("consumption_a.csv | CH"))
        self.assertGreaterEqual(len(first_voltage["points"]), 1)

    def test_decimation_limits_points_per_series(self) -> None:
        csv_path = self.tmp_path / "consumption_dense.csv"
        t0 = datetime(2026, 2, 23, 14, 0, 0)
        rows = []
        for idx in range(1600):
            rows.append(
                {
                    "timestamp_iso": (t0 + timedelta(milliseconds=idx * 100)).isoformat(timespec="milliseconds"),
                    "channel": 1,
                    "voltage_v": 10.0 + (idx % 10) * 0.01,
                    "current_a": 0.5,
                    "power_w": 5.0,
                    "charge_ah": idx / 1_000_000.0,
                    "energy_wh": idx / 900_000.0,
                }
            )
        self._write_csv(csv_path, rows)

        loader = LogPlotLoader(max_points_per_series=300)
        payload = loader.load_csv_files([csv_path])

        voltage_series = payload["series"]["voltage_v"][0]
        self.assertLessEqual(len(voltage_series["points"]), 301)

    def test_missing_columns_raise_clear_error(self) -> None:
        csv_path = self.tmp_path / "invalid.csv"
        csv_path.write_text("timestamp_iso,channel\n2026-02-23T14:00:00,1\n", encoding="utf-8")

        loader = LogPlotLoader()
        with self.assertRaisesRegex(ValueError, "missing columns"):
            loader.load_csv_files([csv_path])


if __name__ == "__main__":
    unittest.main()




