# User Guide - N6705 Power Console

Detailed operational guide for setup, connection, monitoring, logging, and troubleshooting of the N6705 Power Console.

<p align="center">
  <img src="assets/icons/n6705_app_icon.svg" alt="N6705 Power Console app icon" width="220" />
</p>

## 1. Purpose

N6705 Power Console provides production-grade remote operation of a Keysight N6705 over SCPI/TCP with live visualization, logging, and historical analysis.

## 2. Requirements

- Python 3.10+
- Network access to the instrument host
- GUI-capable environment (Windows/Linux desktop)
- Dependencies installed with `pip install -r requirements.txt`

## 3. Installation

### 3.1 Create and Activate Virtual Environment

```bash
python -m venv .venv
```

Linux/macOS:

```bash
source .venv/bin/activate
```

Windows PowerShell:

```powershell
.\.venv\Scripts\Activate.ps1
```

### 3.2 Install Dependencies

```bash
pip install -r requirements.txt
```

### 3.3 Windows End-User Installer (Recommended for Distribution)

If you distribute the application to end users, use the packaged installer.

Build it from the repository root:

```powershell
.\packaging\windows\build_installer.cmd -AppVersion 1.0.0
```

Alternative direct PowerShell call (without changing system policy):

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\packaging\windows\build_installer.ps1 -AppVersion 1.0.0
```

Outputs:

- App bundle: `dist/windows/app/N6705PowerConsole/`
- Installer EXE: `dist/windows/installer/n6705-power-console-1.0.0-setup.exe`

Installer behavior:

- Installs under `%LOCALAPPDATA%\Programs\N6705 Power Console`
- Creates Start Menu entry and optional Desktop shortcut
- Registers uninstaller
- Sets `N6705_UI_HOME` user environment variable

Prerequisites for building installer:

- Inno Setup 6 (`iscc.exe` in `PATH`)
- Python 3.10+ on build machine

## 4. Launching the App

```bash
python app.py
```

## 5. First-Time Configuration

1. Open **Connection Properties**.
2. Enter:
- Host/IP (example: `192.168.6.59`)
- Port (`5025` by default)
- Timeout in seconds (`3.0` recommended to start)
3. Click **Connect**.
4. Verify connection status and IDN string.

## 6. Working with Channels

### 6.1 Select Channel

Use channel selectors (CH1..CH4) in the left/center control area.

### 6.2 Set Voltage and Current

- Enter values in setpoint fields or use the dial controls.
- Click **Apply**.
- The app reads back instrument values to confirm actual applied setpoints.

### 6.3 Output Control

- Toggle per-channel output ON/OFF.
- Use global output control actions as needed.

## 7. Live Monitoring

### 7.1 Meter View

Displays live voltage/current/power and channel status.

### 7.2 Scope View

Displays streaming traces:
- Voltage
- Current
- Power

And cumulative trends:
- Charge (Ah)
- Energy (Wh)

### 7.3 Data Logger View

Provides:
- Channel cards with current values
- Event log stream
- Logging controls

## 8. CSV Logging Workflow

1. Define CSV path manually or via **Browse**.
2. Click **Start Log**.
3. Execute your measurement sequence.
4. Click **Stop Log**.

CSV columns:
- `timestamp_iso`
- `channel`
- `voltage_v`
- `current_a`
- `power_w`
- `charge_ah`
- `energy_wh`

## 9. Historical Analysis (Log Plot)

1. Open **Log Plot** view.
2. Click **Load CSV(s)** and choose one or multiple files.
3. Filter by file/channel when needed.
4. Compare traces across metrics:
- Voltage
- Current
- Power
- Charge
- Energy
5. Export chart panel to PNG.

## 10. Polling Tuning

You can control telemetry rate with either:
- `Interval (s)`
- `Frequency (Hz)`

The relation is:
- `frequency = 1 / interval`

Recommended practice:
- Start with moderate frequencies.
- Increase only if network and instrument remain stable.

## 11. Session Persistence

Persisted automatically:
- Host, port, timeout
- Polling interval/frequency
- Selected chart channel
- CSV logging path
- Log plot title
- Channel polling flags

Path:
- `~/.config/n6705_ui/session.json`

## 12. Troubleshooting

### 12.1 Connection Fails

- Validate instrument IP and physical network route.
- Check firewall rules and TCP port 5025.
- Increase timeout if the network is slow.

### 12.2 Telemetry Is Not Updating

- Confirm monitor loop is running.
- Confirm at least one channel is marked for polling.
- Check event log for SCPI communication errors.

### 12.3 Logging Cannot Start

- Verify write permissions for target folder.
- Ensure path is valid and ends with `.csv`.

### 12.4 Historical Plot Appears Empty

- Confirm CSV file contains required columns.
- Verify timestamps are valid ISO values.
- Ensure selected filters are not excluding all series.

### 12.5 Windows Plugin Loading Problems

- Ensure PySide6 runtime is installed in active environment.
- Run from the same interpreter used for dependency install.
- Confirm that required Qt DLL directories are resolvable.

## 13. Advanced Operational Tips

- Apply setpoints with output OFF during sensitive setup operations.
- Validate module min/max limits before applying aggressive values.
- Keep event log visible during long runs to detect intermittent failures.
- Use descriptive file names for multi-run historical comparisons.

## Signature

Author: Mouhsine Kassimi Farhaoui  
Mail: mouhsine98@gmail.com

