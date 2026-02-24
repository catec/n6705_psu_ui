# Architecture Reference - N6705 Power Console

This document describes the internal architecture, runtime flow, and extension points of the N6705 Power Console.

<p align="center">
  <img src="assets/icons/n6705_app_icon.svg" alt="N6705 Power Console app icon" width="220" />
</p>

## 1. Architectural Style

The project follows a **MVVM + Ports/Adapters** architecture:

- **View (QML)**: visual composition, interactions, bindings
- **ViewModel (Python QObject)**: state, orchestration, async control
- **Domain models**: typed telemetry and totals
- **Adapters**: SCPI transport and N6705 command abstraction
- **Services**: CSV persistence and historical analytics

This separation keeps transport/protocol logic isolated from UI composition and enables predictable testing.

## 2. Layered Structure

### 2.1 Communication Layer

File: `n6705_ui/communication/scpi_client.py`

Responsibilities:
- TCP socket lifecycle (`connect`, `disconnect`)
- Serialized IO with lock-protected command/query flow
- SCPI framing (`\n` termination)
- Line-oriented response parsing

### 2.2 Device Adapter Layer

File: `n6705_ui/device/n6705.py`

Responsibilities:
- Device-level API over SCPI
- Channel setpoint/output operations
- Batch acquisition for `MEAS:VOLT?` and `MEAS:CURR?`
- Graceful fallback to per-channel readout on incompatibility
- Derived power computation (`P = V * I`) when direct power query is unavailable

### 2.3 Application Services

Files:
- `n6705_ui/logging/consumption_logger.py`
- `n6705_ui/logging/log_plot_loader.py`

Responsibilities:
- CSV writing with deterministic schema
- Ah/Wh integration over elapsed time per channel
- Multi-file historical load and validation
- Point decimation for rendering performance
- Series payload generation for QML charts

### 2.4 Presentation Layer

Files:
- `n6705_ui/presentation/viewmodels/dashboard_vm.py`
- `n6705_ui/presentation/viewmodels/channel_vm.py`
- `n6705_ui/presentation/qml/**`

Responsibilities:
- Connection orchestration
- Polling lifecycle and stop policy
- Logging lifecycle
- Session persistence and restoration
- Reactive properties/signals for QML

## 3. Runtime Flow

1. User interacts with QML.
2. QML calls a `DashboardViewModel` slot.
3. ViewModel delegates to `N6705PowerAnalyzer`.
4. Adapter executes SCPI through `ScpiTcpClient`.
5. Polling thread emits samples to the UI thread.
6. Channel viewmodels update traces and numeric readouts.
7. Optional logging persists samples and totals to CSV.

## 4. Concurrency Model

- Connection workflow runs in a dedicated worker thread.
- Polling loop runs in its own daemon thread.
- Snapshot and limit reads are asynchronously dispatched.
- UI mutation is performed through Qt signals/slots to avoid direct cross-thread UI updates.

## 5. Data Contracts

`ChannelMeasurement`:
- `timestamp`
- `channel`
- `voltage_v`
- `current_a`
- `power_w`

`ChannelTotals`:
- `charge_ah`
- `energy_wh`

CSV schema:
- `timestamp_iso, channel, voltage_v, current_a, power_w, charge_ah, energy_wh`

## 6. Reliability and Failure Strategy

- TCP disconnect/shutdown is guarded against socket errors.
- Polling aborts after repeated consecutive failures.
- SCPI batch acquisition fallback avoids repeated timeout penalties.
- Input values are normalized and clamped where relevant.
- Session file loading is tolerant to malformed data.

## 7. Testing Strategy

- Integration-style SCPI transport tests with threaded mock TCP server.
- Log plot service tests for schema validation, series generation, and decimation.

Command:

```bash
python -m unittest discover -s tests -v
```

## 8. Extension Points

- Add support for another instrument by implementing a new adapter.
- Swap persistence backend while keeping ViewModel contract intact.
- Extend visualization by adding new QML view/component modules.

## 9. Release and Packaging Architecture (Windows)

Distribution follows a two-stage pipeline:

1. **Application bundling** with `PyInstaller`
2. **Installer generation** with `Inno Setup`

Build assets:

- Script: `packaging/windows/build_installer.ps1`
- Installer definition: `packaging/windows/installer.iss`
- Icon converter: `packaging/windows/make_icon.py`

Execution model:

- Python runtime and dependencies are embedded in the app bundle
- End users do not need Python/pip installed
- Installer deploys per-user to `%LOCALAPPDATA%\Programs\N6705 Power Console`
- Installer creates shortcuts, uninstaller entry, and `N6705_UI_HOME`

Runtime portability:

- `n6705_ui/qml_main.py` resolves resource paths for both source mode and frozen mode
- QML/assets are included in the bundle and loaded from runtime root

## Signature

Author: Mouhsine Kassimi Farhaoui  
Mail: mouhsine98@gmail.com

