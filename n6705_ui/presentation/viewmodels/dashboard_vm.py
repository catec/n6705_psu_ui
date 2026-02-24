"""
Author: Mouhsine Kassimi Farhaoui
Mail: mouhsine98@gmail.com

@file n6705_ui/presentation/viewmodels/dashboard_vm.py
@brief Main dashboard ViewModel orchestrating connection, polling, and logging.
@author Mouhsine Kassimi Farhaoui
@par Mail
mouhsine98@gmail.com
"""


from __future__ import annotations

import json
import threading
import time
from datetime import datetime
from pathlib import Path

from PySide6.QtCore import Property, QObject, Signal, Slot
from PySide6.QtCore import QStringListModel

from n6705_ui.communication.scpi_client import ScpiTcpClient
from n6705_ui.device.n6705 import N6705PowerAnalyzer
from n6705_ui.logging.consumption_logger import ConsumptionLogger
from n6705_ui.logging.log_plot_loader import LogPlotLoader
from n6705_ui.presentation.viewmodels.channel_vm import ChannelViewModel


class DashboardViewModel(QObject):
    connectionChanged = Signal()
    statusChanged = Signal()
    monitoringChanged = Signal()
    loggingChanged = Signal()
    chartSelectionChanged = Signal()
    axisChanged = Signal()
    channelCountChanged = Signal()
    telemetryChanged = Signal()
    logLinesChanged = Signal()
    sessionChanged = Signal()
    logPlotChanged = Signal()
    logPlotLoadingChanged = Signal()

    samplesReady = Signal(list)
    pollingError = Signal(str)
    connectWorkerDone = Signal(bool, str, int, object, object)
    snapshotValueReady = Signal(int, float, float, bool)
    limitsValueReady = Signal(int, float, float, float, float)
    workerMessage = Signal(str)
    logPlotLoadDone = Signal(bool, str, object)

    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._client: ScpiTcpClient | None = None
        self._instrument: N6705PowerAnalyzer | None = None
        self._logger = ConsumptionLogger()
        self._log_plot_loader = LogPlotLoader(max_points_per_series=2200)

        self._connected = False
        self._connecting = False
        self._connect_thread: threading.Thread | None = None
        self._status = "Ready"
        self._idn = "--"
        self._channel_count = 4

        self._connection_host = "192.168.6.59"
        self._connection_port = 5025
        self._connection_timeout_s = 3.0

        self._monitoring = False
        self._poll_interval_s = 1.0
        self._poll_thread: threading.Thread | None = None
        self._poll_stop = threading.Event()

        self._logging_active = False
        self._logging_path = str(Path("logs") / f"consumption_{datetime.now().strftime('%Y%m%d_%H%M%S')}.csv")

        self._chart_channel = 1
        self._axis_min = 0.0
        self._axis_max = 60.0
        self._plot_window_s = 60.0
        self._acquisition_start = datetime.now()

        self._channels = {ch: ChannelViewModel(ch, self) for ch in range(1, 5)}

        self._log_lines_model = QStringListModel(self)
        self._log_lines: list[str] = []
        self._log_plot_files_model = QStringListModel(self)

        self._log_plot_loading = False
        self._log_plot_title = "Historical Log Plot"
        self._log_plot_files: list[str] = []
        self._log_plot_duration_s = 0.0
        self._log_plot_sample_count = 0
        self._log_plot_start_iso = ""
        self._log_plot_end_iso = ""
        self._log_plot_series: dict[str, list[dict]] = {
            "voltage_v": [],
            "current_a": [],
            "power_w": [],
            "charge_ah": [],
            "energy_wh": [],
        }

        self._session_file = Path.home() / ".config" / "n6705_ui" / "session.json"

        self._load_session_config()

        self.samplesReady.connect(self._on_samples_ready)
        self.pollingError.connect(self._on_polling_error)
        self.connectWorkerDone.connect(self._on_connect_worker_done)
        self.snapshotValueReady.connect(self._on_snapshot_value_ready)
        self.limitsValueReady.connect(self._on_limits_value_ready)
        self.workerMessage.connect(self._append_log)
        self.logPlotLoadDone.connect(self._on_log_plot_load_done)

    @Property(bool, notify=connectionChanged)
    def connected(self) -> bool:
        return self._connected

    @Property(bool, notify=connectionChanged)
    def connecting(self) -> bool:
        return self._connecting

    @Property(str, notify=connectionChanged)
    def idn(self) -> str:
        return self._idn

    @Property(str, notify=statusChanged)
    def statusText(self) -> str:  # noqa: N802
        return self._status

    @Property(bool, notify=monitoringChanged)
    def monitoring(self) -> bool:
        return self._monitoring

    @Property(bool, notify=loggingChanged)
    def loggingActive(self) -> bool:  # noqa: N802
        return self._logging_active

    @Property(str, notify=loggingChanged)
    def loggingPath(self) -> str:  # noqa: N802
        return self._logging_path

    @loggingPath.setter
    def loggingPath(self, value: str) -> None:  # noqa: N802
        value = self._normalize_logging_path(value)
        if not value or self._logging_path == value:
            return
        self._logging_path = value
        self.loggingChanged.emit()
        self._save_session_config()

    @Property(int, notify=chartSelectionChanged)
    def chartChannel(self) -> int:  # noqa: N802
        return self._chart_channel

    @chartChannel.setter
    def chartChannel(self, value: int) -> None:  # noqa: N802
        new_channel = max(1, min(self._channel_count, int(value)))
        if self._chart_channel == new_channel:
            return
        self._chart_channel = new_channel
        self.chartSelectionChanged.emit()
        self._save_session_config()

    @Property(float, notify=axisChanged)
    def axisMin(self) -> float:  # noqa: N802
        return self._axis_min

    @Property(float, notify=axisChanged)
    def axisMax(self) -> float:  # noqa: N802
        return self._axis_max

    @Property(str, notify=sessionChanged)
    def connectionHost(self) -> str:  # noqa: N802
        return self._connection_host

    @Property(int, notify=sessionChanged)
    def connectionPort(self) -> int:  # noqa: N802
        return self._connection_port

    @Property(float, notify=sessionChanged)
    def connectionTimeout(self) -> float:  # noqa: N802
        return self._connection_timeout_s

    @Property(float, notify=sessionChanged)
    def pollInterval(self) -> float:  # noqa: N802
        return self._poll_interval_s

    @Property(float, notify=sessionChanged)
    def pollFrequency(self) -> float:  # noqa: N802
        return 1.0 / self._poll_interval_s if self._poll_interval_s > 0 else 0.0

    @Property(int, notify=channelCountChanged)
    def channelCount(self) -> int:  # noqa: N802
        return self._channel_count

    @Property(QObject, constant=True)
    def logLinesModel(self) -> QObject:  # noqa: N802
        return self._log_lines_model

    @Property(QObject, constant=True)
    def logPlotFilesModel(self) -> QObject:  # noqa: N802
        return self._log_plot_files_model

    @Property(bool, notify=logPlotLoadingChanged)
    def logPlotLoading(self) -> bool:  # noqa: N802
        return self._log_plot_loading

    @Property(str, notify=logPlotChanged)
    def logPlotTitle(self) -> str:  # noqa: N802
        return self._log_plot_title

    @Property(bool, notify=logPlotChanged)
    def logPlotHasData(self) -> bool:  # noqa: N802
        return bool(self._log_plot_files and self._log_plot_sample_count > 0)

    @Property(int, notify=logPlotChanged)
    def logPlotFileCount(self) -> int:  # noqa: N802
        return len(self._log_plot_files)

    @Property(int, notify=logPlotChanged)
    def logPlotSampleCount(self) -> int:  # noqa: N802
        return self._log_plot_sample_count

    @Property(float, notify=logPlotChanged)
    def logPlotAxisMin(self) -> float:  # noqa: N802
        return 0.0

    @Property(float, notify=logPlotChanged)
    def logPlotAxisMax(self) -> float:  # noqa: N802
        if self._log_plot_duration_s > 0.0:
            return self._log_plot_duration_s
        return 1.0

    @Property(float, notify=logPlotChanged)
    def logPlotDurationS(self) -> float:  # noqa: N802
        return self._log_plot_duration_s

    @Property(str, notify=logPlotChanged)
    def logPlotStartIso(self) -> str:  # noqa: N802
        return self._log_plot_start_iso

    @Property(str, notify=logPlotChanged)
    def logPlotEndIso(self) -> str:  # noqa: N802
        return self._log_plot_end_iso

    @Property("QVariantList", notify=logPlotChanged)
    def logPlotVoltageSeries(self) -> list[dict]:  # noqa: N802
        return self._log_plot_series["voltage_v"]

    @Property("QVariantList", notify=logPlotChanged)
    def logPlotCurrentSeries(self) -> list[dict]:  # noqa: N802
        return self._log_plot_series["current_a"]

    @Property("QVariantList", notify=logPlotChanged)
    def logPlotPowerSeries(self) -> list[dict]:  # noqa: N802
        return self._log_plot_series["power_w"]

    @Property("QVariantList", notify=logPlotChanged)
    def logPlotChargeSeries(self) -> list[dict]:  # noqa: N802
        return self._log_plot_series["charge_ah"]

    @Property("QVariantList", notify=logPlotChanged)
    def logPlotEnergySeries(self) -> list[dict]:  # noqa: N802
        return self._log_plot_series["energy_wh"]

    @Slot(int, result=QObject)
    def channelVm(self, channel: int) -> QObject:  # noqa: N802
        return self._channels[max(1, min(4, int(channel)))]

    @Slot(str, int, float)
    def setConnectionParams(self, host: str, port: int, timeout_s: float) -> None:  # noqa: N802
        changed = False

        host = host.strip()
        if host and host != self._connection_host:
            self._connection_host = host
            changed = True

        try:
            safe_port = int(port)
            if 1 <= safe_port <= 65535 and safe_port != self._connection_port:
                self._connection_port = safe_port
                changed = True
        except (TypeError, ValueError):
            pass

        try:
            safe_timeout = max(0.2, float(timeout_s))
            if abs(safe_timeout - self._connection_timeout_s) > 1e-6:
                self._connection_timeout_s = safe_timeout
                changed = True
        except (TypeError, ValueError):
            pass

        if changed:
            self.sessionChanged.emit()
            self._save_session_config()

    @Slot(str, int, float)
    def connectDevice(self, host: str, port: int, timeout_s: float) -> None:  # noqa: N802
        self.setConnectionParams(host, port, timeout_s)

        if not self._connection_host:
            self._set_status("Host/IP is empty")
            return

        if self._connecting:
            self._append_log("Connection in progress")
            return

        if self._connected:
            self._append_log("An active connection already exists")
            return

        self._connecting = True
        self.connectionChanged.emit()
        self._set_status(f"Connecting to {self._connection_host}:{self._connection_port}...")

        self._connect_thread = threading.Thread(
            target=self._connect_worker,
            args=(self._connection_host, self._connection_port, self._connection_timeout_s),
            daemon=True,
        )
        self._connect_thread.start()

    def _connect_worker(self, host: str, port: int, timeout_s: float) -> None:
        client: ScpiTcpClient | None = None
        instrument: N6705PowerAnalyzer | None = None
        try:
            client = ScpiTcpClient(
                host=host,
                port=port,
                timeout_s=timeout_s,
            )
            instrument = N6705PowerAnalyzer(client)
            instrument.connect()
            idn = instrument.identify()
            channel_count = 4
            try:
                channel_count = instrument.get_channel_count()
            except Exception:
                channel_count = 4
            self.connectWorkerDone.emit(True, idn, channel_count, client, instrument)
        except Exception as exc:  # noqa: BLE001
            if client is not None:
                try:
                    client.disconnect()
                except Exception:  # noqa: BLE001
                    pass
            self.connectWorkerDone.emit(False, str(exc), 4, None, None)

    @Slot(bool, str, int, object, object)
    def _on_connect_worker_done(
        self,
        success: bool,
        payload: str,
        channel_count: int,
        client: object,
        instrument: object,
    ) -> None:
        self._connect_thread = None
        self._connecting = False
        self.connectionChanged.emit()

        if not success:
            self._set_status(f"Connection error: {payload}")
            self._safe_disconnect_internals()
            return

        self._client = client if isinstance(client, ScpiTcpClient) else None
        self._instrument = instrument if isinstance(instrument, N6705PowerAnalyzer) else None
        if self._client is None or self._instrument is None:
            self._set_status("Internal connection error")
            self._safe_disconnect_internals()
            return

        self._idn = payload
        self._connected = True
        new_count = max(1, min(4, int(channel_count)))
        if self._channel_count != new_count:
            self._channel_count = new_count
            self.channelCountChanged.emit()
        if self._chart_channel > self._channel_count:
            self._chart_channel = self._channel_count
            self.chartSelectionChanged.emit()
        self.connectionChanged.emit()

        self._set_status(f"Connected to {self._connection_host}:{self._connection_port}")
        self._append_log(f"*IDN?: {self._idn}")

        for channel, vm in self._channels.items():
            vm.pollingSelected = channel <= self._channel_count

        self.refreshSnapshot()
        self._refresh_limits_async()

        if not self._monitoring:
            self.startMonitoring()

    @Slot()
    def disconnectDevice(self) -> None:  # noqa: N802
        if self._connecting and not self._connected:
            self._append_log("Connection in progress; wait for completion")
            return
        self.stopLogging()
        self.stopMonitoring()
        self._safe_disconnect_internals()
        self._set_status("Disconnected")

    def _safe_disconnect_internals(self) -> None:
        if self._instrument is not None:
            try:
                self._instrument.disconnect()
            except Exception as exc:  # noqa: BLE001
                self._append_log(f"Error while disconnecting: {exc}")
        self._client = None
        self._instrument = None
        self._connected = False
        self._connecting = False
        self._connect_thread = None
        self._idn = "--"
        self.connectionChanged.emit()

    @Slot()
    def refreshSnapshot(self) -> None:  # noqa: N802
        instrument = self._instrument
        if instrument is None:
            return

        threading.Thread(
            target=self._refresh_snapshot_worker,
            args=(instrument,),
            daemon=True,
        ).start()

    def _refresh_snapshot_worker(self, instrument: N6705PowerAnalyzer) -> None:
        for channel in range(1, self._channel_count + 1):
            try:
                voltage_v = instrument.get_voltage_setpoint(channel)
                current_a = instrument.get_current_setpoint(channel)
                output_on = instrument.get_output_state(channel)
                self.snapshotValueReady.emit(channel, voltage_v, current_a, output_on)
            except Exception as exc:  # noqa: BLE001
                self.workerMessage.emit(f"Failed to read CH{channel}: {exc}")

    def _refresh_limits_async(self) -> None:
        instrument = self._instrument
        if instrument is None:
            return

        threading.Thread(
            target=self._refresh_limits_worker,
            args=(instrument,),
            daemon=True,
        ).start()

    def _refresh_limits_worker(self, instrument: N6705PowerAnalyzer) -> None:
        for channel in range(1, self._channel_count + 1):
            try:
                # Programming guide: VOLT?/CURR? support MIN|MAX query qualifier.
                v_min = instrument.get_voltage_min_limit(channel)
                v_max = instrument.get_voltage_max_limit(channel)
                i_min = instrument.get_current_min_limit(channel)
                i_max = instrument.get_current_max_limit(channel)
                self.limitsValueReady.emit(channel, v_min, v_max, i_min, i_max)
            except Exception:
                # Keep defaults if module does not support these queries.
                pass

    @Slot(int, float, float, bool)
    def _on_snapshot_value_ready(
        self,
        channel: int,
        voltage_v: float,
        current_a: float,
        output_on: bool,
    ) -> None:
        ch = max(1, min(4, int(channel)))
        ch_vm = self._channels[ch]
        ch_vm.update_setpoints(voltage_v, current_a)
        ch_vm.update_output(output_on)
        self.telemetryChanged.emit()

    @Slot(int, float, float, float, float)
    def _on_limits_value_ready(
        self,
        channel: int,
        voltage_min: float,
        voltage_max: float,
        current_min: float,
        current_max: float,
    ) -> None:
        ch = max(1, min(4, int(channel)))
        self._channels[ch].update_limits(
            voltage_min=voltage_min,
            voltage_max=voltage_max,
            current_min=current_min,
            current_max=current_max,
        )

    @Slot(int, float, float)
    def applyChannelSetpoints(self, channel: int, voltage_v: float, current_a: float) -> None:  # noqa: N802
        if self._instrument is None:
            self._set_status("No connection")
            return

        channel = max(1, min(4, int(channel)))
        if channel > self._channel_count:
            self._set_status(f"CH{channel} is not installed in this mainframe")
            return
        ch_vm = self._channels[channel]
        requested_v = float(voltage_v)
        requested_i = float(current_a)
        safe_v = max(ch_vm.voltageMin, min(ch_vm.voltageMax, requested_v))
        safe_i = max(ch_vm.currentMin, min(ch_vm.currentMax, requested_i))
        if abs(ch_vm.setVoltage - safe_v) < 1e-6 and abs(ch_vm.setCurrent - safe_i) < 1e-6:
            return

        try:
            self._instrument.set_voltage(channel, safe_v)
            self._instrument.set_current(channel, safe_i)
            v_set = self._instrument.get_voltage_setpoint(channel)
            i_set = self._instrument.get_current_setpoint(channel)
            self._channels[channel].update_setpoints(v_set, i_set)
            if abs(requested_v - safe_v) > 1e-9 or abs(requested_i - safe_i) > 1e-9:
                self._append_log(
                    f"CH{channel} limits applied -> requested V={requested_v:.4f} I={requested_i:.6f}; "
                    f"used V={safe_v:.4f} I={safe_i:.6f}"
                )
            self._append_log(f"CH{channel} -> SET V={v_set:.4f}V I={i_set:.6f}A")
        except Exception as exc:  # noqa: BLE001
            self._set_status(f"Error applying CH{channel}: {exc}")

    @Slot(int, bool)
    def setChannelOutput(self, channel: int, enabled: bool) -> None:  # noqa: N802
        if self._instrument is None:
            self._set_status("No connection")
            return

        channel = max(1, min(4, int(channel)))
        if channel > self._channel_count:
            self._set_status(f"CH{channel} is not installed in this mainframe")
            return
        try:
            self._instrument.set_output(channel, bool(enabled))
            out_state = self._instrument.get_output_state(channel)
            self._channels[channel].update_output(out_state)
            self._append_log(f"CH{channel} output {'ON' if out_state else 'OFF'}")
        except Exception as exc:  # noqa: BLE001
            self._set_status(f"Error output CH{channel}: {exc}")

    @Slot(float)
    def setPollInterval(self, interval_s: float) -> None:  # noqa: N802
        self._poll_interval_s = max(0.1, float(interval_s))
        self.sessionChanged.emit()
        self._save_session_config()

    @Slot(float)
    def setPollFrequency(self, frequency_hz: float) -> None:  # noqa: N802
        try:
            hz = float(frequency_hz)
        except (TypeError, ValueError):
            return
        if hz <= 0:
            return
        self.setPollInterval(1.0 / hz)

    @Slot(int, bool)
    def setChannelPolling(self, channel: int, enabled: bool) -> None:  # noqa: N802
        channel = max(1, min(4, int(channel)))
        if channel > self._channel_count:
            return
        self._channels[channel].pollingSelected = bool(enabled)
        self._save_session_config()

    @Slot(str)
    def setLogPlotTitle(self, title: str) -> None:  # noqa: N802
        clean_title = str(title).strip()
        if not clean_title:
            clean_title = "Historical Log Plot"
        if clean_title == self._log_plot_title:
            return
        self._log_plot_title = clean_title
        self.logPlotChanged.emit()
        self._save_session_config()

    @Slot("QVariantList")
    def loadLogFiles(self, paths: list) -> None:  # noqa: N802
        if self._log_plot_loading:
            self._append_log("Log Plot loading in progress")
            return

        normalized_paths = [str(item).strip() for item in list(paths or []) if str(item).strip()]
        if not normalized_paths:
            self._set_status("No CSV files were selected")
            return

        self._log_plot_loading = True
        self.logPlotLoadingChanged.emit()
        self._append_log(f"Loading {len(normalized_paths)} file(s) for Log Plot...")

        threading.Thread(
            target=self._load_log_plot_worker,
            args=(normalized_paths,),
            daemon=True,
        ).start()

    @Slot()
    def clearLogPlot(self) -> None:  # noqa: N802
        if self._log_plot_loading:
            return
        self._log_plot_files = []
        self._log_plot_duration_s = 0.0
        self._log_plot_sample_count = 0
        self._log_plot_start_iso = ""
        self._log_plot_end_iso = ""
        self._log_plot_series = {
            "voltage_v": [],
            "current_a": [],
            "power_w": [],
            "charge_ah": [],
            "energy_wh": [],
        }
        self._log_plot_files_model.setStringList([])
        self.logPlotChanged.emit()
        self._append_log("Log Plot cleared")

    @Slot()
    def startMonitoring(self) -> None:  # noqa: N802
        if self._instrument is None:
            self._set_status("Connect the instrument first")
            return
        if self._monitoring:
            return

        self._acquisition_start = datetime.now()
        self._axis_min = 0.0
        self._axis_max = self._plot_window_s
        self.axisChanged.emit()

        for channel_vm in self._channels.values():
            channel_vm.reset_series()
            channel_vm.reset_totals()

        self._poll_stop.clear()
        self._poll_thread = threading.Thread(target=self._poll_loop, daemon=True)
        self._monitoring = True
        self.monitoringChanged.emit()
        self._append_log("Monitoring started")
        self._poll_thread.start()

    @Slot()
    def stopMonitoring(self) -> None:  # noqa: N802
        if not self._monitoring:
            return

        self._poll_stop.set()
        if self._poll_thread is not None:
            self._poll_thread.join(timeout=2.0)
        self._poll_thread = None
        self._monitoring = False
        self.monitoringChanged.emit()
        self._append_log("Monitoring stopped")

    def _poll_loop(self) -> None:
        consecutive_errors = 0
        while not self._poll_stop.is_set():
            instrument = self._instrument
            if instrument is None:
                return

            selected_channels = [
                ch for ch, vm in self._channels.items()
                if ch <= self._channel_count and vm.pollingSelected
            ]
            if not selected_channels:
                time.sleep(0.2)
                continue

            try:
                samples = instrument.measure_channels(selected_channels)
                self.samplesReady.emit(samples)
                consecutive_errors = 0
            except Exception as exc:  # noqa: BLE001
                consecutive_errors += 1
                if consecutive_errors >= 6:
                    self.pollingError.emit(
                        f"Monitoring stopped after {consecutive_errors} consecutive errors: {exc}"
                    )
                    return
                self.pollingError.emit(f"Sampling error ({consecutive_errors}/6): {exc}")
                time.sleep(min(1.0, self._poll_interval_s))
                continue

            remaining = self._poll_interval_s
            step = 0.1
            while remaining > 0 and not self._poll_stop.is_set():
                wait = min(step, remaining)
                time.sleep(wait)
                remaining -= wait

    @Slot(list)
    def _on_samples_ready(self, samples: list) -> None:
        any_sample = False
        for sample in samples:
            ch_vm = self._channels.get(sample.channel)
            if ch_vm is None:
                continue
            any_sample = True

            elapsed_s = max(0.0, (sample.timestamp - self._acquisition_start).total_seconds())
            ch_vm.update_measurement(sample, elapsed_s)

            if self._logging_active:
                self._logger.register(sample)

            self._update_axis(elapsed_s)

        if any_sample:
            self.telemetryChanged.emit()

    @Slot(str)
    def _on_polling_error(self, message: str) -> None:
        self._append_log(f"Monitoring error: {message}")
        if message.startswith("Monitoring stopped tras"):
            self._set_status(message)
            self.stopMonitoring()

    def _load_log_plot_worker(self, paths: list[str]) -> None:
        try:
            payload = self._log_plot_loader.load_csv_files(paths)
            self.logPlotLoadDone.emit(True, "", payload)
        except Exception as exc:  # noqa: BLE001
            self.logPlotLoadDone.emit(False, str(exc), {})

    @Slot(bool, str, object)
    def _on_log_plot_load_done(self, success: bool, message: str, payload: object) -> None:
        self._log_plot_loading = False
        self.logPlotLoadingChanged.emit()

        if not success:
            self._set_status(f"Failed to load Log Plot: {message}")
            return

        data = payload if isinstance(payload, dict) else {}
        files = [str(item) for item in data.get("files", [])]
        sample_count = int(data.get("sample_count", 0))
        duration_s = max(0.0, float(data.get("duration_s", 0.0)))
        start_iso = str(data.get("global_start_iso", "")).strip()
        end_iso = str(data.get("global_end_iso", "")).strip()
        series = data.get("series", {})

        self._log_plot_files = files
        self._log_plot_sample_count = sample_count
        self._log_plot_duration_s = duration_s
        self._log_plot_start_iso = start_iso
        self._log_plot_end_iso = end_iso
        self._log_plot_series = {
            "voltage_v": list(series.get("voltage_v", [])) if isinstance(series, dict) else [],
            "current_a": list(series.get("current_a", [])) if isinstance(series, dict) else [],
            "power_w": list(series.get("power_w", [])) if isinstance(series, dict) else [],
            "charge_ah": list(series.get("charge_ah", [])) if isinstance(series, dict) else [],
            "energy_wh": list(series.get("energy_wh", [])) if isinstance(series, dict) else [],
        }

        file_labels = [Path(item).name for item in files]
        self._log_plot_files_model.setStringList(file_labels)
        self.logPlotChanged.emit()
        self._append_log(
            f"Log Plot ready -> {len(files)} file(s), {sample_count} samples, "
            f"duration {duration_s:.2f}s"
        )

    @Slot()
    def startLogging(self) -> None:  # noqa: N802
        if self._logging_active:
            return
        try:
            self._logger.start(self._logging_path)
        except Exception as exc:  # noqa: BLE001
            self._set_status(f"Failed to start logging: {exc}")
            return

        for ch_vm in self._channels.values():
            ch_vm.reset_totals()

        self._logging_active = True
        self.loggingChanged.emit()
        self._append_log(f"Logging active -> {self._logger.path}")

        if not self._monitoring:
            self.startMonitoring()

    @Slot()
    def stopLogging(self) -> None:  # noqa: N802
        if not self._logging_active:
            return

        path = self._logger.path
        self._logger.stop()
        self._logging_active = False
        self.loggingChanged.emit()
        self._append_log(f"Logging stopped ({path})")

    @Slot()
    def saveSessionConfig(self) -> None:  # noqa: N802
        self._save_session_config()

    def _update_axis(self, elapsed_s: float) -> None:
        if elapsed_s <= self._axis_max - 1.0:
            return

        self._axis_max = elapsed_s + 1.0
        self._axis_min = max(0.0, self._axis_max - self._plot_window_s)
        self.axisChanged.emit()

    def _set_status(self, message: str) -> None:
        self._status = message
        self.statusChanged.emit()
        self._append_log(message)

    def _append_log(self, message: str) -> None:
        timestamp = datetime.now().strftime("%H:%M:%S")
        line = f"[{timestamp}] {message}"
        self._log_lines.append(line)
        if len(self._log_lines) > 300:
            self._log_lines = self._log_lines[-300:]
        self._log_lines_model.setStringList(self._log_lines)
        self.logLinesChanged.emit()

    def _normalize_logging_path(self, raw_value: str) -> str:
        value = str(raw_value).strip()
        if not value:
            return ""
        path = Path(value).expanduser()
        if not path.is_absolute():
            path = Path.cwd() / path
        if path.suffix.lower() != ".csv":
            path = path.with_suffix(".csv")
        return str(path.resolve())

    def _load_session_config(self) -> None:
        if not self._session_file.exists():
            return

        try:
            data = json.loads(self._session_file.read_text(encoding="utf-8"))
        except Exception as exc:  # noqa: BLE001
            self._append_log(f"Could not read configuration: {exc}")
            return

        host = str(data.get("host", self._connection_host)).strip()
        if host:
            self._connection_host = host

        try:
            port = int(data.get("port", self._connection_port))
            if 1 <= port <= 65535:
                self._connection_port = port
        except (TypeError, ValueError):
            pass

        try:
            timeout_s = float(data.get("timeout_s", self._connection_timeout_s))
            self._connection_timeout_s = max(0.2, timeout_s)
        except (TypeError, ValueError):
            pass

        try:
            self._poll_interval_s = max(0.1, float(data.get("poll_interval_s", self._poll_interval_s)))
        except (TypeError, ValueError):
            pass

        try:
            self._chart_channel = max(1, min(self._channel_count, int(data.get("chart_channel", self._chart_channel))))
        except (TypeError, ValueError):
            pass

        logging_path = self._normalize_logging_path(data.get("logging_path", self._logging_path))
        if logging_path:
            self._logging_path = logging_path

        title = str(data.get("log_plot_title", self._log_plot_title)).strip()
        if title:
            self._log_plot_title = title

        polling = data.get("channels_polling", {})
        if isinstance(polling, dict):
            for channel in range(1, 5):
                raw = polling.get(str(channel), self._channels[channel].pollingSelected)
                self._channels[channel].pollingSelected = bool(raw)

        if not any(self._channels[ch].pollingSelected for ch in range(1, self._channel_count + 1)):
            self._channels[1].pollingSelected = True

    def _save_session_config(self) -> None:
        data = {
            "host": self._connection_host,
            "port": self._connection_port,
            "timeout_s": self._connection_timeout_s,
            "poll_interval_s": self._poll_interval_s,
            "chart_channel": self._chart_channel,
            "logging_path": self._logging_path,
            "log_plot_title": self._log_plot_title,
            "channels_polling": {
                str(ch): self._channels[ch].pollingSelected for ch in range(1, 5)
            },
        }

        try:
            self._session_file.parent.mkdir(parents=True, exist_ok=True)
            self._session_file.write_text(
                json.dumps(data, indent=2, ensure_ascii=True),
                encoding="utf-8",
            )
        except Exception as exc:  # noqa: BLE001
            self._append_log(f"Could not save configuration: {exc}")







